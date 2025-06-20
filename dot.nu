#!/usr/bin/env nu

source scripts/common.nu
source scripts/kubernetes.nu
source scripts/ingress.nu
source scripts/argocd.nu

def main [] {}

def "main setup" [] {

    let provider = main get provider

    main create kubernetes $provider

    mut ingress_class = "contour"
    if $provider == "kind" {
        $ingress_class = "nginx"
    }
    let ingress_data = (
        main apply ingress $ingress_class --provider $provider
    )

    sleep 10sec

    (
        main apply argocd
            --host-name $"argocd.($ingress_data.host)"
            --ingress-class-name $ingress_data.class
    )

    ##########
    # kagent #
    ##########

    (
        helm upgrade --install kagent-crds
            oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds
            --version 0.3.15
            --namespace kagent --create-namespace --wait
    )
    
    (
        helm upgrade --install kagent 
            oci://ghcr.io/kagent-dev/kagent/helm/kagent
            --version 0.3.15
            --namespace kagent --create-namespace
            --set providers.anthropic.apiKeySecretRef=anthropic
            --set providers.anthropic.apiKeySecretKey=ANTHROPIC_API_KEY
            --wait
    )

    mut anthropic_api_key = ""
    if ANTHROPIC_API_KEY in $env {
        $anthropic_api_key = $env.ANTHROPIC_API_KEY
    } else {
        $anthropic_api_key = input $"(ansi green_bold)Anthropic API Key: (ansi reset)"
    }
    $"export ANTHROPIC_API_KEY=($anthropic_api_key)\n"
        | save --append .env

    (
        kubectl create secret generic anthropic
            --from-literal $"ANTHROPIC_API_KEY=($anthropic_api_key)"
            --namespace kagent
    )
    
    {
        apiVersion: "networking.k8s.io/v1"
        kind: "Ingress"
        metadata: { name: "kagent" }
        spec: {
            ingressClassName: $ingress_data.class
            rules: [{
                host: $"kagent.($ingress_data.host)"
                http: { paths: [{
                    backend: { service: {
                        name: kagent
                        port: { number: 80 }
                    } }
                    path: "/"
                    pathType: "Prefix"
                }] }
            }]
        }
    } | to yaml | kubectl --namespace kagent apply --filename -
    
    kubectl --namespace kagent apply --filename manifests/model-config.yaml

    kubectl --namespace kagent apply --filename manifests/kubernetes-agent.yaml

    kubectl --namespace kagent apply --filename manifests/helm-agent.yaml

    kubectl --namespace kagent apply --filename manifests/context7-toolserver.yaml

    kubectl --namespace kagent apply --filename manifests/generic-agent.yaml
    
    main print source

}

def "main destroy" [
    provider: string
] {

    main destroy kubernetes $provider

}
#!/usr/bin/env nu

source scripts/common.nu
source scripts/kubernetes.nu
source scripts/ingress.nu
source scripts/argocd.nu
source scripts/crossplane.nu
source scripts/github.nu

def main [] {}

def "main setup" [] {

    rm --force .env

    let provider = (
        main get provider --providers ['aws', 'azure', 'google', 'upcloud']
    )

    let github_data = main get github

    main create kubernetes $provider --node-size medium

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

    main apply crossplane --provider $provider --app true --db true

    ##########
    # kagent #
    ##########

    (
        helm upgrade --install kagent-crds
            oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds
            --namespace kagent --create-namespace --wait
    )
    
    (
        helm upgrade --install kagent 
            oci://ghcr.io/kagent-dev/kagent/helm/kagent
            --namespace kagent --create-namespace
            --set providers.default=anthropic
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
                http: { paths: [
                    {
                        backend: { service: {
                            name: kagent
                            port: { number: 8081 }
                        } }
                        path: "/api"
                        pathType: "Prefix"
                    }, {
                        backend: { service: {
                            name: kagent
                            port: { number: 80 }
                        } }
                        path: "/"
                        pathType: "Prefix"
                    }
                ] }
            }]
        }
    } | to yaml | kubectl --namespace kagent apply --filename -

    kubectl --namespace kagent apply --filename manifests/model-config.yaml

    # {
    #     apiVersion: "kagent.dev/v1alpha1"
    #     kind: "ToolServer"
    #     metadata: { name: "github" }
    #     spec: {
    #         config: { streamableHttp: {
    #             headers: { Authorization: $"Bearer ($github_data.token)" }
    #             sseReadTimeout: "5m0s"
    #             timeout: "5s"
    #             url: "https://api.githubcopilot.com/mcp/"
    #         } }
    #         description: "GitHub MCP"
    #     }
    # } | to yaml | kubectl --namespace kagent apply --filename -

    # kubectl --namespace kagent apply --filename manifests/git-operations-agent.yaml

    # kubectl --namespace kagent apply --filename manifests/kubernetes-agent.yaml

    # kubectl --namespace kagent apply --filename manifests/helm-agent.yaml

    # kubectl --namespace kagent apply --filename manifests/context7-toolserver.yaml

    # kubectl --namespace kagent apply --filename manifests/service-create-agent.yaml

    # kubectl --namespace kagent apply --filename manifests/service-observe-agent.yaml

    # kubectl --namespace kagent apply --filename manifests/service-delete-agent.yaml

    # kubectl --namespace kagent apply --filename manifests/kagent-crossplane-rbac.yaml

    # kubectl --namespace kagent apply --filename manifests/memory-app-toolserver.yaml

    # kubectl --namespace kagent apply --filename manifests/manage-app.yaml

    # kubectl --namespace kagent apply --filename manifests/generic-agent.yaml

    kubectl create namespace a-team

    kubectl create namespace b-team
    
    main print source

    print $"
Open `(ansi yellow_bold)http://kagent.($ingress_data.host)(ansi reset)` in a browser to explore kagent Web UI.
    "

}

def "main destroy" [
    provider: string
] {

    main destroy kubernetes $provider

}
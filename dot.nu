#!/usr/bin/env nu

source scripts/common.nu
source scripts/kubernetes.nu
source scripts/ingress.nu
source scripts/argocd.nu

def main [] {

    let provider = main get provider

    main create kubernetes $provider

    let ingress_class = "contour"
    if $provider == "kind" {
        let ingress_class = "nginx"
    }
    let ingress_data = (
        main apply ingress $ingress_class --provider $provider
    )

    (
        main apply argocd
            --host-name $ingress_data.host
            --ingress-class-name $ingress_class
    )

    # # Create namespace and install kagent
    # echo "Creating kagent namespace..."
    # kubectl create namespace kagent --dry-run=client --output yaml | kubectl apply --filename -
            
    # # Create API key secret
    # echo "Creating Anthropic API key secret..."
    # kubectl create secret generic anthropic-claude-3-7-sonnet-20250219 \
    #   --from-literal=ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
    #   --namespace kagent
    
    # # Install kagent using Helm directly
    # echo "Adding kagent Helm repository..."
    # helm repo add kagent https://vfarcic.github.io/kagent
    # helm repo update
    
    # echo "Installing kagent CRDs..."
    # helm install kagent-crds kagent/kagent-crds --namespace kagent --create-namespace
    
    # echo "Installing kagent operator..."
    # helm install kagent-operator kagent/kagent --namespace kagent \
    #   --set providers.anthropic.apiKeySecretRef=anthropic-claude-3-7-sonnet-20250219 \
    #   --set providers.anthropic.apiKeySecretKey=ANTHROPIC_API_KEY
    
    # echo "Waiting for kagent operator to be ready..."
    # kubectl wait --for=condition=available --timeout=300s deployment/kagent-operator --namespace kagent
    
    # # Apply kagent manifests directly
    # echo "Applying kagent manifests..."
    # kubectl apply --filename manifests/model-config.yaml
    # kubectl apply --filename manifests/generic-agent.yaml
    # kubectl apply --filename manifests/kubernetes-agent.yaml
    # kubectl apply --filename manifests/helm-agent.yaml
    # kubectl apply --filename manifests/context7-toolserver.yaml
    # kubectl apply --filename manifests/kagent-ingress.yaml
    
    main print source

}

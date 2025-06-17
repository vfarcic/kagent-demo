#!/bin/bash

set -e

echo "Setting up kagent demo with GitOps approach..."

# Get Anthropic API key (from env var or prompt)
if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "Please enter your Anthropic API key:"
  read -s ANTHROPIC_API_KEY
  
  if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Error: API key is required"
    exit 1
  fi
else
  echo "Using ANTHROPIC_API_KEY from environment"
fi

# Create kind cluster with local kubeconfig
echo "Creating kind cluster with local kubeconfig..."
kind create cluster --name kagent-demo --kubeconfig kubeconfig.yaml --config kind-config.yaml

echo "Setting KUBECONFIG environment variable..."
export KUBECONFIG=$(pwd)/kubeconfig.yaml

# Create namespace and install kagent
echo "Creating kagent namespace..."
kubectl create namespace kagent --dry-run=client --output yaml | kubectl apply --filename -



# Install NGINX Ingress Controller
echo "Installing NGINX Ingress Controller..."
kubectl apply --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s

# Install Argo CD
echo "Installing Argo CD..."
kubectl create namespace argocd --dry-run=client --output yaml | kubectl apply --filename -
kubectl apply --namespace argocd --filename https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for Argo CD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server --namespace argocd

# Create API key secret
echo "Creating Anthropic API key secret..."
kubectl create secret generic anthropic-claude-3-7-sonnet-20250219 \
  --from-literal=ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  --namespace kagent

# Apply the Argo CD Application
echo "Creating Argo CD Application..."
export REPO_URL=$(git remote get-url origin)
if [ -z "$REPO_URL" ]; then
  echo "Warning: No git remote found. Please update repoURL in apps-app.yaml manually."
else
  echo "Using git remote URL: $REPO_URL"
  yq eval '.spec.source.repoURL = env(REPO_URL)' -i apps-app.yaml
  yq eval '.spec.source.repoURL = env(REPO_URL)' -i bootstrap/00-kagent-crds.yaml
  yq eval '.spec.source.repoURL = env(REPO_URL)' -i bootstrap/01-kagent-operator.yaml
  yq eval '.spec.source.repoURL = env(REPO_URL)' -i bootstrap/02-manifests.yaml
fi
kubectl apply --filename apps-app.yaml

echo "Setup complete!"
echo ""
echo "Access Argo CD UI:"
echo "http://argocd.127.0.0.1.nip.io"
echo "Initial admin password: kubectl get secret argocd-initial-admin-secret --namespace argocd --output jsonpath='{.data.password}' | base64 --decode"
echo ""
echo "Access kagent UI:"
echo "http://kagent.127.0.0.1.nip.io"
echo ""
echo "Verify the setup:"
echo "kubectl get applications --namespace argocd"
echo "kubectl get agents --namespace kagent"
echo "kubectl get modelconfigs --namespace kagent"
echo ""
echo "Test the generic agent:"
echo "echo 'List pods in default namespace' > /tmp/task.txt"
echo "kagent invoke --agent generic --task /tmp/task.txt"
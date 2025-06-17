#!/bin/bash

set -e

echo "Setting up kagent with custom agents..."

# Create namespace and install kagent
echo "Creating kagent namespace..."
kubectl create namespace kagent --dry-run=client --output yaml | kubectl apply --filename -

echo "Adding kagent helm repo..."
helm repo add kagent https://kagent.dev/charts
helm repo update

echo "Installing kagent CRDs..."
helm install kagent-crds kagent/kagent-crds --version 0.3.15 --namespace kagent

echo "Installing kagent..."
helm install kagent kagent/kagent --version 0.3.15 --namespace kagent

# Create API key secret (replace with your actual key)
echo "Creating API key secret..."
echo "Please replace 'your-anthropic-api-key' with your actual API key"
kubectl create secret generic anthropic-claude-3-7-sonnet-20250219 \
  --from-literal=ANTHROPIC_API_KEY=your-anthropic-api-key \
  --namespace kagent \
  --dry-run=client --output yaml | kubectl apply --filename -

# Apply manifests
echo "Applying model config, tool servers, and agents..."
kubectl apply --filename manifests/model-config.yaml
kubectl apply --filename manifests/context7-toolserver.yaml
kubectl apply --filename manifests/kubernetes-agent.yaml
kubectl apply --filename manifests/helm-agent.yaml
kubectl apply --filename manifests/generic-agent.yaml

echo "Setup complete!"
echo ""
echo "IMPORTANT: Remember to replace 'your-anthropic-api-key' with your actual Anthropic API key:"
echo "kubectl patch secret anthropic-claude-3-7-sonnet-20250219 --namespace kagent --type='json' --patch='[{\"op\": \"replace\", \"path\": \"/data/ANTHROPIC_API_KEY\", \"value\":\"$(echo -n 'YOUR_ACTUAL_API_KEY' | base64)\"}]'"
echo ""
echo "Verify the setup:"
echo "kubectl get agents --namespace kagent"
echo "kubectl get modelconfigs --namespace kagent"
echo ""
echo "Test the generic agent:"
echo "echo 'List pods in default namespace' > /tmp/task.txt"
echo "kagent invoke --agent generic --task /tmp/task.txt"
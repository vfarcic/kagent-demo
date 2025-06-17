# Claude Code Session Context

This file provides context for Claude Code about the current state of this kagent project.

## Project Overview

This is a **kagent demo project** that sets up kagent (AI agents for Kubernetes) with Context7 MCP integration for up-to-date documentation retrieval.

## What We've Accomplished

### 1. **GitOps Setup with Kind and Argo CD** ✅ COMPLETE
- Created `setup.sh` script for automated cluster and GitOps setup
- Creates Kind cluster with local kubeconfig (`kubeconfig.yaml`)
- Installs NGINX Ingress Controller for local access
- Installs Argo CD with HTTP ingress via `nip.io`
- Prompts user for Anthropic API key and creates secret automatically
- Uses full argument names (e.g., `--namespace` instead of `-n`) per user preference

### 2. **GitOps Application Structure** ✅ COMPLETE
- **Directory**: `apps/` - Contains all Kubernetes manifests managed by Argo CD
- **File**: `apps/kagent-app.yaml` - Argo CD Application pointing to this repo
- **Ingress**: Both Argo CD and kagent accessible via HTTP ingress
- **Access URLs**:
  - Argo CD: `http://argocd.127.0.0.1.nip.io`
  - Kagent: `http://kagent.127.0.0.1.nip.io`

### 3. **Context7 MCP Integration** ✅ WORKING
- **File**: `apps/context7-toolserver.yaml` (moved from manifests/)
- **Status**: Successfully deployed and tested
- **Tools Available**: 
  - `resolve-library-id` - Resolves library names to Context7 IDs
  - `get-library-docs` - Fetches up-to-date documentation
- **Command**: `npx --yes @upstash/context7-mcp`

### 4. **Custom Agents Created**

#### Generic Agent (Orchestrator)
- **File**: `apps/generic-agent.yaml` (moved from manifests/)
- **Role**: Main orchestrator that delegates to specialized agents
- **Key Feature**: **MUST use Context7 first** for any technology/library questions
- **Tools**: Context7 MCP + kubernetes agent + helm agent
- **System Message**: Prioritizes Context7 for up-to-date documentation over training data

#### Kubernetes Agent
- **File**: `apps/kubernetes-agent.yaml` (moved from manifests/)
- **Role**: Kubernetes cluster operations
- **Tools**: All kagent K8s builtin tools (GetResources, ApplyManifest, etc.)

#### Helm Agent
- **File**: `apps/helm-agent.yaml` (moved from manifests/)
- **Role**: Helm chart operations
- **Tools**: Helm builtin tools (ListReleases, Upgrade, etc.)

### 5. **Model Configuration**
- **File**: `apps/model-config.yaml` (moved from manifests/)
- **Model**: `anthropic-claude-3-7-sonnet-20250219`
- **Provider**: Anthropic
- **Secret**: `anthropic-claude-3-7-sonnet-20250219`

### 6. **Ingress Configuration** ✅ COMPLETE
- **File**: `apps/argocd-ingress.yaml` - Argo CD HTTP ingress
- **File**: `apps/argocd-server-patch.yaml` - Configures Argo CD for insecure HTTP
- **File**: `apps/kagent-ingress.yaml` - Kagent HTTP ingress
- **NGINX Ingress**: Installed with Kind-specific configuration
- **Access**: Both services accessible via `nip.io` domains

### 7. **Development Environment**
- **Devbox**: `devbox.json` and `devbox.lock` for consistent dev environment
- **Git**: `.gitignore` created to exclude sensitive `kubeconfig.yaml`

## Current State

### ✅ Working Features
- **GitOps Setup**: Fully automated cluster creation with Kind, Argo CD, and NGINX Ingress
- **Context7 MCP Server**: Deployed and discovering tools correctly
- **Generic Agent**: Successfully uses Context7 tools for library documentation (tested with React useState)
- **Agent Communication**: Generic agent properly delegates to kubernetes/helm agents
- **Web Access**: Both Argo CD and kagent accessible via HTTP ingress
- **Setup Script**: Complete GitOps workflow with user-friendly API key input

### 🔧 Technical Details
- **Kagent CLI Issue**: `--stream` flag causes JSON parsing crashes, use without streaming
- **Tool Configuration**: Required explicit `toolNames` in mcpServer configuration
- **System Message**: Uses strong mandatory language ("MUST use Context7 FIRST") to ensure tool usage

### 📋 Test Commands
```bash
# Test Context7 integration (without --stream to avoid crashes)
echo "How do I use React useState hook?" > /tmp/task.txt
kagent invoke --agent generic --task /tmp/task.txt

# Test Kubernetes delegation
echo "List pods in default namespace" > /tmp/task.txt
kagent invoke --agent generic --task /tmp/task.txt
```

## Next Steps (if needed)

1. **Git Repository**: Complete git initialization and GitHub repository creation
2. **Add Argo CD**: User mentioned wanting to add Argo CD to the setup
3. **Platform Setup Workflows**: User interested in predefined prompts like "setup platform"
4. **Documentation**: Create comprehensive README.md

## File Structure
```
kagent-demo/
├── setup.sh                           # GitOps installation script
├── apps/                               # Argo CD managed manifests
│   ├── kagent-app.yaml                 # Argo CD Application
│   ├── context7-toolserver.yaml       # Context7 MCP server
│   ├── generic-agent.yaml             # Orchestrator agent
│   ├── kubernetes-agent.yaml          # K8s operations agent
│   ├── helm-agent.yaml                # Helm operations agent
│   ├── model-config.yaml              # Anthropic model config
│   ├── argocd-ingress.yaml             # Argo CD HTTP ingress
│   ├── argocd-server-patch.yaml       # Argo CD insecure config
│   └── kagent-ingress.yaml             # Kagent HTTP ingress
├── .gitignore                          # Excludes kubeconfig.yaml
├── devbox.json                        # Dev environment
├── devbox.lock                        # Dev environment lock
├── kubeconfig.yaml                     # K8s config (git ignored)
└── CLAUDE.md                          # This context file
```

## Key Learnings

1. **GitOps Approach**: Moving from imperative setup to declarative GitOps significantly improves maintainability
2. **Context7 Integration**: Works perfectly when properly configured with explicit tool names
3. **Agent Prompting**: Strong mandatory language required to ensure tool usage over training data
4. **Kagent CLI**: Streaming mode has bugs, use non-streaming for reliability
5. **System Architecture**: Generic orchestrator + specialized agents pattern works well
6. **Ingress with nip.io**: HTTP-only ingress with nip.io domains provides easy local access without TLS complexity

## User Preferences

- Prefers full argument names in scripts (`--namespace` not `-n`)
- Wants Context7 for up-to-date documentation
- Interested in platform setup automation
- Prefers YAML manifests over inline configurations
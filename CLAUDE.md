# Claude Code Session Context

This file provides context for Claude Code about the current state of this kagent project.

## Project Overview

This is a **kagent demo project** that sets up kagent (AI agents for Kubernetes) with Context7 MCP integration for up-to-date documentation retrieval.

## What We've Accomplished

### 1. **Kagent Installation Setup**
- Created `setup.sh` script for automated kagent installation
- Uses full argument names (e.g., `--namespace` instead of `-n`) per user preference
- Installs kagent CRDs and main chart via Helm
- Sets up Anthropic API key secret

### 2. **Context7 MCP Integration** ✅ WORKING
- **File**: `manifests/context7-toolserver.yaml`
- **Status**: Successfully deployed and tested
- **Tools Available**: 
  - `resolve-library-id` - Resolves library names to Context7 IDs
  - `get-library-docs` - Fetches up-to-date documentation
- **Command**: `npx --yes @upstash/context7-mcp`

### 3. **Custom Agents Created**

#### Generic Agent (Orchestrator)
- **File**: `manifests/generic-agent.yaml`
- **Role**: Main orchestrator that delegates to specialized agents
- **Key Feature**: **MUST use Context7 first** for any technology/library questions
- **Tools**: Context7 MCP + kubernetes agent + helm agent
- **System Message**: Prioritizes Context7 for up-to-date documentation over training data

#### Kubernetes Agent
- **File**: `manifests/kubernetes-agent.yaml`
- **Role**: Kubernetes cluster operations
- **Tools**: All kagent K8s builtin tools (GetResources, ApplyManifest, etc.)

#### Helm Agent
- **File**: `manifests/helm-agent.yaml`
- **Role**: Helm chart operations
- **Tools**: Helm builtin tools (ListReleases, Upgrade, etc.)

### 4. **Model Configuration**
- **File**: `manifests/model-config.yaml`
- **Model**: `anthropic-claude-3-7-sonnet-20250219`
- **Provider**: Anthropic
- **Secret**: `anthropic-claude-3-7-sonnet-20250219`

### 5. **Development Environment**
- **Devbox**: `devbox.json` and `devbox.lock` for consistent dev environment
- **Git**: `.gitignore` created to exclude sensitive `kubeconfig.yaml`

## Current State

### ✅ Working Features
- **Context7 MCP Server**: Deployed and discovering tools correctly
- **Generic Agent**: Successfully uses Context7 tools for library documentation (tested with React useState)
- **Agent Communication**: Generic agent properly delegates to kubernetes/helm agents
- **Setup Script**: Ready for production deployment

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
├── setup.sh                           # Main installation script
├── manifests/
│   ├── context7-toolserver.yaml       # Context7 MCP server
│   ├── generic-agent.yaml             # Orchestrator agent
│   ├── kubernetes-agent.yaml          # K8s operations agent
│   ├── helm-agent.yaml                # Helm operations agent
│   └── model-config.yaml              # Anthropic model config
├── .gitignore                          # Excludes kubeconfig.yaml
├── devbox.json                        # Dev environment
├── devbox.lock                        # Dev environment lock
├── kubeconfig.yaml                     # K8s config (git ignored)
└── CLAUDE.md                          # This context file
```

## Key Learnings

1. **Context7 Integration**: Works perfectly when properly configured with explicit tool names
2. **Agent Prompting**: Strong mandatory language required to ensure tool usage over training data
3. **Kagent CLI**: Streaming mode has bugs, use non-streaming for reliability
4. **System Architecture**: Generic orchestrator + specialized agents pattern works well

## User Preferences

- Prefers full argument names in scripts (`--namespace` not `-n`)
- Wants Context7 for up-to-date documentation
- Interested in platform setup automation
- Prefers YAML manifests over inline configurations
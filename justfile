# Homelab — Common Workflows
# Usage: just <command>

# Generate Talos cluster configs
genconfig:
    just --justfile 02-kubernetes/justfile genconfig

# Encrypt Talos configs for git
encrypt:
    just --justfile 02-kubernetes/justfile encrypt

# Deploy to a specific hypervisor (usage: just deploy hyp01)
deploy host:
    just --justfile 01-virtualization/justfile {{host}}

# Deploy all hypervisors
deploy-all:
    just --justfile 01-virtualization/justfile hyp01
    just --justfile 01-virtualization/justfile hyp02
    just --justfile 01-virtualization/justfile hyp03
    just --justfile 01-virtualization/justfile hyp04

# Edit encrypted secrets
edit-secrets path:
    sops {{path}}

# Lint all YAML files
lint:
    yamllint .

# Check cluster nodes
cluster-nodes:
    kubectl get nodes -o wide

# Show flux reconciliations
flux-status:
    flux get all --all-namespaces

# Show argocd applications
argocd-status:
    argocd app list

# Open dev shell
dev:
    devbox shell

# List all available targets
default:
    just --list
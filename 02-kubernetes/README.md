# Kubernetes Cluster — Talos Linux

Talos Linux cluster (v1.12.4) running Kubernetes v1.34.0 across 3 control plane nodes and 1 worker node, managed with [talhelper](https://budimanjojo.github.io/talhelper/).

## Quick Start

```bash
# Generate cluster configs
just genconfig

# Encrypt for git
just encrypt

# Bootstrap the cluster
talosctl bootstrap --nodes 10.30.0.29

# Get kubeconfig
talosctl kubeconfig
```

## Nodes

| Hostname | IP (VLAN 30) | IP (VLAN 40) | Role | Hypervisor |
|----------|-------------|-------------|------|------------|
| cp-node01 | 10.30.0.29 | 10.40.0.29 | Control Plane | hyp01 |
| cp-node02 | 10.30.0.31 | 10.40.0.31 | Control Plane | hyp02 |
| cp-node03 | 10.30.0.32 | 10.40.0.32 | Control Plane | hyp03 |
| w-node04 | 10.30.0.33 | 10.40.0.33 | Worker | hyp04 |

## Key Files

- `talconfig.yaml` — Cluster definition
- `patches/` — Machine/node-specific patches
- `clusterconfig-enc/` — Encrypted cluster configs for git
- `talsecret.sops.yaml` — Encrypted secrets (SOPS+age)

## Directory Structure

```
02-kubernetes/
├── talconfig.yaml
├── talenv.yaml
├── talsecret.sops.yaml
├── patches/machine/        # Machine-level patches
├── patches/nodes/          # Node-level patches
├── clusterconfig-enc/      # Encrypted configs (committed)
├── clusterconfig/          # Generated configs (gitignored)
├── tool-pods/              # Debug/temporary pods
├── app1/                   # Example Helm output
└── AGENTS.md               # AI context
```
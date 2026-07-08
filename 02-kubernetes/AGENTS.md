# Talos Linux Cluster - 02-kubernetes

## Structure

```
02-kubernetes/
├── talconfig.yaml              # Talhelper main config
├── talenv.yaml                 # Environment variables
├── talsecret.sops.yaml         # Encrypted secrets (SOPS)
├── .sops.yaml                  # SOPS configuration
├── justfile                    # Build automation
├── patches/                    # Kustomize patches
│   ├── machine/
│   │   └── enable-discovery-patch.yaml
│   └── workers/
│       └── kubelet-extra.args-patch.yaml
├── clusterconfig/              # Generated Talos configs (gitignored)
│   ├── talosconfig             # Talos client config
│   ├── kubeconfig             # Kubernetes client config
│   └── merida.akna.lan-*.yaml # Per-node machine configs
├── clusterconfig-enc/          # Encrypted cluster configs
├── app1/                      # Example Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── templates/
│   └── out/                   # Rendered manifests
├── tool-pods/                 # Debug/temp pods
└── README.md
```

## How It Works

1. **talhelper** generates Talos machine configs from `talconfig.yaml`
2. **SOPS + age** encrypts sensitive configs (see `.sops.yaml`)
3. **just** automates generation and encryption workflows
4. CNI is set to `none` - Cilium is installed separately via Helm

## Key Files

- `talconfig.yaml` - Cluster definition (nodes, network, patches)
- `talenv.yaml` - Environment variables (ClusterName, etc.)
- `talsecret.sops.yaml` - Encrypted secrets
- `clusterconfig/` - Generated configs (never commit this)
- `clusterconfig-enc/` - Encrypted configs for git

## Common Commands

```bash
# Generate cluster configs
just genconfig

# Encrypt configs
just encrypt

# Decrypt configs (to /dev/shm)
just decrypt

# Apply to node (from decrypted clusterconfig)
talosctl apply-config --insecure --nodes 10.30.0.29 --file clusterconfig/merida.akna.lan-cp-node01.yaml

# Generate talosconfig
talosctl config merge clusterconfig/talosconfig

# Get kubeconfig
talosctl kubeconfig

# Upgrade Talos
talosctl upgrade --nodes 10.30.0.29 --image ghcr.io/siderolabs/installer:v1.11.0
```

## Node Setup

| Hostname      | IP          | Role           |
|---------------|-------------|----------------|
| cp-node01     | 10.30.0.29  | Control Plane  |
| cp-node02     | 10.30.0.31  | Control Plane  |
| cp-node03     | 10.30.0.32  | Control Plane  |
| w-node04      | 10.30.0.33  | Worker         |

- Cluster Domain: `merida.akna.lan`
- Kubernetes: `v1.32.0`
- Talos: `v1.11.0`
- VIP: `10.30.0.200`

## Adding a New Node

1. Add node to `talconfig.yaml` under `nodes:`
2. Run `just generate` to create configs
3. Apply config: `talosctl apply-config --insecure --nodes <IP> --file clusterconfig/<hostname>.yaml`

## Patches

Patches are applied via `talconfig.yaml`:
```yaml
patches:
  - "@./patches/machine/enable-discovery-patch.yaml"
```

## Secrets Management

- Uses **age** encryption via SOPS
- Keys defined in `.sops.yaml`
- Always decrypt to `/dev/shm` (tmpfs), never to disk

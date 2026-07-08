# Homelab Monorepo

This is the public monorepo for our bare-metal Kubernetes platform.

## Structure

```
homelab/
├── 00-pxe-bootstrap/          # PXE boot, Matchbox server
├── 01-virtualization/    # NixOS hypervisors, libvirt, OVS
├── 02-kubernetes/        # Talos Linux cluster configs
├── 03-flux-apps/         # FluxCD-managed platform tools
├── 04-argocd-apps/       # ArgoCD-managed applications
├── docs/adr/             # Architecture Decision Records
├── sources/              # Custom Helm charts
├── app-of-apps.yaml      # Root ArgoCD Application
├── devbox.json
└── README.md
```

## How It Works

1. **00-pxe-bootstrap** — PXE provisioning with Matchbox (k0s cluster)
2. **01-virtualization** — NixOS hypervisors managed with deploy-rs, each running one Talos VM
3. **02-kubernetes** — Talos Linux cluster defined with talhelper
4. **03-flux-apps** — FluxCD installs and manages all platform tools
5. **04-argocd-apps** — ArgoCD manages business applications via App-of-Apps

## Adding a New Application

1. Create directory: `04-argocd-apps/<app-name>/`
2. Create `application.yaml` with ArgoCD Application spec
3. The root `app-of-apps.yaml` discovers it automatically (recurse: true)

## Key Patterns

- Infrastructure tools → `03-flux-apps/` (FluxCD)
- Business applications → `04-argocd-apps/` (ArgoCD)
- Secrets encrypted with SOPS+age, or SealedSecrets
- Gateway API HTTPRoutes for all ingress
- CloudNativePG for all database needs
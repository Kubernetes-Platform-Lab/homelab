# Cluster Tools - 03-cluster-tools

## Structure

```
03-cluster-tools/
├── 01.cilium/
├── 02.fluxcd/                    # FluxCD + Flux Kustomizations for all tools
│   ├── kustomization.yaml        # Main kustomization (includes all tool kustomizations)
│   ├── flux-system/              # Flux components
│   │   ├── kustomization.yaml
│   │   ├── gotk-components.yaml
│   │   └── gotk-sync.yaml
│   ├── argocd-kustomization.yaml # Flux Kustomization for ArgoCD
│   ├── cert-manager-kustomization.yaml
│   ├── external-secrets-kustomization.yaml
│   └── ...
├── 03.cert-manager/
├── 04.gateway-api/
├── 05.argocd/
├── 06.sealed-secrets/
├── 07.democratic-csi/
├── 08.local-path-provisioner/
├── 09.external-secrets/
│   ├── kustomization.yaml
│   ├── helmrepo.yaml
│   ├── helmrelease.yaml
│   └── namespace.yaml
└── README.md
```

## How It Works

1. **FluxCD** in `02.fluxcd/` manages all cluster tools
2. Each tool has its own directory (e.g., `06.sealed-secrets/`, `09.external-secrets/`)
3. Each tool directory contains:
   - `helmrepo.yaml` - HelmRepository (source.toolkit.fluxcd.io)
   - `helmrelease.yaml` - HelmRelease (helm.toolkit.fluxcd.io)
   - `namespace.yaml` - Namespace definition
   - `kustomization.yaml` - Kustomization combining above resources
4. Each tool also has a corresponding Flux Kustomization in `02.fluxcd/` (e.g., `external-secrets-kustomization.yaml`)
5. The main `02.fluxcd/kustomization.yaml` includes all tool kustomizations

## Adding a New Cluster Tool

1. Create directory: `0X.<tool-name>/` (use next available number)
2. Create tool files:
   - `helmrepo.yaml` - HelmRepository pointing to chart repo
   - `helmrelease.yaml` - HelmRelease with chart spec
   - `namespace.yaml` - Target namespace
   - `kustomization.yaml` - References above files
3. Create Flux Kustomization in `02.fluxcd/`:
   - `0X.<tool-name>-kustomization.yaml`
4. Add new kustomization to `02.fluxcd/kustomization.yaml` resources

## Apply Commands

```bash
# Flux automatically reconciles from Git
# After pushing changes, Flux will apply them

# To manually reconcile
flux reconcile kustomization flux-system --with-source
```

## Common Helm Repos

- **external-secrets**: https://charts.external-secrets.io
- **sealed-secrets**: https://bitnami-labs.github.io/sealed-secrets
- **argocd**: https://argoproj.github.io/argo-helm
- **cert-manager**: https://charts.jetstack.io
- **cilium**: https://helm.cilium.io
- **gateway-api**: https://kubernetes-sigs.github.io/gateway-api
- **democratic-csi**: https://democratic-csi.github.io/charts
- **local-path-provisioner**: https://rancher.github.io/local-path-provisioner

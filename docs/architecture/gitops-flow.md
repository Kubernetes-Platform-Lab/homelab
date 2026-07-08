# GitOps Flow

This homelab uses a dual GitOps approach: **FluxCD for platform infrastructure**, **ArgoCD for applications**.

## Why Two Tools?

| Aspect | FluxCD | ArgoCD |
|--------|--------|--------|
| Scope | Platform tooling (Cilium, cert-manager, etc.) | Business applications |
| Lifecycle | Changes rarely, high blast radius | Changes frequently, lower blast radius |
| Team | Platform engineers | Application developers |
| Sync model | Push-based (reconciled from git) | Pull-based (agent watches git) |

## Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                        │
│  homelab/                                                    │
│  ├── 00-pxe-bootstrap/                                       │
│  ├── 01-virtualization/   ← Nix flakes, deploy-rs           │
│  ├── 02-kubernetes/       ← talhelper generates configs      │
│  ├── 03-flux-apps/        ← Flux Kustomizations + HelmReleases│
│  ├── 04-argocd-apps/      ← ArgoCD Applications             │
│  └── app-of-apps.yaml     ← Root Application                │
└──────────┬──────────────────────────────────────────────────┘
           │ git push
           ▼
┌──────────────────────┐
│    FluxCD (03-flux-apps)  │
│                      │
│ Watches: 03-flux-apps/│
│ Installs: Cilium,     │
│  cert-manager, ArgoCD,│
│  OpenEBS, Kyverno...  │
└──────────┬───────────┘
           │ deploys ArgoCD
           ▼
┌────────────────────────┐
│  ArgoCD (04-argocd-apps)  │
│                        │
│ Watches: 04-argocd-apps/│
│ Deploys: Ente,         │
│  Mattermost, Linkding...│
└────────────────────────┘
```

## Reconciliation

1. Developer pushes changes to `03-flux-apps/` or `04-argocd-apps/`
2. FluxCD detects changes to `03-flux-apps/` within 5 minutes (or immediately with webhook)
3. ArgoCD detects changes to `04-argocd-apps/` similarly
4. Both tools reconcile state to match git

## Manual Sync

```bash
# Force flux reconciliation
flux reconcile kustomization flux-system --with-source

# Force argocd sync
argocd app sync -l app.kubernetes.io/instance=cluster-apps
```
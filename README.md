# Homelab Applications

ArgoCD-managed application deployments for the Homelab Kubernetes platform. Uses the App-of-Apps pattern -- a single root Application discovers and deploys everything in `apps/`.

**Built by:** [Waldemar Kubica](https://gitlab.com/ebi-droid) and [Jakub Kubica](https://gitlab.com/beraton)
**Infrastructure repo:** [1-Infra](https://gitlab.com/homelab-dev/1-Infra)

---

## Architecture

```
ArgoCD (deployed by FluxCD in 1-Infra)
  └─► app-of-apps.yaml (root Application, recursive discovery)
       ├── cloudnativepg/    PostgreSQL operator (foundation for app databases)
       ├── ente/             End-to-end encrypted photo backup
       ├── mattermost/       Team chat with operator pattern
       ├── linkding/         Bookmark manager
       ├── alloy/            Telemetry collector → VictoriaMetrics
       ├── diagnostic-app/   Test workloads (kuard + podinfo)
       └── nginx/            Minimal test deployment
```

## Deployed Applications

### CloudNativePG -- PostgreSQL Operator

| | |
|---|---|
| **Chart** | cloudnative-pg v0.22.0 |
| **Purpose** | Manages PostgreSQL clusters as Kubernetes-native resources |

Foundation dependency. Both Ente and Mattermost use CloudNativePG `Cluster` CRs for their databases: 2-instance PostgreSQL 17 clusters with pod anti-affinity, `openebs-lvm` storage, and automatic failover.

### Ente Photos -- Encrypted Photo Backup

| | |
|---|---|
| **Chart** | ente-photos v0.2.0 |
| **Routes** | `photos.akna.one.pl`, `ente-auth.akna.one.pl`, `api-ente.akna.one.pl` |
| **Database** | CloudNativePG cluster (2 instances, 5Gi) |

Self-hosted, end-to-end encrypted photo/video storage. Deploys three web frontends (photos, auth, accounts) and a backend API server (museum). External database via CNPG.

### Mattermost -- Team Chat

| | |
|---|---|
| **Operator** | mattermost-operator v1.0.5, Mattermost v11.4.3 |
| **Route** | `mattermost.akna.one.pl` |
| **Database** | CloudNativePG cluster (2 instances, 5Gi) |

Deployed via the Mattermost Kubernetes Operator. Includes the operator, CRDs (from upstream GitHub), and a `Mattermost` CR. File storage on a 2Gi `openebs-lvm` PVC. Webhooks enabled for Robusta/Kubewatch integration.

### Linkding -- Bookmark Manager

| | |
|---|---|
| **Chart** | linkding v1.1.20 |
| **Route** | `linkding.akna.one.pl` |
| **Storage** | 5Gi PVC on `openebs-lvm` |

Self-hosted bookmark manager with tagging and search.

### Grafana Alloy -- Telemetry Collector

| | |
|---|---|
| **Chart** | alloy v1.5.0 |
| **Namespace** | monitoring |

Collects metrics from CloudNativePG, node-exporter, and kube-state-metrics via Kubernetes service discovery. Writes to VictoriaMetrics (`vmsingle-vm.monitoring.svc`).

### Diagnostic App and Nginx -- Test Workloads

Custom Helm chart deploying kuard + podinfo for cluster validation. Nginx deployment with Grafana Beyla annotation for eBPF-based auto-instrumentation.

## Repository Structure

```
2-Apps/
├── app-of-apps.yaml          # Root ArgoCD Application (recursive discovery)
├── apps/
│   ├── alloy/                # Grafana Alloy telemetry collector
│   ├── cloudnativepg/        # PostgreSQL operator
│   ├── diagnostic-app/       # Test workloads (custom chart)
│   ├── ente/                 # Ente Photos + CNPG database + HTTPRoutes
│   ├── linkding/             # Bookmark manager + PVC + HTTPRoute
│   ├── mattermost/           # Operator + CRDs + installation + CNPG database
│   └── nginx/                # Minimal test deployment
├── sources/
│   └── charts/
│       ├── diagnostic-app/   # Custom Helm chart (kuard + podinfo)
│       └── common/           # Reusable generic Helm chart library
└── devbox.json
```

## Patterns

| Pattern | Implementation |
|---------|---------------|
| **Routing** | Gateway API HTTPRoutes via `internal-gateway`, domain `*.akna.one.pl` |
| **DNS** | External-DNS annotations on HTTPRoutes for automatic record creation |
| **Databases** | CloudNativePG clusters (PostgreSQL 17, 2 instances, anti-affinity) |
| **Storage** | `openebs-lvm` StorageClass for all persistent data |
| **Secrets** | SealedSecrets (Bitnami) for credentials in git |
| **Monitoring** | Alloy scrapes → VictoriaMetrics, Beyla eBPF instrumentation on nginx |
| **Sync policy** | Infrastructure apps: automated. User-facing apps: manual sync |

## Adding a New Application

1. Create `apps/<app-name>/application.yaml` with ArgoCD Application spec
2. Add supporting manifests (CNPG database, HTTPRoute, PVC) alongside it
3. Push to git -- the root app-of-apps discovers it automatically (recursive)
4. Sync manually in ArgoCD (or enable automated sync in the Application spec)

See [2-Apps/AGENTS.md](AGENTS.md) for detailed structural conventions.

# ArgoCD Applications - 2-Apps

## Structure

```
2-Apps/
├── app-of-apps.yaml          # Root Application (points to apps/)
├── apps/
│   ├── cloudnativepg/
│   │   └── application.yaml  # ArgoCD Application for CloudNativePG
│   ├── victoriametrics/
│   │   └── application.yaml  # ArgoCD Application for VictoriaMetrics
│   └── grafana/
│       ├── application.yaml  # ArgoCD Application for Grafana
│       ├── dashboards/      # Grafana dashboards (ConfigMaps)
│       │   └── victoriametrics.yaml
│       └── datasources/     # Grafana datasources (ConfigMaps)
│           └── datasources.yaml
├── devbox.json
└── README.md
```

## How It Works

1. **app-of-apps.yaml** - Root ArgoCD Application that discovers all `*/application.yaml` files in `apps/` directory
2. Each app directory contains its own ArgoCD Application definition
3. Grafana includes ConfigMaps for dashboards and datasources (loaded via sidecar)

## Adding a New Application

1. Create directory: `apps/<app-name>/`
2. Create `application.yaml` with ArgoCD Application spec
3. Update `app-of-apps.yaml` if needed

## Apply Commands

```bash
# Apply root app-of-apps
kubectl apply -f app-of-apps.yaml

# Or apply all individually
kubectl apply -f apps/*/application.yaml
```

## Key Patterns

- Use ArgoCD Applications (not ApplicationSets) for single cluster
- ApplicationSets only when deploying to multiple clusters
- Grafana dashboards/datasources: use ConfigMaps with labels `grafana_dashboard: "1"` or `grafana_datasource: "1"`
- Update `repoURL` in app-of-apps.yaml before applying

## Helm Charts

- **cloudnativepg**: https://cloudnative-pg.github.io/charts
- **victoriametrics**: https://victoriametrics.github.io/helm-charts
- **grafana**: https://grafana.github.io/helm-charts

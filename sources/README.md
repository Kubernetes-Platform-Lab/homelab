# Custom Helm Charts

Helm charts developed for this homelab. Used by ArgoCD applications and diagnostic workloads.

## Charts

| Chart | Purpose |
|-------|---------|
| `charts/common/` | Generic application chart (deployment, service, ingress, HPA, PVC, secrets) |
| `charts/diagnostic-app/` | Test/debug application for validating cluster features |

## Development

```bash
# Lint charts
helm lint sources/charts/*/

# Render templates
helm template test-release sources/charts/common/

# Package for local use
helm package sources/charts/common/
```
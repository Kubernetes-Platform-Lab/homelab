# ArgoCD Applications

Applications managed by ArgoCD via the App-of-Apps pattern. Root Application: [`app-of-apps.yaml`](../app-of-apps.yaml).

## Applications

| Application | Type | Database | Gateway Route |
|-------------|------|----------|---------------|
| alloy | DaemonSet | — | — |
| cloudnativepg | Operator | — | — |
| diagnostic-app | Deployment | — | — |
| ente | Deployment | CloudNativePG | HTTPRoute |
| linkding | Deployment | — | HTTPRoute |
| mattermost | Operator + Installation | CloudNativePG | HTTPRoute |
| nginx | Deployment | — | HTTPRoute |

## Patterns

- Each app has its own `application.yaml` ArgoCD Application definition
- Databases use CloudNativePG clusters defined within the app directory
- Routes use Gateway API HTTPRoutes
- Secrets use Bitnami SealedSecrets for encrypted credentials in git

## Adding a New App

1. Create directory: `04-argocd-apps/<app-name>/`
2. Create `application.yaml` with ArgoCD Application spec
3. Push — ArgoCD auto-discovers via `app-of-apps.yaml`
4. Apply manually if needed: `kubectl apply -f 04-argocd-apps/*/application.yaml`
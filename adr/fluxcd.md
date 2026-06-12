| Field | Value |
|---|---|
| ADR Title | Use FluxCD as a CD application |
| ADR Number | 0003 |
| Status | Accepted |
| Decision Date | 25/04/2026 |
| Domain | Continous Delivery |
| Impact Level | High |
| Context | We wanted to provide a reliable, consistent and standarized way of deploying and maintaining cluster components. |
| Decision | We have already deployed ArgoCD for user-exposed applications working inside k8s cluster. To keep our lab more robust and for educational purposes we decided to deploy all our cluster apps using FluxCD which is a CNCF project and one of the most popular GitOps tool for k8s. |
| Alternatives | **1)** ArgoCD (accepted: we have already implemented ArgoCD for our production apps and use it very frequently) |
| Pros & Cons | **Pros:** Centralized k8s production apps management; Very robust CLI; Good documentation and tons of user information in the internet about it; **Cons:** (Not really a con but still) No native web UI |
| Assumptions | FluxCD made deploying cluster apps fast and in a structured way but in a slightly different way that ArgoCD |
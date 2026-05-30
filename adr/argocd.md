| Field | Value |
|---|---|
| ADR Title | Use ArgoCD as a CD application |
| ADR Number | 0002 |
| Status | Accepted |
| Decision Date | 25/04/2026 |
| Domain | Continous Delivery |
| Impact Level | High |
| Context | We wanted to provide a reliable, consistent and standarized way of deploying user-exposed apps in our lab environment. The two main requirements we have taken into consideration was to have both web UI to manage resources as well as robust CLI. |
| Decision | We have deployed ArgoCD 'app of apps' that will manage all production applications working inside k8s cluster. This approach allows us to create folders for each application and define it's all resources there. This way each app is managed in a structured manner and separater from each other. |
| Alternatives | **1)** Flux (accepted: we have also implemented flux for internal k8s apps essential to build production apps; this is because we wanted to have an experience in both those tools)|
| Pros & Cons | **Pros:** Centralized k8s production apps management; Fast and readable web UI; Good documentation and tons of user information in the internet about ArgoCD |
| Assumptions | ArgoCD made deploying production apps extremely fast in a clear and structured way |
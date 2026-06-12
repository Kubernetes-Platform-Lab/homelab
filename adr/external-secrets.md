| Field | Value |
|---|---|
| ADR Title | Use External Secrets operator to manage cluster secrets using external secret management system |
| ADR Number | 0004 |
| Status | Planned |
| Decision Date | 04/06/2026 |
| Domain | Secret Management, Security |
| Impact Level | High |
| Context | Managing secrets across multiple k8s clusters is generating a lot of labour by managing secrets manually and encrypting them every time before commiting any changes. In order to avoid managing secrets manually we decided to manage them 'the kubernetes way' |
| Decision | 
| Alternatives |
| Pros & Cons |
| Assumptions |
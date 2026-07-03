| Field | Value |
|---|---|---|
| ADR Title | CI/CD Tooling - GitOps Strategy |
| ADR Number | 0001 |
| Status | Accepted |
| Decision Date | 25/04/2026 |
| Domain | Continuous Delivery |
| Impact Level | High |

## Context and Problem Statement

We needed a reliable, consistent, and standardized way of deploying both user-exposed applications and internal cluster components in our lab environment. The two main requirements were to have a robust CLI and, where practical, a web UI for resource management.

This required us to evaluate GitOps tools that could:

- Manage production applications exposed to users in a centralized manner.
- Handle internal cluster infrastructure components essential to building and maintaining the lab.
- Provide good documentation and community support.
- Offer flexibility between web UI and CLI workflows.

## Considered Options

### ArgoCD only

Use ArgoCD exclusively for all workloads — both user-facing applications and internal cluster components. ArgoCD provides a mature web UI, strong CLI, and follows the "app of apps" pattern.

- **Pros**: Single toolchain, unified management surface, fast and readable web UI, extensive community resources.
- **Cons**: Does not provide direct exposure to a second CNCF GitOps tool; single point of failure in tooling approach.

### FluxCD only

Use FluxCD exclusively for all workloads. FluxCD is a CNCF-graduated project with a very robust CLI and strong Kubernetes-native design.

- **Pros**: CNCF-graduated, very robust CLI, excellent documentation, strong Kubernetes-native design.
- **Cons**: No native web UI, less visual feedback for resource state.

### ArgoCD + FluxCD (selected)

Deploy both ArgoCD and FluxCD, each responsible for a distinct category of workloads:

- **ArgoCD**: Manages all user-exposed production applications via an "app of apps" pattern.
- **FluxCD**: Manages all internal cluster components (infrastructure and platform services).

This dual-tool approach provides hands-on experience with both major GitOps tools while leveraging each one's strengths.

- **Pros**:
  - Centralized management for both app categories.
  - Educational value — team gains proficiency in both ArgoCD and FluxCD.
  - Reduces blast radius: issues in one toolchain do not affect the other.
  - ArgoCD's web UI for production apps; FluxCD's CLI for cluster components.
- **Cons**:
  - Operational overhead of maintaining two GitOps tools.
  - Team must stay proficient in both toolchains.

## Decision Outcome

We chose to deploy **both ArgoCD and FluxCD** — ArgoCD for user-exposed production applications and FluxCD for internal cluster infrastructure components. This hybrid approach balances operational robustness with educational value, giving the team direct experience with the two most popular CNCF GitOps tools.

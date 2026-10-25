# ADR-005: CI/CD Tooling - GitOps Strategy

**Date:** 2026-04-25
**Status:** accepted
**Authors:** Jakub Kubica

## Context

We needed a reliable, consistent, and standardized way of deploying both user-exposed applications and internal cluster components in our lab environment. The two main requirements were a robust CLI and, where practical, a web UI for resource management.

This required us to evaluate GitOps tools that could:

- Manage production applications exposed to users in a centralized manner
- Handle internal cluster infrastructure components essential to building and maintaining the lab
- Provide good documentation and community support
- Offer flexibility between web UI and CLI workflows

## Decision

Deploy **both ArgoCD and FluxCD**, each responsible for a distinct category of workloads:

- **ArgoCD** manages all user-exposed production applications via an "app of apps" pattern
- **FluxCD** manages all internal cluster components (infrastructure and platform services)

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|-------------|
| **ArgoCD only** | Single toolchain with a mature web UI, strong CLI and the "app of apps" pattern, but the lab would gain no experience with a second CNCF GitOps tool and would rely on a single tooling approach. |
| **FluxCD only** | CNCF-graduated with a robust CLI and excellent Kubernetes-native design, but no native web UI and less visual feedback for resource state. |

## Consequences

- Centralized management for both application categories
- Educational value: the team gains proficiency in both ArgoCD and FluxCD
- Reduced blast radius: issues in one toolchain do not affect the other
- ArgoCD's web UI for production apps, FluxCD's CLI for cluster components
- Operational overhead of maintaining two GitOps tools
- The team must stay proficient in both toolchains

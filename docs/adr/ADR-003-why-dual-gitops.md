# ADR-003: Why Dual GitOps (FluxCD + ArgoCD)

**Date:** 2025-07-09
**Status:** accepted
**Authors:** Waldemar Kubica

## Context

We needed a GitOps tool for managing cluster resources. Initial options: use one tool (FluxCD or ArgoCD) for everything, or split responsibilities between two.

## Decision

Use **FluxCD for infrastructure/platform tooling** and **ArgoCD for applications**.

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|-------------|
| **FluxCD only** | Flux is great for infrastructure (HelmReleases, Kustomizations) but ArgoCD's App-of-Apps pattern and UI are better for application teams. |
| **ArgoCD only** | ArgoCD is opinionated about application structure. Flux handles cluster bootstrapping (CRDs, Helm repos) more cleanly. |

## Consequences

- Different reconciliation cadences: Flux syncs infrastructure (critical), ArgoCD syncs apps (tolerant)
- FluxCD installs ArgoCD itself — ArgoCD is managed as a Flux-managed tool
- Application developers only interact with ArgoCD, not FluxCD
- Platform changes (Flux) have larger blast radius than app changes (ArgoCD)
- Self-healing: cluster rebuild from git push without manual intervention
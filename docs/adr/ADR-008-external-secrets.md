# ADR-008: External Secrets Operator for Cluster Secrets

**Date:** 2026-06-04
**Status:** proposed
**Authors:** Jakub Kubica

## Context

Managing secrets across multiple Kubernetes clusters generates a lot of labour when secrets are handled manually and encrypted every time before committing a change. We wanted to avoid that manual lifecycle and manage secrets "the Kubernetes way", sourcing them from an external secret management system instead of storing them in git.

## Decision

Use the **External Secrets Operator (ESO)** to synchronise secrets from the external secret store (OpenBao) into Kubernetes Secrets through `ClusterSecretStore` and `ExternalSecret` resources.

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|-------------|
| **Manual secrets encrypted before commit** | Every change requires re-encrypting and committing the ciphertext, which generates a lot of labour and drift across clusters. |
| **SealedSecrets only** | Already used for some workloads, but the sealed ciphertext is bound to the cluster and still requires committing secret material to git. Kept for cases where no external store is available. |

## Consequences

- Secrets are no longer stored in git; they are pulled from OpenBao by ESO
- Each workload declares an `ExternalSecret` referencing the `homelab-secretstore` `ClusterSecretStore`
- Rotation and revocation happen in the external store and propagate on the configured `refreshInterval`
- ESO and OpenBao become critical-path components: if they are unavailable, newly created pods cannot obtain their secrets
- Cluster bootstrap must provision the store credentials before dependent applications can start

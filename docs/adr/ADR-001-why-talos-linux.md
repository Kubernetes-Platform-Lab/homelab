# ADR-001: Why Talos Linux

**Date:** 2025-07-09
**Status:** accepted
**Authors:** Waldemar Kubica

## Context

We needed a Kubernetes operating system for our 4-node cluster. Options considered: Talos Linux, k3s, RKE2, and kubeadm on Ubuntu/Debian.

Requirements:
- Minimal attack surface (no SSH, no package manager)
- Declarative, API-driven configuration
- Atomic upgrades with rollback
- Small resource footprint (each VM has 6-14 GiB RAM)

## Decision

Use Talos Linux.

## Alternatives Considered

| Option | Why Rejected |
|--------|-------------|
| k3s | Built on containerd + SQLite, not a true Kubernetes OS. Less suitable for production patterns. |
| RKE2 | Rancher ecosystem dependency. More complex than needed for our size. |
| kubeadm (Ubuntu) | Traditional approach with SSH access — larger attack surface, imperative configs. |

## Consequences

- All node management goes through `talosctl` API — no SSH access even for debugging
- Upgrades are atomic (A/B disk partitions), tested and fast
- Steeper initial learning curve for operators used to SSH-based management
- Kubernetes version is tied to Talos releases (can't independently upgrade)
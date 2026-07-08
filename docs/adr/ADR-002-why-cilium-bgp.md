# ADR-002: Why Cilium with eBGP

**Date:** 2025-07-09
**Status:** accepted
**Authors:** Waldemar Kubica

## Context

We needed a CNI with:
- Native LoadBalancer IP advertisement (no MetalLB)
- kube-proxy replacement for scalability
- Network policy enforcement
- Observability (Hubble)
- Gateway API support

## Decision

Use Cilium with eBGP for LoadBalancer IP advertisement, kube-proxy replacement enabled, and Hubble for observability.

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|-------------|
| **Calico** | No native BGP LoadBalancer IP advertisement. Requires MetalLB alongside. |
| **Flannel** | Too simple — no network policies, no BGP, no encryption. |
| **MetalLB + Flannel** | Two separate tools to maintain. BGP is MetalLB's second-class mode. |
| **kube-router** | Limited feature set, smaller community. |

## Consequences

- Single CNI handles networking, policy, LB IPs, and observability
- eBGP advertisements mean LoadBalancer IPs work without extra components
- Hubble provides network flow visibility (mTLS-flows, DNS, HTTP metrics)
- Cilium's eBPF datapath means kernel dependency — must match Talos kernel support
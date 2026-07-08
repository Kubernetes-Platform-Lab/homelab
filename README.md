# Homelab — Bare-Metal Kubernetes Platform

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.34.0-326CE5?style=flat-square&logo=kubernetes)](https://kubernetes.io)
[![Talos](https://img.shields.io/badge/Talos-v1.12.4-FF7300?style=flat-square&logo=linux)](https://www.talos.dev)
[![NixOS](https://img.shields.io/badge/Hypervisors-4%C3%97%20NixOS-7EB42C?style=flat-square&logo=nixos)](./01-virtualization/)
[![CNI](https://img.shields.io/badge/CNI-Cilium-1D9E75?style=flat-square)](./03-flux-apps/01.cilium/)
[![Mesh](https://img.shields.io/badge/Mesh-Istio%20Ambient-1D9E75?style=flat-square)](./03-flux-apps/22.istio-ambient/)
[![GitOps](https://img.shields.io/badge/GitOps-FluxCD%20%2B%20ArgoCD-1D9E75?style=flat-square)](./docs/adr/ADR-3-dual-gitops.md)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

An **over-engineered, production-grade Kubernetes homelab** built entirely from scratch. From PXE-booting bare metal to running real applications behind a service mesh — everything is declarative, version-controlled, and GitOps-driven.

**Built by:** [Waldemar Kubica](https://github.com/ebi-droid) · [Jakub Kubica (Beraton)](https://github.com/beraton)

---

## Why This Lab Exists

> *"We don't have a place to break things safely."*

We are cloud infrastructure engineers who need a realistic sandbox to practice, experiment, and stay current. This lab exists to:

1. **Test production-grade patterns** — Cilium eBGP, Istio Ambient Mesh, Gateway API, dual GitOps — without risking a real production environment.
2. **Learn by doing** — Every tool here was chosen because we wanted to understand it deeply, not because it was the easiest option.
3. **Build a portfolio** — This repository is a live artifact showing real engineering decisions, real debugging, and real operational work.
4. **Collaborate** — Two engineers sharing a codebase, reviewing each others' changes, and growing together.

## Architecture

```mermaid
graph TB
    subgraph Provisioning["00 · PXE Bootstrap"]
        PXE["k0s + Matchbox<br/>PXE Boot Server"]
    end

    subgraph Hypervisors["01 · Virtualization — NixOS (4x bare-metal)"]
        hyp01["hyp01 · 10.20.0.30"]
        hyp02["hyp02 · 10.20.0.31"]
        hyp03["hyp03 · 10.20.0.32"]
        hyp04["hyp04 · 10.20.0.33"]
    end

    subgraph Kubernetes["02 · Kubernetes — Talos Linux · K8s v1.34"]
        cp1["cp-node01<br/>Control Plane"]
        cp2["cp-node02<br/>Control Plane"]
        cp3["cp-node03<br/>Control Plane"]
        w4["w-node04<br/>Worker"]
    end

    subgraph GitOps["GitOps Layer"]
        flux["FluxCD<br/>Infrastructure"]
        argocd["ArgoCD<br/>Applications"]
    end

    subgraph Platform["03 · Platform Tooling (FluxCD)"]
        cilium["Cilium CNI<br/>eBGP · Hubble · kube-proxy replacement"]
        gw["Gateway API<br/>Cilium GatewayClass · wildcard TLS"]
        istio["Istio Ambient Mesh<br/>ztunnel · sidecar-less"]
        cert["cert-manager<br/>Let's Encrypt · deSEC DNS-01"]
        dns["External DNS<br/>deSEC webhook"]
        storage["OpenEBS LVM<br/>Local Storage"]
        secrets["Sealed Secrets · External Secrets<br/>SOPS/age"]
        kyverno["Kyverno<br/>Policy Engine"]
    end

    subgraph Applications["04 · Applications (ArgoCD)"]
        cnpg["CloudNativePG<br/>PostgreSQL Operator"]
        ente["Ente Photos<br/>Encrypted Photo Backup"]
        mattermost["Mattermost<br/>Team Chat"]
        linkding["Linkding<br/>Bookmark Manager"]
        alloy["Alloy<br/>Telemetry Collector"]
    end

    PXE --> hyp01 & hyp02 & hyp03 & hyp04
    hyp01 --> cp1
    hyp02 --> cp2
    hyp03 --> cp3
    hyp04 --> w4
    cp1 & cp2 & cp3 & w4 --> flux
    flux --> cilium & gw & istio & cert & dns & storage & secrets & kyverno
    flux --> argocd
    argocd --> cnpg & ente & mattermost & linkding & alloy
```

## Network Topology

4 VLANs with **Open vSwitch** bridging on each hypervisor. eBGP between cluster and ToR switch.

| VLAN | Subnet | Purpose | Routing |
|------|--------|---------|---------|
| 10 | 10.10.0.0/16 | PXE boot & provisioning | Static |
| 20 | 10.20.0.0/16 | Hypervisor management | Static |
| 30 | 10.30.0.0/16 | Kubernetes cluster | Internal |
| 40 | 10.40.0.0/16 | Services & LoadBalancer IPs | eBGP (ASN 65000 ↔ 65001) |

**BGP:** 4 nodes advertise 10.40.0.150–160 via eBGP to ToR switch (ASN 65001) with ECMP.

## Repository Layout

```
homelab/
├── 00-pxe-bootstrap/         # PXE boot with Matchbox (k0s cluster)
├── 01-virtualization/        # NixOS hypervisors, libvirt, OVS
├── 02-kubernetes/            # Talos Linux cluster (talhelper)
├── 03-flux-apps/             # FluxCD-managed platform tools
├── 04-argocd-apps/            # ArgoCD-managed applications
├── docs/                    # Documentation & ADRs
│   ├── adr/                  # Architecture Decision Records
│   ├── architecture/         # Detailed architecture docs
│   ├── operations/          # Runbooks & procedures
│   └── platform/            # Platform component guides
├── sources/                  # Custom Helm charts
├── app-of-apps.yaml          # Root ArgoCD Application
└── README.md
```

Each layer is independently deployable and version-controlled. See individual READMEs for details.

## Infrastructure Stack

| Layer | Tech | Nodes | Management |
|-------|------|-------|------------|
| Provisioning | k0s + Matchbox PXE | 1 VM | Declarative (k0sctl) |
| Virtualization | NixOS + libvirt + OVS | 4 bare-metal | Nix flakes, deploy-rs |
| Kubernetes | Talos Linux | 3 CP + 1 worker | talhelper, talosctl |
| GitOps (infra) | FluxCD | — | Git push → reconcile |
| GitOps (apps) | ArgoCD | — | App-of-Apps pattern |

## Platform Tooling

| Category | Tool | Version | Purpose |
|----------|------|---------|---------|
| CNI | Cilium | 1.18.5 | eBPF datapath, eBGP, Hubble, kube-proxy replacement |
| Service Mesh | Istio Ambient | 1.29.1 | Sidecar-less mesh (ztunnel) |
| Ingress | Gateway API | — | Cilium GatewayClass, wildcard TLS |
| Certificates | cert-manager | 1.19.2 | Let's Encrypt via deSEC DNS-01 |
| DNS | External DNS | 1.20.0 | Automatic DNS with deSEC webhook |
| Storage | OpenEBS LVM | 4.0.0 | Local PV via LVM |
| Storage | Democratic-CSI | — | ZFS/iSCSI block & filesystem |
| Secrets | Sealed Secrets | 2.18.0 | Encrypted secrets in git |
| Secrets | External Secrets | ≥1.15.0 | External secrets operator |
| Policy | Kyverno | 3.7.0 | Kubernetes policy engine |
| GitOps | FluxCD | — | Infrastructure lifecycle |
| GitOps | ArgoCD | 9.4.15 | Application lifecycle |

## Applications

| App | Purpose | Database | Storage |
|-----|---------|----------|---------|
| CloudNativePG | PostgreSQL operator | — | openebs-lvm |
| Ente Photos | Encrypted photo backup | CNPG cluster | openebs-lvm |
| Mattermost | Team chat | CNPG cluster | openebs-lvm + ZFS |
| Linkding | Bookmark manager | — | openebs-lvm |
| Alloy | Telemetry collection | — | — |

## Key Decisions

| Decision | Rationale | ADR |
|----------|-----------|-----|
| Talos Linux | Immutable, API-driven, no SSH | Planned |
| Cilium + eBGP | eBPF datapath, native LB IP advertisement | Planned |
| Dual GitOps | Different lifecycles for infra vs apps | Planned |
| NixOS for hypervisors | Reproducible, atomic rollbacks, declarative VMs | Planned |
| Gateway API | Role-oriented, portable across implementations | Planned |

## Security

- All secrets encrypted with **SOPS+age**. Decrypted only to `/dev/shm` (tmpfs).
- **Sealed Secrets** for Kubernetes secrets committed to the repository.
- **Kyverno** policies enforce security standards.
- **Istio Ambient** provides mTLS between services.
- No plaintext credentials, kubeconfigs, or private keys in this repository.

## Documentation

Detailed documentation lives in the [`docs/`](./docs/) directory:

- **[Architecture Decision Records](./docs/adr/)** — Why we chose each technology
- **Platform guides** — How each component is configured
- **Operations** — Runbooks and procedures

Full documentation generated from the repository structure is planned.

## Project Status

- [x] PXE boot infrastructure
- [x] NixOS hypervisors
- [x] Talos Linux cluster
- [x] Cilium CNI + eBGP
- [x] FluxCD platform tools
- [x] ArgoCD applications
- [ ] Observability (Grafana, dashboards, alerting)
- [ ] CI/CD pipeline
- [ ] Structured logging (Loki)
- [ ] Automated testing
- [ ] Full documentation

## Contributors

- **Waldemar Kubica** ([@ebi-droid](https://github.com/ebi-droid)) — Architecture & design, NixOS, Talos, Cilium, FluxCD, ArgoCD, Istio, Kyverno, networking, observability
- **Jakub Kubica** ([@beraton](https://github.com/beraton)) — Democratic-CSI, OpenEBS, Ente Photos, Linkding, Mattermost, custom Helm charts, diagnostic tooling

## License

MIT — This project is for educational purposes. Use at your own risk.
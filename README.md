# Homelab Infrastructure

Bare-metal Kubernetes platform built from scratch -- from PXE boot to production-grade cluster tooling. Fully declarative, fully GitOps-managed.

**Built by:** [Waldemar Kubica](https://gitlab.com/ebi-droid) and [Jakub Kubica](https://gitlab.com/beraton)
**Applications repo:** [2-Apps](https://gitlab.com/homelab-dev/2-Apps)

---

## Architecture

```
PXE Boot (k0s + Matchbox)
  └─► NixOS Hypervisors (4x bare-metal, OVS, libvirt/KVM)
       └─► Talos Linux VMs (Kubernetes v1.34, 3 control-plane + 1 worker)
            └─► Platform Tools (FluxCD GitOps)
                 ├── Cilium CNI (eBGP, kube-proxy replacement, Hubble)
                 ├── Gateway API (Cilium GatewayClass, wildcard TLS)
                 ├── cert-manager (Let's Encrypt, DNS-01 via deSEC)
                 ├── Istio Ambient Mesh (sidecar-less, ztunnel)
                 ├── Storage: OpenEBS LVM (local) + Democratic-CSI (ZFS/iSCSI)
                 ├── Secrets: Sealed Secrets + External Secrets + SOPS/age
                 ├── Policy: Kyverno
                 ├── DNS: External DNS (deSEC webhook)
                 └── ArgoCD (deploys applications from 2-Apps repo)
```

## Network

4 VLANs with Open vSwitch bridging on each hypervisor:

| VLAN | Subnet       | Purpose                                 |
|------|--------------|-----------------------------------------|
| 10   | 10.10.0.0/16 | PXE boot and provisioning               |
| 20   | 10.20.0.0/16 | Hypervisor management                   |
| 30   | 10.30.0.0/16 | Kubernetes cluster (API, etcd, inter-node) |
| 40   | 10.40.0.0/16 | Services and BGP (LoadBalancer IPs)     |

**BGP peering:** Cluster nodes (ASN 65000) ↔ ToR switch (ASN 65001) on VLAN 40. LoadBalancer IPs (10.40.0.150-160) are advertised via eBGP with ECMP across all nodes.

## Repository Structure

```
1-Infra/
├── 00-pxeboot/           # Bootstrap k0s cluster running Matchbox PXE server
├── 01-nixos-servers/     # NixOS configs for 4 hypervisors (deploy-rs, disko, OVS)
├── 02-talos/             # Talos Linux cluster definition (talhelper, 4 nodes)
└── 03-cluster-tools/     # FluxCD-managed platform tools (Cilium, ArgoCD, etc.)
```

### 00-pxeboot -- PXE Boot Server

Single-node k0s cluster hosting a [Matchbox](https://matchbox.psdn.io/) PXE server for network booting bare-metal machines.

- k0s with Calico CNI (VXLAN)
- Matchbox v0.11.0 in hostNetwork mode
- SOPS+age encrypted kubeconfig

### 01-nixos-servers -- Hypervisor Hosts

4 NixOS bare-metal hypervisors managed declaratively with Nix Flakes and deployed remotely via deploy-rs.

| Host  | Management IP | Hardware         |
|-------|---------------|------------------|
| hyp01 | 10.20.0.30   | NVMe, AMD/Intel  |
| hyp02 | 10.20.0.31   | NVMe, AMD/Intel  |
| hyp03 | 10.20.0.32   | NVMe, AMD/Intel  |
| hyp04 | 10.20.0.33   | NVMe, AMD/Intel  |

Key capabilities:
- **Virtualization:** libvirt/QEMU/KVM with declarative VM definitions
- **Networking:** Open vSwitch bridges with VLAN tagging, systemd-networkd
- **Disk management:** disko for declarative partitioning (GPT, EFI, XFS)
- **Secrets:** sops-nix for encrypted passwords
- **Monitoring:** Cockpit web UI

### 02-talos -- Kubernetes Cluster

Talos Linux cluster managed with [talhelper](https://budimanjojo.github.io/talhelper/). Dual-homed nodes with separate cluster and service networks.

| Node      | VLAN 30 (cluster) | VLAN 40 (services) | Role          |
|-----------|--------------------|--------------------|---------------|
| cp-node01 | 10.30.0.29         | 10.40.0.29         | Control Plane |
| cp-node02 | 10.30.0.31         | 10.40.0.31         | Control Plane |
| cp-node03 | 10.30.0.32         | 10.40.0.32         | Control Plane |
| w-node04  | 10.30.0.33         | 10.40.0.33         | Worker        |

- **K8s version:** v1.34.0 | **Talos version:** v1.12.4
- **API VIP:** 10.30.0.200
- **Cluster domain:** merida.akna.lan
- **Pod CIDR:** 10.244.0.0/16 | **Service CIDR:** 10.96.0.0/12
- **Extensions:** qemu-guest-agent, iscsi-tools, CPU microcode

### 03-cluster-tools -- Platform Tooling (FluxCD)

All cluster tools are managed by FluxCD using HelmReleases. Each tool follows a consistent pattern: `helmrepo.yaml` + `helmrelease.yaml` + `namespace.yaml` + `kustomization.yaml`.

| Tool | Version | Purpose |
|------|---------|---------|
| Cilium | 1.18.5 | CNI, eBGP, kube-proxy replacement, Gateway API, Hubble |
| ArgoCD | 9.4.15 | GitOps for applications (deploys from 2-Apps) |
| cert-manager | 1.19.2 | TLS certificates (Let's Encrypt via deSEC DNS-01) |
| Gateway API | -- | Internal (`*.akna.one.pl`) + external gateways |
| Istio Ambient | 1.29.1 | Sidecar-less service mesh (ztunnel) |
| OpenEBS | 4.0.0 | LVM-based local storage |
| Democratic-CSI | 0.15.1 | ZFS-over-iSCSI from NAS (10.11.1.5) |
| Sealed Secrets | 2.18.0 | Encrypted secrets in git |
| External Secrets | >=1.15.0 | External secrets operator |
| External DNS | 1.20.0 | Automatic DNS (deSEC webhook, Gateway API HTTPRoutes) |
| Kyverno | 3.7.0 | Kubernetes policy engine |
| kube-state-metrics | 5.x | Kubernetes metrics exporter |

## Key Design Decisions

- **Why Talos Linux:** Immutable, API-driven, minimal attack surface. No SSH, no shell, no package manager on nodes.
- **Why Cilium with BGP:** eBPF-based datapath, native LoadBalancer IP advertisement to physical network, kube-proxy replacement, integrated Gateway API support.
- **Why dual GitOps (FluxCD + ArgoCD):** FluxCD manages platform tools (infrastructure concern), ArgoCD manages applications (developer concern). Different lifecycles, different blast radii.
- **Why NixOS for hypervisors:** Reproducible host configuration, atomic upgrades/rollbacks, declarative VM and network definitions.
- **Why Gateway API over Ingress:** Role-oriented API (infra team manages Gateways, app teams manage HTTPRoutes), multi-protocol support, portable across implementations.

*Detailed Architecture Decision Records: coming soon*

## Tools Required

Each subdirectory includes a `devbox.json` for reproducible tool environments:

```bash
# Enter the development shell
devbox shell

# Available tools vary by directory but include:
# kubectl, talosctl, talhelper, k9s, helm, cilium-cli, flux, sops, kubeseal
```

## Security

- All secrets encrypted with SOPS+age. Decrypted only to `/dev/shm` (tmpfs), never to persistent disk.
- Sealed Secrets for Kubernetes secrets committed to git.
- No plaintext credentials in the repository.

# Network Topology

## Overview

4 VLAN architecture with Open vSwitch bridging. eBGP peering between cluster nodes and ToR switch for LoadBalancer IP advertisement.

## VLANs

| VLAN | Subnet | Purpose | Type |
|------|--------|---------|------|
| 10 | 10.10.0.0/16 | PXE boot and provisioning | Untagged on provisioning NIC |
| 20 | 10.20.0.0/16 | Hypervisor management | Management interface |
| 30 | 10.30.0.0/16 | Kubernetes cluster traffic | Cluster node NIC |
| 40 | 10.40.0.0/16 | Services and BGP | Cluster node NIC (LB IPs) |

## BGP Peering

```
Cluster Nodes (ASN 65000)
    ↓ eBGP
ToR Switch (ASN 65001)
    ↓
LoadBalancer IP Pool: 10.40.0.150-160
```

- All 4 nodes peer with ToR switch on VLAN 40
- LoadBalancer IPs advertised via eBGP with ECMP
- Cilium manages BGP advertisements via CiliumBGPPeeringPolicy

## OVS Bridges

Each hypervisor has an Open vSwitch bridge (`br-int`) with VLAN sub-interfaces:

```
Physical NIC
    └─ br-int (OVS bridge)
        ├── mgmt20 (VLAN 20) — hypervisor management
        ├── pxe-net (untagged) — PXE provisioning
        └── Talos VM vNICs
            ├── VLAN 30 — cluster traffic
            └── VLAN 40 — services + BGP
```

## DNS

- Internal: `/etc/hosts` entries on hypervisors
- External: deSEC with External-DNS operator (automatic DNS for Gateway API HTTPRoutes)
- Domain: `*.akna.one.pl`
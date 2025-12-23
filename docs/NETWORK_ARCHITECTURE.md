# Network Architecture Documentation

This document describes the network architecture for the Talos Kubernetes cluster.

## Network Bridges Overview

| Bridge | VLAN | Purpose | NixOS Host IP | Talos VM IP | Subnet |
|--------|------|---------|---------------|-------------|---------|
| **br10** | untagged | PXE Boot | - | DHCP (initial) | - |
| **br20** | 20 | Hypervisor Management | 10.20.0.30/16 | - | 10.20.0.0/16 |
| **br30** | 30 | Kubernetes Nodes | - | 10.30.0.30 | 10.30.0.0/16 |
| **br40** | 40 | LoadBalancer Services | - | Managed by Talos | 10.40.0.0/16 |

## Bridge Details

### br10 - PXE Boot Bridge (Untagged)
- **Purpose**: Initial network boot for Talos installation
- **VLAN**: None (native/untagged on eth0)
- **Configuration**: 
  - Connected directly to eth0
  - No static IP on host
  - Used by VM's first NIC for PXE boot from matchbox
- **Talos Usage**: Initial boot only, gets DHCP from matchbox server

### br20 - Hypervisor Management Bridge (VLAN 20)
- **Purpose**: Management interface for the NixOS hypervisor host
- **VLAN**: 20
- **Configuration**:
  - Host IP: `10.20.0.30/16`
  - Subnet: `10.20.0.0/16`
  - Static IP assignment
- **Usage**: SSH access, monitoring, hypervisor management
- **Talos Usage**: Not used by Talos VM

### br30 - Kubernetes Nodes Bridge (VLAN 30)
- **Purpose**: Communication between Kubernetes cluster nodes
- **VLAN**: 30
- **Configuration**:
  - Host IP: None
  - Talos VM IP: `10.30.0.30` (configured in Talos)
  - Subnet: `10.30.0.0/16`
- **Usage**: 
  - Kubernetes control plane communication
  - etcd cluster communication
  - Pod-to-pod networking (may use CNI overlay)
  - Node-to-node communication

### br40 - LoadBalancer Services Bridge (VLAN 40)
- **Purpose**: External access to Kubernetes services via LoadBalancer type
- **VLAN**: 40
- **Configuration**:
  - Host IP: None
  - Talos manages IP assignments
  - Subnet: `10.40.0.0/16`
- **Usage**:
  - MetalLB or similar LoadBalancer controller assigns IPs from this range
  - External services accessible on these IPs
  - Talos VM participates in this network

## VM Network Interfaces

The Talos VM (`talos-1`) has 4 network interfaces:

1. **eth0** → **br10** (MAC: 52:54:00:12:34:10)
   - Boot priority 1 (PXE boot)
   - Used during installation only
   
2. **eth1** → **br20** (MAC: 52:54:00:12:34:20)
   - VLAN 20 - Management network
   - Not actively used by Talos (reserved for future use)
   
3. **eth2** → **br30** (MAC: 52:54:00:12:34:30)
   - VLAN 30 - Kubernetes nodes network
   - Primary network for Kubernetes operations
   - Talos will configure: `10.30.0.30`
   
4. **eth3** → **br40** (MAC: 52:54:00:12:34:40)
   - VLAN 40 - LoadBalancer services
   - Used by MetalLB or similar for service IPs

## Network Flow

### Initial Installation (PXE Boot)
```
Talos VM (eth0) → br10 → eth0 (physical) → Matchbox Server
                  ↓
            Gets DHCP IP
                  ↓
       Downloads Talos kernel/initrd
                  ↓
            Boots Talos
```

### Normal Operation
```
┌─────────────────────────────────────────────────────┐
│ NixOS Hypervisor Host                               │
│  - br20: 10.20.0.30/16 (Management)                 │
│  - br10, br30, br40: No IPs (VM bridges)            │
└─────────────────────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┬──────────────┐
        │              │              │              │
     br10           br20           br30           br40
   (PXE/unused)  (Management)   (K8s Nodes)      (LB)
        │              │              │              │
        ▼              ▼              ▼              ▼
┌─────────────────────────────────────────────────────┐
│ Talos VM (talos-1)                                  │
│  - eth0 (br10): PXE boot only                       │
│  - eth1 (br20): Not used                            │
│  - eth2 (br30): 10.30.0.30 (K8s control/data)      │
│  - eth3 (br40): LoadBalancer IPs (MetalLB pool)    │
└─────────────────────────────────────────────────────┘
```

## Talos Configuration Notes

When configuring Talos, you'll need to specify:

### Network Interface Assignment
```yaml
machine:
  network:
    interfaces:
      - interface: eth2  # br30 - Kubernetes nodes network
        addresses:
          - 10.30.0.30/16
        routes:
          - network: 0.0.0.0/0
            gateway: 10.30.0.1  # Your router/gateway
      - interface: eth3  # br40 - LoadBalancer services
        addresses:
          - 10.40.0.30/16  # Optional, if Talos needs an IP here
```

### MetalLB Configuration (for LoadBalancer services)
```yaml
# In your Kubernetes manifests after Talos is running
apiVersion: v1
kind: ConfigMap
metadata:
  name: config
  namespace: metallb-system
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 10.40.0.100-10.40.0.200  # IP pool for LoadBalancer services
```

## Physical Network Requirements

Your physical network switch must be configured to:

1. **Untagged/native VLAN** on the port connected to your NixOS host's `eth0`:
   - Allow untagged traffic for PXE boot (br10)
   
2. **VLAN Trunking** on the same port:
   - VLAN 20 (Management)
   - VLAN 30 (Kubernetes nodes)
   - VLAN 40 (LoadBalancer services)

### Example Switch Configuration
```
interface GigabitEthernet0/1
  description "NixOS Hypervisor"
  switchport mode trunk
  switchport trunk native vlan 1    # or your PXE VLAN
  switchport trunk allowed vlan 20,30,40
```

## IP Address Planning

| Network | VLAN | Subnet | Gateway | Reserved IPs | Purpose |
|---------|------|--------|---------|--------------|---------|
| PXE Boot | untagged | DHCP | - | - | Matchbox PXE server |
| Management | 20 | 10.20.0.0/16 | 10.20.0.1 | 10.20.0.30 (NixOS host) | Hypervisor mgmt |
| K8s Nodes | 30 | 10.30.0.0/16 | 10.30.0.1 | 10.30.0.30 (talos-1) | Kubernetes cluster |
| LB Services | 40 | 10.40.0.0/16 | 10.40.0.1 | 10.40.0.100-200 (MetalLB) | Kubernetes services |

## Troubleshooting

### Check NixOS Host Connectivity
```bash
# Verify br20 has correct IP
ip addr show br20

# Ping gateway on management network
ping 10.20.0.1

# Check bridge status
ip link show type bridge
```

### Check VM Network from Host
```bash
# List VM interfaces
virsh domiflist talos-1

# Check bridge-interface mappings
brctl show  # or bridge link show
```

### From Talos VM
```bash
# Connect to Talos console
virsh console talos-1

# Check interfaces (in Talos)
talosctl -n 10.30.0.30 get links
```

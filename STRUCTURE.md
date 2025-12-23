# NixLab Project Structure

## Proposed Directory Layout

```
nixlab/
├── flake.nix                    # Main flake with all hypervisors and deploy-rs config
├── flake.lock                   # Flake lock file (auto-generated)
│
├── hosts/                       # Host-specific configurations
│   ├── hyp01/                   # Hypervisor 1
│   │   ├── configuration.nix    # Main NixOS configuration for hyp01
│   │   ├── hardware-configuration.nix  # Hardware-specific config (from nixos-generate-config)
│   │   ├── networking.nix       # Network bridges/VLANs for this host
│   │   └── vms/                 # VM definitions for this hypervisor
│   │       ├── talos-1.nix      # NixOS module for talos-1 VM
│   │       └── talos-1.xml      # Libvirt XML definition
│   │
│   └── hyp02/                   # Hypervisor 2 (future - copy from hyp01)
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       ├── networking.nix
│       └── vms/
│
├── modules/                     # Shared/reusable NixOS modules
│   ├── common.nix               # Common settings for all hypervisors
│   └── libvirt.nix              # Shared libvirt/virtualization config
│
└── docs/                        # Documentation
    ├── DEPLOYMENT.md            # Deployment instructions
    ├── NETWORK_ARCHITECTURE.md  # Network design documentation
    └── README.md                # Quick start guide
```

## Key Benefits

1. **Isolation**: Each hypervisor has its own directory
2. **Scalability**: Easy to add hyp02, hyp03 by copying hyp01 structure
3. **Clarity**: Clear separation between host configs and VM configs
4. **Reusability**: Common modules can be shared across all hosts
5. **Learning-friendly**: Easy to navigate and understand

## Usage Pattern

### Adding a new hypervisor (hyp02):
```bash
cp -r hosts/hyp01 hosts/hyp02
# Edit hosts/hyp02/configuration.nix to update hostname and IPs
# Add hyp02 to flake.nix nixosConfigurations and deploy.nodes
```

### Deploying:
```bash
# Deploy to hyp01
nix run github:serokell/deploy-rs -- .#hyp01

# Deploy to specific host with override
nix run github:serokell/deploy-rs -- .#hyp01 --hostname 192.168.1.100
```

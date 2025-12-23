# NixLab - Talos Kubernetes Lab

Laboratory project for building a Kubernetes environment using Talos Linux on NixOS hypervisors.

## 🏗️ Project Structure

```
nixlab/
├── flake.nix              # Main Nix Flakes + deploy-rs configuration
├── hosts/                 # Individual hypervisor configurations
│   └── hyp01/            # First hypervisor
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       ├── networking.nix
│       └── vms/          # VM definitions for this host
├── modules/              # Shared modules
│   ├── common.nix       # Common configuration
│   └── libvirt.nix      # Virtualization configuration
└── docs/                # Documentation
```

## 🚀 Quick Start

### Requirements

- Nix with Flakes enabled
- Server with any Linux (Debian, Ubuntu, etc.)
- SSH access as root

### Installation with nixos-anywhere (Recommended)

**Fastest method - full automation!**

```bash
# 1. Check disks on the target server
ssh root@YOUR_SERVER_IP "lsblk"

# 2. Adjust disk configuration
vim hosts/hyp01/disko.nix  # Set correct devices (e.g., /dev/sda)

# 3. Verify configuration
nix flake check

# 4. Install NixOS remotely
nix run github:nix-community/nixos-anywhere -- \
  --flake .#hyp01 \
  root@YOUR_SERVER_IP
```

**That's it!** In 10-15 minutes, you have a fully configured hypervisor.

See details: [NIXOS_ANYWHERE.md](docs/NIXOS_ANYWHERE.md)

### Alternative Installation (Traditional)

If you prefer the traditional method with an ISO:

1. **Generate hardware configuration on the target server:**
   ```bash
   ssh root@YOUR_SERVER_IP "nixos-generate-config --show-hardware-config" > hosts/hyp01/hardware-configuration.nix
   ```

2. **Adjust network configuration:**
   - Edit `hosts/hyp01/networking.nix` 
   - Set the correct physical interface name (default is `eth0`)

3. **First deployment (with hostname override):**
   ```bash
   nix run github:serokell/deploy-rs -- .#hyp01 --hostname YOUR_CURRENT_IP
   ```

4. **Subsequent deployments (using management IP):**
   ```bash
   nix run github:serokell/deploy-rs -- .#hyp01
   ```

## 📖 Documentation

- [DEPLOYMENT.md](docs/DEPLOYMENT.md) - Detailed deployment instructions
- [NETWORK_ARCHITECTURE.md](docs/NETWORK_ARCHITECTURE.md) - Network architecture
- [STRUCTURE.md](STRUCTURE.md) - Project structure details
- [NIXOS_BASICS.md](docs/NIXOS_BASICS.md) - NixOS concepts for beginners

## 🔧 Adding More Hypervisors

```bash
# Copy hyp01 directory as a template
cp -r hosts/hyp01 hosts/hyp02

# Edit configuration
vim hosts/hyp02/configuration.nix  # change hostname to hyp02
vim hosts/hyp02/networking.nix     # adjust IP addresses

# Add to flake.nix in nixosConfigurations and deploy.nodes sections
```

## 🌐 Network Architecture

- **br10** - PXE boot (untagged)
- **br20** - Management (VLAN 20, 10.20.0.0/16)
- **br30** - Kubernetes nodes (VLAN 30, 10.30.0.0/16)
- **br40** - LoadBalancer services (VLAN 40, 10.40.0.0/16)

## ⚡ Useful Commands

```bash
# Check configuration before deployment
nix flake check

# Build configuration locally (without deploying)
nix build .#nixosConfigurations.hyp01.config.system.build.toplevel

# Deploy with automatic rollback
nix run github:serokell/deploy-rs -- .#hyp01 --auto-rollback true

# Check VM status on the hypervisor
ssh root@10.20.0.30 "virsh list --all"
```

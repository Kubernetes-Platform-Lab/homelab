# Morph Deployment Configuration

This directory contains NixOS configurations designed to be deployed via [Morph](https://github.com/DBCDK/morph) to remote hypervisor hosts.

## About This Setup

**Architecture**: Headless hypervisor with libvirt VMs for Talos Kubernetes cluster

**Deployment Tool**: Morph (NixOS deployment tool)
- Alternative options: colmena, deploy-rs, NixOps

**Purpose**: Production-like lab environment for learning Kubernetes, Talos, and infrastructure as code

---

## Morph Setup

### 1. Install Morph

On your **local machine** (not the remote host):

```bash
# Option 1: Using nix-shell
nix-shell -p morph

# Option 2: Add to your local NixOS configuration
environment.systemPackages = [ pkgs.morph ];

# Option 3: Using nix run (flakes)
nix run nixpkgs#morph -- --help
```

### 2. Create Morph Network Configuration

Create `network.nix` in this directory:

```nix
{
  network = {
    description = "Talos Kubernetes Lab";
    # Optional: set network-wide settings
  };

  # Define your hypervisor host
  hypervisor = { config, pkgs, ... }: {
    # Import your existing configurations
    imports = [
      ./networking.nix
      ./vm-talos-1.nix
      # Add your hardware-configuration.nix path here
      # /etc/nixos/hardware-configuration.nix
    ];

    # Deployment configuration
    deployment = {
      targetHost = "10.20.0.30";  # Will connect via management network after first deployment
      # For initial deployment, use existing IP or hostname:
      # targetHost = "your-current-host-ip-or-hostname";
      
      targetUser = "root";  # or your SSH user with sudo
      
      # Optional: specify SSH key
      # keys.ssh.privateKey = "/home/yourusername/.ssh/id_ed25519";
    };

    # Basic system configuration
    system.stateVersion = "24.05";  # Adjust to your NixOS version
    
    # Enable SSH for remote management
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";  # or "yes" for initial setup
        PasswordAuthentication = false;
      };
    };

    # Optional: Install helpful tools on the hypervisor
    environment.systemPackages = with pkgs; [
      vim
      htop
      tmux
      curl
      wget
    ];
  };
}
```

### 3. Deploy to Remote Host

```bash
# Build the configuration (test without deploying)
morph build network.nix

# Deploy to the host
morph deploy network.nix

# Deploy with specific switches (see morph --help)
morph deploy network.nix --keep-result

# Push secrets (if you use morph secrets)
morph push network.nix
```

### 4. Manage VMs After Deployment

SSH to your hypervisor and manage VMs:

```bash
# SSH to hypervisor
ssh root@10.20.0.30

# List VMs
virsh list --all

# Start Talos VM
virsh start talos-1

# Console access
virsh console talos-1

# Check VM status
virsh dominfo talos-1
```

---

## Alternative Deployment Tools

### colmena (Recommended alternative)

**Why colmena?**
- More actively maintained than Morph
- Better parallelization for multiple hosts
- Nice CLI with colored output
- Built-in secrets management

**Install:**
```bash
nix-shell -p colmena
```

**Create `hive.nix`:**
```nix
{
  meta = {
    nixpkgs = import <nixpkgs> {};
    specialArgs = {};
  };

  hypervisor = { config, pkgs, ... }: {
    deployment = {
      targetHost = "10.20.0.30";
      targetUser = "root";
    };

    imports = [
      ./networking.nix
      ./vm-talos-1.nix
    ];

    # ... rest of your config
  };
}
```

**Deploy:**
```bash
colmena apply
colmena apply-local --sudo  # For local deployment
```

### deploy-rs (Rust-based, fast)

**Why deploy-rs?**
- Very fast
- Written in Rust
- Good for flake-based configs
- Rollback support

**Requires NixOS flakes**

---

## Project Structure

```
/home/valdi/Poligon/to-del/
├── network.nix              # Morph deployment config (create this)
├── networking.nix           # Network bridges and VLANs
├── vm-talos-1.nix          # Libvirt VM configuration
├── talos-1.xml             # Libvirt domain XML
├── NETWORK_ARCHITECTURE.md # Network documentation
└── DEPLOYMENT.md           # This file
```

---

## Initial Deployment Workflow

### Step 1: Prepare Remote Host

Ensure your remote NixOS host:
1. Has SSH access configured
2. Has a reachable IP address
3. Has enough disk space for VMs
4. Has `/dev/vda` or the block device you specified

### Step 2: First Deployment

```bash
# Create network.nix with current IP address
# Set deployment.targetHost to current host IP

# Deploy
morph deploy network.nix

# After deployment, the host will have:
# - br20 with IP 10.20.0.30 (management network)
# - libvirt running
# - talos-1 VM defined and started
```

### Step 3: Verify Deployment

```bash
# SSH to the new management IP
ssh root@10.20.0.30

# Check network
ip addr show br20

# Check libvirt
systemctl status libvirtd

# Check VM
virsh list --all
```

### Step 4: Update Morph Config

After successful deployment, update `network.nix`:
- Change `deployment.targetHost` to `10.20.0.30`
- Future deployments will use the management network

---

## Remote VM Management

### Via SSH + virsh

```bash
# SSH to hypervisor
ssh root@10.20.0.30

# VM operations
virsh start talos-1
virsh shutdown talos-1
virsh destroy talos-1  # force stop
virsh console talos-1  # serial console (Ctrl+] to exit)

# VM info
virsh dominfo talos-1
virsh domiflist talos-1  # network interfaces
virsh domblklist talos-1  # disk info
```

### Via SSH One-liners

```bash
# Start VM remotely
ssh root@10.20.0.30 'virsh start talos-1'

# Get VM status
ssh root@10.20.0.30 'virsh list --all'

# Attach to console over SSH
ssh -t root@10.20.0.30 'virsh console talos-1'
```

---

## Updating Configuration

When you make changes to `networking.nix`, `vm-talos-1.nix`, etc.:

```bash
# Deploy changes
morph deploy network.nix

# Or with colmena
colmena apply
```

Morph/colmena will:
1. Build the new configuration
2. Copy it to the remote host
3. Switch to the new configuration
4. Restart affected services

---

## Production Best Practices Implemented

✅ **Infrastructure as Code**: All configs in Git  
✅ **Remote Deployment**: Via Morph/colmena  
✅ **Headless Hypervisor**: No GUI, minimal packages  
✅ **Network Segmentation**: VLANs for different purposes  
✅ **Management Network**: Dedicated br20 for hypervisor access  
✅ **Libvirt**: Industry-standard VM management  
✅ **Talos Linux**: Immutable Kubernetes OS  

### Additional Recommendations

1. **Version Control**: Store all configs in Git
   ```bash
   git init
   git add networking.nix vm-talos-1.nix network.nix talos-1.xml
   git commit -m "Initial hypervisor configuration"
   ```

2. **Backup Strategy**: 
   - VMs: Regular snapshots via `virsh snapshot-create-as`
   - Configs: Git repository
   - Data: External backup solution

3. **Monitoring** (optional for later):
   - Prometheus + Grafana
   - Node exporter on hypervisor
   - Libvirt exporter for VM metrics

4. **Secrets Management**:
   - sops-nix for encrypted secrets in Git
   - agenix (age-based encryption)
   - Morph built-in secrets (simpler)

5. **CI/CD** (advanced):
   - GitHub Actions / GitLab CI
   - Automatically deploy on push to main branch
   - Run NixOS VM tests before deployment

---

## Troubleshooting Morph Deployments

### SSH Connection Issues

```bash
# Test SSH connection manually
ssh root@10.20.0.30

# Check SSH config
morph deploy network.nix --show-trace

# Use different SSH key
morph deploy network.nix --ssh-private-key ~/.ssh/id_ed25519
```

### Build Failures

```bash
# Build locally first
morph build network.nix --show-trace

# Check for NixOS syntax errors
nix-instantiate network.nix
```

### Rollback

```bash
# On the remote host
ssh root@10.20.0.30

# List generations
nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
/nix/var/nix/profiles/system-<N>-link/bin/switch-to-configuration switch
```

---

## Next Steps

1. **Create `network.nix`** with your host details
2. **Deploy** using Morph: `morph deploy network.nix`
3. **Verify** VM is running: `ssh root@10.20.0.30 'virsh list'`
4. **Install Talos** via PXE boot from matchbox
5. **Configure Kubernetes** on Talos cluster
6. **(Optional) Add HAProxy VM** for load balancing

---

## Learning Resources

- **Morph**: https://github.com/DBCDK/morph
- **colmena**: https://github.com/zhaofengli/colmena
- **Talos Linux**: https://www.talos.dev/
- **libvirt**: https://libvirt.org/
- **NixOS Manual**: https://nixos.org/manual/nixos/stable/

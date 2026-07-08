# NixOS Hypervisors

4 bare-metal NixOS hypervisors running Talos Linux VMs for the Kubernetes cluster. Fully declarative -- hosts, disks, networking, VMs, and secrets are all defined in Nix and deployed remotely via deploy-rs.

## Hosts

| Host | Management IP | Physical NIC | VM RAM | VM vCPUs | VM Role |
|------|---------------|-------------|--------|----------|---------|
| hyp01 | 10.20.0.30 | enp9s0f0 | 14 GiB | 4 | Control Plane (cp-node01) |
| hyp02 | 10.20.0.31 | enp8s0f0 | 14 GiB | 4 | Control Plane (cp-node02) |
| hyp03 | 10.20.0.32 | enp2s0 | 6 GiB | 2 | Control Plane (cp-node03) |
| hyp04 | 10.20.0.33 | enp2s0 | 12 GiB | 4 | Worker (w-node04) |

## Architecture

```
Physical NIC (e.g. enp9s0f0)
  └─> OVS Bridge (br-int)
       ├── mgmt20 (VLAN 20, 10.20.0.x/16) ─── hypervisor management, SSH, Cockpit
       ├── pxe-net (untagged)               ─── PXE provisioning (currently unused)
       └── Talos VM (talos-1)
            ├── NIC 1 (VLAN 30) ─── Kubernetes cluster traffic
            └── NIC 2 (VLAN 40) ─── Services + BGP
```

Each hypervisor runs one Talos Linux VM with:
- 20G qcow2 system disk (auto-created on first boot)
- `/dev/sda` passed through as raw block device (for OpenEBS LVM local storage)
- Talos metal ISO mounted as CD-ROM for initial boot
- Two OVS-bridged NICs: VLAN 30 (cluster) + VLAN 40 (services/BGP)
- QEMU guest agent for host-VM communication

## Directory Structure

```
01-virtualization/
├── flake.nix                   # 4 NixOS configs + deploy-rs targets
├── justfile                    # Deployment shortcuts (just hyp01, just hyp02, ...)
├── modules/
│   ├── common.nix              # SSH, users, packages, firewall, nix settings, SOPS
│   └── libvirt.nix             # KVM/QEMU/libvirt, trusted bridge interfaces
├── secrets/
│   ├── secrets.yaml            # SOPS-encrypted: root password
│   └── cockpit-secrets.yaml    # SOPS-encrypted: Cockpit TLS cert + key
├── .sops.yaml                  # Age key recipients (2 operators + 4 hosts)
└── hosts/
    └── hyp01/                  # (hyp02-04 have the same structure)
        ├── configuration.nix   # Imports all host modules
        ├── hardware-configuration.nix
        ├── networking.nix      # OVS bridge, VLANs, systemd-networkd
        ├── disko.nix           # Disk partitioning (GPT, EFI + XFS root)
        ├── hosts.nix           # /etc/hosts entries
        ├── cockpit.nix         # Web management UI (port 9090, TLS)
        └── vms/
            ├── talos-1.nix     # Systemd service: create qcow2, define/start VM
            └── talos-1.xml     # Libvirt XML: CPU, RAM, disks, NICs
```

## How Hosts Differ

All hosts share the same modules (`common.nix`, `libvirt.nix`). Per-host differences are only:
- Hostname and management IP
- Physical NIC name (hardware-dependent)
- NVMe disk ID (for disko)
- VM resources (RAM, vCPUs) and MAC addresses
- Cockpit allowed origins

## Common Operations

### Prerequisites

Enter the dev environment (provides `just`, `sops`, `kubectl`, `k9s`, `nixfmt`):

```bash
devbox shell
# or with direnv:
cd 01-virtualization/  # auto-activates via .envrc
```

Make sure your age key is at `~/.config/sops/age/keys.txt`.

### Deploy changes to a host

After modifying any Nix file:

```bash
just hyp01    # deploys to hyp01 (10.20.0.30)
just hyp02    # deploys to hyp02 (10.20.0.31)
just hyp03    # deploys to hyp03 (10.20.0.32)
just hyp04    # deploys to hyp04 (10.20.0.33)
```

This runs `deploy-rs` which:
1. Builds the NixOS closure locally
2. Copies it to the host via SSH (as `admin` user)
3. Activates the new configuration
4. Automatically rolls back if the host becomes unreachable within 30 seconds

### Initial bare-metal installation

For a new machine that was PXE-booted and is reachable:

```bash
sudo nix run github:nix-community/nixos-anywhere -- --flake .#hyp01 root@<IP>
```

This partitions disks (via disko), installs NixOS, and reboots.

### Edit encrypted secrets

```bash
# Edit root password and other secrets
sops secrets/secrets.yaml

# Edit Cockpit TLS certificate
sops secrets/cockpit-secrets.yaml
```

SOPS opens the file decrypted in your editor and re-encrypts on save. Never decrypt to a file on persistent disk.

### VM management

VMs are defined declaratively in Nix and auto-started on boot. For manual operations:

```bash
# SSH to the hypervisor
ssh admin@10.20.0.30

# VM status
virsh list --all

# Console access (escape with Ctrl+])
virsh console talos-1

# Restart a VM
virsh destroy talos-1 && virsh start talos-1
```

The VM definition is managed by a systemd service (`define-talos-1-vm`). If you change the XML or Nix wrapper, run `just hyp01` to redeploy -- the service will destroy, undefine, and recreate the VM.

## Adding a New Hypervisor

1. **Create host directory:**

```bash
cp -r hosts/hyp01 hosts/hyp05
```

2. **Edit host-specific files:**
   - `configuration.nix` -- change hostname
   - `networking.nix` -- change physical NIC name, management IP
   - `disko.nix` -- change NVMe disk ID (find with `lsblk -o NAME,MODEL,SERIAL`)
   - `cockpit.nix` -- change allowed origins hostname
   - `hosts.nix` -- change hostname
   - `vms/talos-1.xml` -- change RAM, vCPUs, MAC addresses (must be unique)
   - `hardware-configuration.nix` -- generate on the target machine with `nixos-generate-config`

3. **Add to `flake.nix`:**

```nix
# In nixosConfigurations:
hyp05 = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    disko.nixosModules.disko
    sops-nix.nixosModules.sops
    ./hosts/hyp05/configuration.nix
    ./hosts/hyp05/disko.nix
  ];
};

# In deploy.nodes:
hyp05 = {
  hostname = "10.20.0.34";  # new management IP
  profiles.system = {
    user = "root";
    path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.hyp05;
    sshOpts = [ "-o" "StrictHostKeyChecking=accept-new" ];
    autoRollback = true;
    magicRollback = true;
    confirmTimeout = 30;
  };
};
```

4. **Add host's age key to `.sops.yaml`:**

```bash
# Get the host's age public key from its SSH key
ssh-keyscan 10.20.0.34 2>/dev/null | ssh-to-age

# Add to .sops.yaml under keys, then re-encrypt:
sops updatekeys secrets/secrets.yaml
sops updatekeys secrets/cockpit-secrets.yaml
```

5. **Add justfile target:**

```
hyp05:
    nix run github:serokell/deploy-rs -- .#hyp05 --ssh-user admin
```

6. **Install and deploy:**

```bash
# Initial install via PXE or nixos-anywhere
sudo nix run github:nix-community/nixos-anywhere -- --flake .#hyp05 root@<PXE_IP>

# Subsequent changes
just hyp05
```

## Secrets Management

Secrets are encrypted with SOPS + age. Six key holders can decrypt:
- 2 operator keys (Waldemar + Beraton)
- 4 host keys (derived from each host's SSH ed25519 key at `/etc/ssh/ssh_host_ed25519_key`)

Hosts decrypt their own secrets at boot using their SSH key. Operators decrypt for editing using their personal age key.

## Shared Configuration

### `modules/common.nix`
- SSH server (root login by key only)
- Users: `root` (SOPS password), `admin` (wheel, libvirtd, passwordless sudo, SSH keys for both operators)
- Packages: vim, htop, tmux, curl, wget, git, rsync
- Firewall: enabled, TCP 22 open
- Nix: flakes enabled, weekly garbage collection (30d retention)
- Kernel: `net.core.wmem_max` and `rmem_max` set to 16MB (BGP stability)

### `modules/libvirt.nix`
- libvirtd with QEMU/KVM, swtpm (TPM emulation)
- Firewall trusts bridge interfaces (`br-int`, `pxe-net`, `mgmt20`)
- Default virsh connection: `qemu:///system`

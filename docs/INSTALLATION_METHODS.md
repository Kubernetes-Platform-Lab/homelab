# NixOS Installation - Methods and Recommendations

## 🎯 Target Case: Remote Headless Hypervisor

For a remote server without easy physical access, choosing the right installation method is critical.

## 📋 Available Methods

---

### 1. **nixos-anywhere** ⭐ RECOMMENDED

**The best method for remote installation!**

#### How it works:
```mermaid
graph LR
    A[Your Computer] -->|SSH| B[Server with any Linux]
    B -->|kexec| C[NixOS Installer in RAM]
    C -->|partition| D[Disks]
    D -->|install| E[NixOS from your config]
    
    style A fill:#d4e6f1
    style E fill:#d4f1d4
```

#### Advantages:
- ✅ **Fully automatic** - zero interaction required.
- ✅ **Remote** - no physical access or KVM needed.
- ✅ **Declarative partitioning** - utilizes `disko` for disk management.
- ✅ **Flake integration** - uses your `flake.nix` directly.
- ✅ **One step** - from any Linux to NixOS in minutes.

#### Requirements:
- Server with any Linux (e.g., Debian, Ubuntu).
- Root SSH access.

#### Usage:
```bash
nix run github:nix-community/nixos-anywhere -- --flake .#hyp01 root@YOUR_SERVER_IP
```

---

### 2. **Hybrid Method (ISO + nixos-anywhere)** ⭐ STABLE

**Best if you have physical or IPMI/KVM access and want maximum reliability.**

#### How it works:
1. Boot the server from a **NixOS Minimal ISO**.
2. Set a temporary root password: `sudo passwd`.
3. Check the IP address: `ip addr`.
4. Run `nixos-anywhere` from your local machine targeting that IP.

#### Advantages:
- ✅ **Visible progress** - You see exactly what's happening on the monitor.
- ✅ **Clean environment** - No risk of old Linux processes interfering with disks.
- ✅ **Automated disks** - Disko still handles all the complex partitioning for you.

---

### 3. **Traditional ISO Installation + deploy-rs**

#### How it works:
1. **Boot from NixOS ISO**.
2. **Manual partitioning**: Run `parted`, `mkfs`, and `mount` commands manually.
3. **Minimal install**: Run `nixos-generate-config` and `nixos-install`.
4. **Deploy**: Once rebooted, use `deploy-rs` for the final configuration.

#### Advantages:
- ✅ **Total manual control** - if you have very specific needs.
- ❌ **Slow and error-prone** - manual typing of device paths is risky.

---

## 📊 Comparison Table

| Method | Automation | Remote | Speed | Risk |
|---|---|---|---|---|
| **nixos-anywhere** | ⭐⭐⭐⭐⭐ | Yes | 10-15 min | Low |
| **Hybrid (ISO)** | ⭐⭐⭐⭐ | Yes (KVM) | 15-20 min | Very Low |
| **ISO + deploy-rs** | ⭐⭐ | No | 30-45 min | Medium |

## 🏆 Recommendation for nixlab

For your **hyp01** setup, I strongly recommend the **Hybrid Method** or **nixos-anywhere**. 

Since you asked about booting with ISO and configuring SSH:
1. **Boot NixOS Minimal ISO**.
2. Run `sudo passwd` to enable SSH access via password.
3. run **nixos-anywhere** from your workstation.

This takes away the "scary" part of manual partitioning while keeping the process very safe and visible.

## 🚀 Quick Start (Hybrid)

1. **Verify your disk names** in [hosts/hyp01/disko.nix](file:///home/valdi/Poligon/nixlab/hosts/hyp01/disko.nix).
2. **On the server (ISO):**
   ```bash
   sudo passwd
   ip addr
   ```
3. **On your computer:**
   ```bash
   nix run github:nix-community/nixos-anywhere -- --flake .#hyp01 root@SERVER_IP
   ```

---
*For details on disk configuration, see [DISKO_GUIDE.md](DISKO_GUIDE.md).*

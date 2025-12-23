# NixOS Basics - System Architecture

## 🎯 Main Concept

NixOS is a **declarative** operating system where the entire system configuration is built as **immutable packages** in `/nix/store`.

## 📦 `/nix/store` Structure

```
/nix/store/
├── bv3sqiv8pzbya...-nixos-system-hyp01-24.05.20241230.b134951/  ← Entire system
├── q6nka7blklbkq...-vim-9.1.0765/                               ← vim
├── 17ni0jyqg114j...-htop-3.3.0/                                 ← htop
├── lpkn9w3h16wb9...-git-2.44.2/                                 ← git
└── rhq3rwyghbqq4...-systemd-255.9/                              ← systemd
```

Every package:
- Has a **unique hash** based on its content
- Is **immutable** - it never changes
- Has **all dependencies** built-in

## 🔗 What is `result`?

When you build the system:
```bash
nix build .#nixosConfigurations.hyp01.config.system.build.toplevel
```

You get a symlink `result`:
```
result -> /nix/store/bv3sqiv8pzbya...-nixos-system-hyp01-24.05.20241230.b134951
```

**This is your complete, built system!**

## 📂 `result/` Structure (Future Root `/`)

```
result/
├── bin/                    # System binaries
├── etc -> /nix/store/...   # Configurations (/etc)
├── systemd -> /nix/store/...  # systemd for this system
├── sw -> /nix/store/...    # System-wide packages (environment.systemPackages)
├── activate                # System activation script
├── init                    # Init script
└── kernel -> /nix/store/...   # Kernel
```

### Why is `systemd` in the root `/`?

The `result/` directory **represents the future root filesystem** after deployment.

After deployment on the server, NixOS:
1. Copies this system to `/nix/store/bv3sqiv8...`
2. Creates a symlink `/run/current-system` -> `/nix/store/bv3sqiv8...`
3. The system uses `/run/current-system/systemd`, `/run/current-system/sw`, etc.

## 🔍 What is `/sw`?

`sw` = **System-Wide** - all packages from your configuration:

```nix
# From modules/common.nix
environment.systemPackages = with pkgs; [
  vim    # -> result/sw/bin/vim
  htop   # -> result/sw/bin/htop
  git    # -> result/sw/bin/git
  # ...
];
```

Let's check:
```bash
$ ls -l result/sw/bin/vim
lrwxrwxrwx result/sw/bin/vim -> /nix/store/q6nka7blkl...-vim-9.1.0765/bin/vim

$ ls -l result/sw/bin/git  
lrwxrwxrwx result/sw/bin/git -> /nix/store/lpkn9w3h16...-git-2.44.2/bin/git
```

Everything is a symlink to `/nix/store`!

## 🚀 How it works in action?

### Current System (on a running NixOS)

```bash
/run/current-system/ -> /nix/store/ABC123...-nixos-system-hyp01-v1

$ which vim
/run/current-system/sw/bin/vim -> /nix/store/...-vim-9.1.0/bin/vim
```

### After Deploying a New Version

```bash
# deploy-rs deploys the new version
/run/current-system/ -> /nix/store/XYZ789...-nixos-system-hyp01-v2

# The OLD version still exists in /nix/store/ABC123...!
# You can go back to it (rollback)!
```

## 🔄 System Generations

NixOS keeps **all previous versions** of the system:

```bash
# List generations
$ nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to the previous generation
$ nixos-rebuild switch --rollback
```

## 🌟 Key Advantages

1. **Atomic updates**: The system switches between versions atomically
2. **Rollback**: You can always return to a previous version
3. **Reproducibility**: Same `flake.lock` = same system
4. **Isolation**: Different versions of packages can coexist

## 📖 Example Flow

```mermaid
graph TD
    A[flake.nix + configuration] -->|nix build| B[/nix/store/ABC...-nixos-system]
    B -->|symlink| C[result/]
    C -->|deploy-rs| D[Server: /nix/store/ABC...]
    D -->|activate| E[/run/current-system -> ABC...]
    E --> F[System works with new version]
    
    style B fill:#d4f1d4
    style E fill:#d4f1d4
```

## 💡 Practical Commands

```bash
# See the current system
ls -la /run/current-system

# See all packages in PATH
ls /run/current-system/sw/bin/

# Check system hash
readlink /run/current-system

# See what will change before deployment
nix build .#nixosConfigurations.hyp01.config.system.build.toplevel
readlink result  # Compare with /run/current-system
```

## 🎓 Summary

| What | Where | Purpose |
|---|---|---|
| `/nix/store` | Immutable packages | All packages and systems |
| `result/` | Local symlink | Built system (before deployment) |
| `/run/current-system` | Symlink on server | Currently running system |
| `result/sw/` | System packages | Everything from `environment.systemPackages` |
| `result/systemd` | systemd | systemd for this system version |

**Key principle**: Everything in NixOS is symlinks to `/nix/store`. Thanks to this:
- You can have multiple system versions simultaneously
- Rollback is instantaneous (symlink change)
- The system is fully reproducible

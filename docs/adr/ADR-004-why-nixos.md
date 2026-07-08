# ADR-004: Why NixOS for Hypervisors

**Date:** 2025-07-09
**Status:** accepted
**Authors:** Waldemar Kubica

## Context

We needed an OS for 4 bare-metal hypervisors running KVM/libvirt VMs with Open vSwitch networking. Key requirements:
- Declarative, reproducible configuration
- Atomic upgrades with rollback
- Declarative VM definitions (disks, networks, resources)
- Network management via SOPS+age

## Decision

Use NixOS with Nix flakes, deployed via deploy-rs.

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|-------------|
| **Ubuntu Server** | Imperative package management, SSH-driven maintenance. Configuration drift over time. No atomic rollbacks. |
| **Debian** | Same as Ubuntu — no declarative system management. |
| **Proxmox VE** | Opinionated virtualization platform, not a general-purpose OS. Hard to manage declaratively. |
| **Fedora Server** | Good for cutting-edge but not as reproducible as NixOS. |

## Consequences

- Entire hypervisor config (hosts, disks, networking, VMs, secrets) in version-controlled Nix files
- `deploy-rs` with automatic rollback on failure (30-second timeout)
- `disko` partitions disks declaratively — from bare metal to running NixOS in one command
- VMs defined as systemd services — auto-started, auto-recreated on config change
- Declarative OVS bridge configuration with VLANs
- Nix learning curve — operators must learn Nix expression language
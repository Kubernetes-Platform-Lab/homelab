# GitOps Workflow for NixOS

Implementing GitOps in NixOS allows for automated builds, testing, and deployments triggered by git commits. This guide outlines the professional "Build → Cache → Deploy" architecture.

## 🏗️ The Architecture

1.  **Git Repository**: The single source of truth (your `nixlab` repo).
2.  **Hydra (CI)**: The Continuous Integration server that builds your Flake.
3.  **Binary Cache (Attic/Cachix)**: Stores pre-built binaries to speed up deployment.
4.  **Deployment Engine (deploy-rs)**: Transfers and activates the new system.

```mermaid
graph TD
    User[Developer] -->|Push| Git[Git Repository]
    Git -->|Webhook| Hydra[Hydra CI]
    Hydra -->|Builds| Store[/nix/store]
    Store -->|Upload| Cache[Private Binary Cache<br/>Attic / Harmonia]
    Hydra -->|On Success| Deploy[CI Runner / deploy-rs]
    Deploy -->|Activate| Server[Production Hypervisor]
    Server -->|Fetch Binaries| Cache
```

## 🛠️ Key Components

### 1. Hydra (The Builder)
Hydra is the official Nix CI. It is designed to work natively with Nix expressions.
- **Jobsets**: You define which flake outputs Hydra should build.
- **Evaluation**: Hydra evaluates your `flake.nix` and triggers builds for every architecture (e.g., `x86_64-linux`).
- **Private Setup**: Typically run in a dedicated VM with significant CPU and Disk space.

### 2. Private Binary Cache (Attic)
Storing binaries is crucial. Without a cache, every server would have to compile its own updates.
- **[Attic](https://github.com/zhaofengli/attic)**: A modern, self-hosted binary cache for Nix.
- **Efficiency**: Only builds that are missing from the cache are compiled.
- **Security**: Can be protected by authentication and signing keys.

### 3. deploy-rs (The Deployer)
While Hydra builds the system, `deploy-rs` handles the transition.
- **Atomic**: It ensures the new system is fully available before switching.
- **Rollback**: Automatically rolls back if the new configuration breaks network connectivity.

## 🚀 Setting Up the GitOps Pipeline

### Step 1: Configure the Binary Cache
In your `common.nix`, you must tell your hypervisors to trust your private cache:

```nix
nix.settings = {
  substituters = [
    "https://cache.nixos.org"
    "https://your-private-cache.example.com/main"
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "main:your-signing-key-goes-here"
  ];
};
```

### Step 2: Configure Hydra
Create a `hydra-config.nix` (or similar) that defines which systems to build. Hydra will look for these in your flake outputs.

### Step 3: CI/CD Integration
Use a runner (e.g., GitHub Actions, Gitea Actions) to bridge Hydra and Deployment:
1. Push to Git.
2. Wait for Hydra build to complete.
3. Run `nix run github:serokell/deploy-rs -- .#hyp01`.

## 🌟 Benefits
- **Speed**: Servers download binaries at 1Gbps+ instead of compiling for hours.
- **Reliability**: If the build fails in Hydra, it never touches your servers.
- **Traceability**: Every system state is tied to a specific git commit.
- **Consistency**: All hypervisors share the same pre-built binaries.

## 🎓 Summary
This method transforms your hypervisor management from "manual maintenance" to "infrastructure as code" with a professional delivery pipeline.

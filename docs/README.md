# Documentation

This directory contains all documentation for the homelab platform.

## Structure

```
docs/
├── README.md                # This file
├── adr/                     # Architecture Decision Records
│   ├── ADR-1-cicd-tooling.md
│   ├── ADR-2-local-storage.md
│   ├── ADR-3-object-storage.md
│   └── external-secrets.md
├── architecture/            # Detailed architecture documentation
│   ├── network-topology.md  # VLANs, BGP, OVS
│   ├── storage-architecture.md
│   └── gitops-flow.md
├── operations/             # Runbooks and operational procedures
│   ├── backup-restore.md
│   ├── node-recovery.md
│   └── cluster-upgrade.md
├── platform/               # Component-specific guides
│   ├── cilium.md
│   ├── fluxcd.md
│   └── argocd.md
└── guides/                 # How-to guides
    ├── adding-a-tool.md
    ├── adding-an-app.md
    └── deploying-changes.md
```

## For Contributors

Documentation follows these principles:
- **ADRs** capture why we made decisions
- **Architecture docs** describe how things fit together
- **Operations** documents how to fix things
- **Platform guides** explain how components are configured
- **How-to guides** show step-by-step procedures
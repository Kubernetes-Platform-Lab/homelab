# Documentation

This directory contains all documentation for the homelab platform.

## Structure

```
docs/
├── README.md                # This file
├── adr/                     # Architecture Decision Records
│   ├── ADR-001-why-talos-linux.md
│   ├── ADR-002-why-cilium-bgp.md
│   ├── ADR-003-why-dual-gitops.md
│   ├── ADR-004-why-nixos.md
│   ├── ADR-1-cicd-tooling.md
│   ├── ADR-2-local-storage.md
│   ├── ADR-3-object-storage.md
│   └── external-secrets.md
├── architecture/            # Detailed architecture documentation
│   ├── gitops-flow.md
│   └── network-topology.md  # VLANs, BGP, OVS
├── procedures/              # Manual step-by-step procedures and runbooks
│   ├── cnpg-manual-restore-from-backup.yaml
│   └── database-failover.md
└── samples/                 # Manually applied templates (not synced by ArgoCD)
    └── README.md
```

## For Contributors

Documentation follows these principles:
- **ADRs** capture why we made decisions
- **Architecture docs** describe how things fit together
- **Procedures** document manual, step-by-step operational tasks
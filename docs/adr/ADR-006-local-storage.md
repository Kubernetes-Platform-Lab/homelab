# ADR-006: Local Storage for Pods

**Date:** 2026-03-01
**Status:** accepted
**Authors:** Jakub Kubica

## Context

We needed to provide persistent block and filesystem storage in the cluster that allows pods to run on nodes. The main requirements for this type of storage were relatively high throughput and low latency. To remain highly available during hardware problems, the storage needs to be replicated synchronously so that pods can easily be moved to a different node without any issues. Synchronous replication comes at the cost of lower speed, which we accept.

## Decision

Deploy **OpenEBS** to create pod PVs on each node's local storage, backed by an LVM volume group per node. Democratic-CSI against the external ZFS server was used initially and later deprecated.

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|-------------|
| **OpenEBS** | Accepted. Supports both local and replicated storage for block and filesystem PVs, and is well documented. |
| **Democratic-CSI with external ZFS server** | ZFS over iSCSI can serve block PVs but cannot reliably create filesystem PVs. PV removal also left "zombie" volumes on the ZFS server. Deprecated after evaluation. |

## Consequences

- Pods get PVs from the local node's LVM volume group via OpenEBS
- Currently only local storage is deployed; replication is planned so deployments become highly available and can move between nodes effortlessly
- Our environments predominantly require filesystem PVs and S3 storage, which is why the ZFS-over-iSCSI approach was abandoned
- Local-only PVs mean a pod cannot be rescheduled to another node until the volume is recreated

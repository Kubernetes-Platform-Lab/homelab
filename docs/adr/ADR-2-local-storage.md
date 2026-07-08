---
adr: 2
date: 2026-03-01
title: Storage used for pods running in the cluster
status: Accepted
type: Backend, Storage
---

## Context and Problem Statement

We needed to provide persistent block and filesystem storage in the cluster that allow to run pods on nodes. The main requirements for this type of storage is to be relatively high throughput and low latency. In order to remain high availability during any hardware problems the storage needs to be replicated synchronously so that all pods can easily be moved to a different node without any issues. Synchronous replication comes at a cost of lower speed but we accept that fact.

## Considered Options

### OpenEBS

Allows to set up both local and replicated storage that can be used to server both block and filesystem PVs. Well documented solution.

### Democratic-CSI with external ZFS server

There is an external ZFS server set up in our lab. By deploying democratic-csi with a ZFS-capable backend targeting an external ZFS server. The Kubernetes environment is configured so that democratic-csi can create and manage PVs on the remote ZFS pool, with StorageClasses mapping to those remote resources.

- **Pros**:
  - Reuses existing ZFS server to manage PVs.
  - Centralized storage lifecycle management (snapshots, pool expansion).
  - Storage is isolated and independent from Kubernetes nodes — usable by multiple clusters.
- **Cons**:
  - ZFS over iSCSI can serve block PVs but cannot create filesystem PVs reliably.

## Decision Outcome

We deployed **OpenEBS** to create pod PVs on local node's storage. Each node has an LVM set up that is being used in OpenEBS deployment. Currently we have only local storage deployed but we plan to change that into a replicated storage so that our deployments are highly available and can be moved between nodes effortlessly.

We also deployed **democratic-csi** with a ZFS-backed target on an external server. However, this approach was later **deprecated** due to two issues: (1) ZFS over iSCSI could not reliably serve filesystem PVs, and (2) PV removal left "zombie" volumes on the ZFS server. Our environments predominantly require filesystem PVs and S3 storage, leading us to move away from democratic-csi.
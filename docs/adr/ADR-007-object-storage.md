# ADR-007: Object Storage for Large Unstructured Data

**Date:** 2026-03-01
**Status:** accepted
**Authors:** Jakub Kubica

## Context

We needed large-scale storage for massive loads of data, such as videos and photos, as well as application backup data. Besides the Kubernetes cluster there is an external ZFS server that we plan to use for this purpose. The storage does not need to be particularly fast but it needs to be easy to use and expand in the future. We plan to use S3 storage because of its ease of use and flexibility.

## Decision

Deploy **SeaweedFS** to provide S3 buckets, with one dedicated user and token per application.

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|-------------|
| **RustFS** | Project is currently in a very early phase and has poor documentation. |
| **SeaweedFS** | Accepted. Supports multiple masters, has an admin UI, and can create both volumes and S3 buckets. Provides snapshotting capabilities plus user and group management. |

## Consequences

- Applications consume S3 buckets served by SeaweedFS
- A separate user with its own token is created per application, so each application can only modify its own bucket
- The admin UI and multi-master setup make the store easy to operate and expand
- Backup data and large unstructured data share the same object store, so bucket-level isolation and quotas matter

| Field | Value |
|---|---|
| ADR Title | Use external ZFS server for democratic-csi |
| ADR Number | 0001 |
| Status | Deprecated |
| Decision Date | 2026-03-01 |
| Domain | Backend, Storage |
| Impact Level | High |
| Context | We wanted to provide persistent block/filesystem storage via democratic-csi. Our storage hardware is an external server that already hosts a ZFS pool. The goal is to expose that pool to k8s reliably using democratic-csi, while keeping k8s nodes stateless and avoiding using local k8s nodes storage. We wanted to serve all storage via iSCSI |
| Decision | Deploy democratic-csi with a ZFS-capable backend that targets an external ZFS server. The k8s environment will be configured so that democratic-csi can create/manage PV's on the remote ZFS pool, and k8s StorageClasses will map to those remote resources. |
| Alternatives | **1)** OpenEBS (considered: complex but allows to create both filesystem and block PVs), **2)** RustFS (rejected: low maturity and not really battle-tested), **3)** SeaweedFS (considered: good scalability but cannot serve block PVs) |
| Pros & Cons | **Pros:** Reuse of existing ZFS server to manage PVs; Centralized strorage lifecycle management (snapshots, expanding ZFS pool); Storage is completely isolated and independent from k8s nodes - this way it can be used by multiple clusters if we plan to add more in the future. **Cons:** Unfortunately during implementation it turned out that ZFS over iSCSI can be used to serve block PV's but it is not possible to create filesystem PV's reliably with such setup |
| Assumptions | We have noticed problems with PV removal as they were removed from k8s but still existed on ZFS server as "zombie" volumes; We have also noticed that we very rarely use block PV's in our environments and require more of filesystem PV's as well as S3 storage hence we moved away from democratic-csi |

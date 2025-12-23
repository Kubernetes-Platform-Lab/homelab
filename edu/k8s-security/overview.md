# Kubernetes Security Education Path

This directory contains a structured learning path for mastering Kubernetes security, from basic concepts to advanced hardening and offensive/defensive techniques.

## 🗺️ Learning Roadmap

### 1. Fundamentals & Isolation
*   **[K8S_SECURITY_LAB.md](../../docs/K8S_SECURITY_LAB.md)**: Introduction to common pod-level vulnerabilities (Privileged pods, hostPath, etc.).
*   **Container Security**: Deep dive into namespaces, cgroups, and capabilities.

### 2. Access Control & Secrets (The "Who & What")
*   **[RBAC_GUIDE.md](RBAC_GUIDE.md)**: Understanding Roles, ClusterRoles, and the principle of least privilege.
*   **[SOPS_VS_AGENIX.md](../../docs/SOPS_VS_AGENIX.md)**: Comparing modern NixOS secret managers.
*   **[AGENIX_GUIDE.md](../../docs/AGENIX_GUIDE.md)**: Managing server-level secrets with agenix.
*   **Service Accounts**: Securing automated identities.
*   **API Server Hardening**: Authentication (OIDC, Certificates) and Authorization.

### 3. Policy & Governance
*   **Pod Security Admission (PSA)**: Built-in enforcement of security standards.
*   **Network Policies**: Implementing zero-trust networking between pods.
*   **Admission Controllers**: Using OPA/Gatekeeper for custom policy enforcement.

### 4. Hardening the Infrastructure
*   **Node Security**: OS hardening (NixOS specific tips).
*   **Secrets Management**: Securely handling sensitive data (Vault, SealedSecrets).
*   **Control Plane Security**: ETCD encryption and API protection.

### 5. Runtime Security & IR
*   **Detection**: monitoring with Falco or Tracee.
*   **Auditing**: Analyzing Kubernetes audit logs for suspicious activity.

---

## 🚀 How to use this path
1.  Start with the **Isolation** lab to see how easy it is to break a weak cluster.
2.  Move to **RBAC** to learn how to lock down the "keys to the kingdom".
3.  Implement **Policies** to prevent weak configurations from being deployed.

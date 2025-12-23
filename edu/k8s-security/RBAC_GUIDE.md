# Kubernetes RBAC: Role-Based Access Control and Hardening

RBAC is the mechanism that determines "Who can do What to which Resource". It is the most critical defense line in a Kubernetes cluster.

---

## 🧩 RBAC Core Concepts

RBAC uses four main objects:

### 1. Role & ClusterRole (The "What")
Defines a set of permissions.
- **Role**: Namespaced (applies to one namespace).
- **ClusterRole**: Cluster-scoped (applies across all namespaces or cluster-wide resources like Nodes).

**Example Role (Read-only for Pods):**
```yaml
kind: Role
metadata:
  namespace: my-app
  name: pod-reader
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

### 2. RoleBinding & ClusterRoleBinding (The "Who")
Connects a Role/ClusterRole to a **Subject** (User, Group, or ServiceAccount).

**Example Binding:**
```yaml
kind: RoleBinding
metadata:
  name: read-pods-binding
  namespace: my-app
subjects:
- kind: ServiceAccount
  name: my-app-sa
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

---

## 🚩 Common RBAC Misconfigurations (The Risks)

### 1. The "Wildcard" Admin
Giving `*` verbs on `*` resources. This is usually unnecessary and extremely dangerous.
```yaml
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
```

### 2. Excessive Permissions on Secrets
Users or Pods that can `list` or `get` secrets globally can steal passwords, token, and keys.

### 3. Ability to create `Pods` or `Deployments`
If an attacker can create pods, they can often create a **Privileged Pod** to escape to the host node.

### 4. `Escalate` or `Bind` permissions
Special verbs that allow a user to grant themselves more permissions than they currently have.

---

## 🛡️ RBAC Hardening Techniques

### 1. Principle of Least Privilege (PoLP)
Only grant the absolute minimum permissions required.
- Isolate apps into **Namespaces**.
- Use **Roles** instead of ClusterRoles whenever possible.
- Avoid using the `default` ServiceAccount.

### 2. Disable Automounting Tokens
If your pod doesn't need to talk to the K8s API, don't give it a token.
```yaml
spec:
  automountServiceAccountToken: false
```

### 3. Audit Over-Privileged ServiceAccounts
Regularly scan for SAs with `cluster-admin` or high-privilege roles.
```bash
# List all ClusterRoleBindings with cluster-admin
kubectl get clusterrolebindings -o json | jq '.items[] | select(.roleRef.name=="cluster-admin")'
```

### 4. Use `ResourceNames` to Restrict Access
Instead of allowing access to ALL secrets, allow access only to a specific one:
```yaml
rules:
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["my-app-db-secret"]  # 🟢 Specific restriction
  verbs: ["get"]
```

### 5. Periodically Clean Up Unused RBAC
Remove bindings for users who left or services that were deleted.

---

## 🛠️ RBAC Security Lab Exercise

### Project: "The Secret Thief"

1.  **Create a ServiceAccount** with `get` permissions on all secrets.
2.  **Deploy a Pod** using this ServiceAccount.
3.  **Exec into the Pod** and try to steal a secret from a DIFFERENT namespace.
4.  **Harden it**: Change the Role to use `resourceNames` to limit access only to its own secret.
5.  **Verify**: Try to steal again—it should fail!

---

## 🔍 Recommended Tools
- **[Krane](https://github.com/appvia/krane)**: RBAC static analysis tool.
- **[RBAC-Lookup](https://github.com/FairwindsOps/rbac-lookup)**: Easily find which users/SAs have what permissions.
- **[Kubescape](https://github.com/kubescape/kubescape)**: Scans for RBAC vulnerabilities and compliance.

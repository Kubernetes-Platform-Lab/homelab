# Kubernetes Security Lab: Understanding and Preventing Takeovers

Learning security is most effective when you understand the **attacker's perspective**. In this guide, we will explore "badly configured pods" and how they can lead to a full cluster takeover.

---

## 🏗️ Attack Vector 1: The Privileged Pod Escape

A "privileged" container has nearly all the same capabilities as the host machine's root user.

### 🚩 The Vulnerability
```yaml
spec:
  containers:
  - name: exploit-me
    image: alpine
    securityContext:
      privileged: true  # 🔴 DANGEROUS
```

### 🔓 The Attack (Breakout)
If an attacker gains shell access to this pod, they can:
1. Access all host devices.
2. Mount the host's root filesystem.
3. Infect the host or other pods.

**Commands an attacker might run inside the pod:**
```bash
# See host disks
lsblk 
# Mount host root filesystem
mkdir /host && mount /dev/sda1 /host
# Access host files (like /etc/shadow or SSH keys)
cat /host/etc/shadow
```

### 🛡️ Prevention
- **Never** run privileged containers unless absolutely necessary.
- Use **Pod Security Admission (PSA)** with the `restricted` profile to block privileged pods.
- Implement **Runtime Security** (like Falco) to detect mount attempts.

---

## 🏗️ Attack Vector 2: Writable HostPath Mounts

Mounting host directories into a pod is often necessary for logging or monitoring, but it's a huge security risk if misconfigured.

### 🚩 The Vulnerability
```yaml
spec:
  containers:
  - name: exploit-me
    volumeMounts:
    - name: host-root
      mountPath: /mnt/host
  volumes:
  - name: host-root
    hostPath:
      path: /  # 🔴 MOUNTING ENTIRE HOST ROOT
```

### 🔓 The Attack
An attacker can:
1. Add their SSH public key to the host's `/root/.ssh/authorized_keys`.
2. Modify `crontab` on the host to execute a reverse shell.
3. Overwrite system binaries (like `ls` or `sh`) with malicious versions.

### 🛡️ Prevention
- Use **Read-only** mounts if you must use `hostPath`.
- Better yet: **Avoid `hostPath` entirely**. Use `mountPropagation: HostToContainer` only when strictly required.
- Use **Admission Controllers** (OPA/Gatekeeper) to restrict which host paths can be mounted.

---

## 🏗️ Attack Vector 3: Service Account Token Theft

By default, every pod gets a service account token mounted at `/var/run/secrets/kubernetes.io/serviceaccount/token`.

### 🚩 The Vulnerability
If the **ServiceAccount** assigned to the pod has overly permissive **RBAC** (e.g., `cluster-admin` or rights to create Pods/secrets), the pod becomes a target.

### 🔓 The Attack
An attacker can use the token to talk to the Kubernetes API:
```bash
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl -K -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc/api/v1/secrets
```
If the token has rights, the attacker can steal secrets (like DB passwords or other service tokens) across the **entire cluster**.

### 🛡️ Prevention
- **Principle of Least Privilege**: Give ServiceAccounts ONLY the permissions they need.
- Set `automountServiceAccountToken: false` in the Pod spec if the pod doesn't need to talk to the API.
- Use **Network Policies** to block pods from reaching the internal API server IP.

---

## 🏗️ Attack Vector 4: Host Network/PID/IPC Sharing

Sharing host namespaces breaks the fundamental isolation of containers.

### 🚩 The Vulnerability
```yaml
spec:
  hostNetwork: true  # 🔴 ACCESS TO HOST INTERFACES
  hostPID: true      # 🔴 VIEW ALL PROCESSES ON HOST
  hostIPC: true      # 🔴 ACCESS HOST SHARED MEMORY
```

### 🔓 The Attack
- `hostNetwork`: Can listen to traffic on the host (e.g., capture passwords from other services).
- `hostPID`: Can see all processes on the node, including those of other pods, and even kill them or inject code.

### 🛡️ Prevention
- Set these to `false` (default) and enforce it via **Pod Security Standards**.

---

## 🛠️ The "Takeover" Checklist (Learning Lab)

If you want to simulate this safely in your lab:

1.  **Create a "Victim" Namespace**:
    ```bash
    kubectl create ns security-lab
    ```
2.  **Deploy a Misconfigured Pod**:
    Try deploying a pod with `privileged: true` and `hostPath: /`.
3.  **Attempt Breakout**:
    `kubectl exec` into the pod and try to see `/etc/shadow` on the host.
4.  **Harden the Namespace**:
    Apply a Pod Security label to the namespace:
    ```bash
    kubectl label ns security-lab pod-security.kubernetes.io/enforce=restricted
    ```
5.  **Test Again**:
    Try to deploy the same pod. It should now be **REJECTED** by Kubernetes.

---

## 🔍 Tools for Scanning

- **[Kube-bench](https://github.com/aquasecurity/kube-bench)**: Checks cluster against CIS Benchmarks.
- **[Kube-hunter](https://github.com/aquasecurity/kube-hunter)**: Hunts for security weaknesses in your cluster.
- **[Checkov](https://github.com/bridgecrewio/checkov)**: Scans your YAML files for misconfigurations before you deploy.

## 🎓 Summary
Security isn't a single switch; it's **Defense in Depth**. By understanding how an attacker escapes a pod, you can build clusters that are "Secure by Default".

**Pro Tip**: In your Talos/NixOS lab, use **PodSecurityAdmission** from day one. It's the most powerful built-in tool you have.

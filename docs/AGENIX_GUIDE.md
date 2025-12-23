# Secret Management in NixOS: agenix vs sops-nix

Managing secrets (passwords, keys, certificates) in a declarative NixOS configuration is a challenge because everything in `/nix/store` is world-readable. Tools like **agenix** and **sops-nix** solve this by keeping secrets encrypted in your repository and decrypting them only on the target machine.

---

## 🔒 What is agenix?

**agenix** is a NixOS tool that uses `age` (a modern encryption tool) to encrypt secrets. Crucially, it uses **SSH keys** (Ed25519 or RSA) for encryption/decryption.

### Why it's a GREAT choice for your fleet:
1.  **Uses SSH Keys**: You already have SSH keys for your hypervisors (`hyp01`, `hyp02`). No need to manage PGP/GPG keys or cloud KMS.
2.  **Simple**: The configuration is very straightforward.
3.  **Lightweight**: Minimal dependencies.
4.  **No Plaintext in Nix Store**: Secrets are decrypted into a temporary `ramfs` (memory) at boot, so they are never stored in plaintext on disk or in the Nix store.

---

## ⚖️ agenix vs sops-nix

| Feature | agenix | sops-nix |
|---|---|---|
| **Encryption Engine** | `age` | `sops` (supports age, GPG, AWS/GCP/Azure KMS) |
| **Identity** | SSH Keys (mostly) | SSH Keys, GPG, Cloud IAM |
| **Complexity** | Low (Very simple) | Medium (More features/options) |
| **Editing** | Command line `agenix -e` | Standard `sops` editor |
| **Best For** | Small-Medium server fleets | Large enterprise / Cloud-heavy fleets |

---

## 🛠️ How agenix Works in a "Fleet"

In your `nixlab` repo, you would have a `secrets/secrets.nix` file that defines who can decrypt what:

```nix
let
  valdi = "ssh-ed25519 AAAAC3Nza..."; # Your workstation key
  hyp01 = "ssh-ed25519 AAAAC3Nza..."; # Host key of hyp01
in
{
  "tailscale-key.age".publicKeys = [ valdi hyp01 ];
  "libvirt-cert.age".publicKeys = [ valdi hyp01 ];
}
```

### The Workflow:
1.  **Encrypt**: You encrypt a secret on your workstation using the server's public SSH key.
2.  **Commit**: You commit the `.age` file to Git.
3.  **Deploy**: During `deploy-rs`, the encrypted file is sent to the server.
4.  **Decrypt**: At boot/activation, the server uses its **private host key** (`/etc/ssh/ssh_host_ed25519_key`) to decrypt the secret into `/run/agenix/`.

---

## 🎯 Is it good for your "Fleet"?

**Yes, absolutely.** For a hypervisor lab like yours:
- **Automation**: It integrates perfectly with your `flake.nix`.
- **Security**: It keeps your Talos secrets and bridge credentials out of public GitHub.
- **Convenience**: You don't need a separate "Secret Server" (like Vault) to get started.

---

## 🚀 Example Integration

To add `agenix` to your `nixlab` project:

1.  **Add Input to `flake.nix`**:
    ```nix
    agenix.url = "github:ryantm/agenix";
    ```
2.  **Add Module to `common.nix`**:
    ```nix
    imports = [ agenix.nixosModules.default ];
    age.secrets.root-password.file = ../../secrets/password.age;
    ```

## 🛡️ Hardening Tip: Permission Control
agenix allows you to set ownership and permissions for the decrypted secret:
```nix
age.secrets.my-secret = {
  file = ./secret.age;
  owner = "libvirtd";
  group = "libvirtd";
  mode = "0400";
};
```

## 🎓 Summary
For your `hyp01...hypXX` fleet, **agenix** is the most "Nix-native" and painless way to handle secrets. It scales well up to dozens of servers. If you ever move to a huge enterprise environment, you might look at `sops-nix` for its Vault/KMS integration, but for now, agenix is the winner.

resource "vault_mount" "kv_v2" {
  path        = "secret"
  type        = "kv-v2"
  description = "KV v2 secrets engine"
}

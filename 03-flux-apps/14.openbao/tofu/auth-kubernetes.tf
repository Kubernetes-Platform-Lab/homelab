resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "config" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = "https://kubernetes.default.svc.cluster.local"
}

resource "vault_kubernetes_auth_backend_role" "tofu_runner" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "tofu-runner"
  bound_service_account_names      = ["*"]
  bound_service_account_namespaces = ["openbao"]
  token_policies                   = ["terraform-admin"]
  ttl                              = 21600
}

resource "openbao_kubernetes_auth_backend_role" "external_secrets" {
  backend                          = openbao_auth_backend.kubernetes.path
  role_name                        = "external-secrets"
  bound_service_account_names      = ["external-secrets"]
  bound_service_account_namespaces = ["external-secrets"]
  token_policies                   = ["secret-reader"]
  ttl                              = 86400
}

resource "vault_policy" "external_secrets_reader" {
  name = "external-secrets-reader"

  policy = <<-EOT
    path "secret/data/*" {
      capabilities = ["read"]
    }

    path "secret/metadata/*" {
      capabilities = ["read", "list"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "external_secrets" {
  backend   = "kubernetes"
  role_name = "external-secrets"

  bound_service_account_names = [
    var.external_secrets_service_account,
  ]

  bound_service_account_namespaces = [
    var.external_secrets_namespace,
  ]

  token_policies = [
    vault_policy.external_secrets_reader.name,
  ]

  token_ttl     = 1800
  token_max_ttl = 3600
}

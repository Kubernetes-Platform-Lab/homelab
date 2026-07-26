resource "vault_policy" "secret_reader" {
  name = "secret-reader"
  policy = <<EOT
path "secret/data/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/*" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_policy" "terraform_admin" {
  name = "terraform-admin"
  policy = <<EOT
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOT
}

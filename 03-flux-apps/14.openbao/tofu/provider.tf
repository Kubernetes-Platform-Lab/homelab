locals {
  service_account_jwt = trimspace(
    file("/var/run/secrets/kubernetes.io/serviceaccount/token")
  )
}

provider "vault" {
  address          = var.openbao_address
  ca_cert_file     = var.openbao_ca_cert_file
  skip_child_token = true

  auth_login {
    path = "auth/kubernetes/login"

    parameters = {
      role = "tofu-runner"
      jwt  = local.service_account_jwt
    }
  }
}

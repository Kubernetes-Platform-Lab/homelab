locals {
  service_account_jwt = trimspace(
    file("/var/run/secrets/kubernetes.io/serviceaccount/token")
  )
}

provider "vault" {
  address          = var.openbao_address
  ca_cert_file     = "${path.module}/openbao-ca.crt"
  skip_child_token = true

  auth_login {
    path = "auth/kubernetes/login"

    parameters = {
      role = "tofu-runner"
      jwt  = local.service_account_jwt
    }
  }
}

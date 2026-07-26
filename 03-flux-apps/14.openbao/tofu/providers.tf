terraform {
  required_providers {
    openbao = {
      source = "opentofu/vault"
      version = "~> 1.0"
    }
  }
}

provider "openbao" {
  skip_verify = true
  auth_login {
    path = "auth/kubernetes/login"
    parameters = {
      role = "tofu-runner"
      jwt  = file("/var/run/secrets/kubernetes.io/serviceaccount/token")
    }
  }
}

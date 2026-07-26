terraform {
  required_providers {
    openbao = {
      source = "hashicorp/vault"
      version = "~> 5.10.0"
    }
  }
}

provider "openbao" {
  auth_login {
    path = "auth/kubernetes/login"
    parameters = {
      role = "tofu-runner"
      jwt  = file("/var/run/secrets/kubernetes.io/serviceaccount/token")
    }
  }
}

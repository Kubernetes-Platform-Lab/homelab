resource "openbao_auth_backend" "oidc" {
  type = "oidc"
  path = "oidc"
}

resource "openbao_jwt_auth_backend_role" "authentik" {
  backend        = openbao_auth_backend.oidc.path
  role_name      = "authentik"
  role_type      = "oidc"
  token_policies = ["secret-reader"]

  oidc_scopes = [
    "openid",
    "profile",
    "email",
  ]

  bound_audiences   = []
  allowed_redirect_uris = []
  user_claim        = "sub"
  verbose_oidc_logging = true
}

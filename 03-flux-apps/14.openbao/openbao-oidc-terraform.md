# OpenBao OIDC przez Terraform / OpenTofu

Ten dokument opisuje konfigurację logowania OIDC do UI OpenBao wystawionego pod adresem:

```text
https://vault.akna.one.pl
```

Zakładana ścieżka metody auth:

```text
oidc
```

## 1. Redirect URI po stronie dostawcy OIDC

W konfiguracji klienta u dostawcy OIDC dodaj dokładnie ten adres jako **Redirect URI**, **Callback URL** albo **Response URL**:

```text
https://vault.akna.one.pl/ui/vault/auth/oidc/oidc/callback
```

Adres musi zgadzać się dokładnie, łącznie z:

- `https`,
- nazwą hosta,
- ścieżką,
- brakiem końcowego `/`.

Jeżeli metoda auth zostanie zamontowana pod inną ścieżką, np. `sso`, callback zmieni się na:

```text
https://vault.akna.one.pl/ui/vault/auth/sso/oidc/callback
```

Opcjonalny callback dla logowania z CLI:

```text
http://localhost:8250/oidc/callback
```

## 2. Wymagane dane

Przygotuj:

```text
OIDC issuer / discovery URL
Client ID
Client Secret
```

`oidc_discovery_url` powinien być bazowym adresem issuera, bez końcówki:

```text
/.well-known/openid-configuration
```

Przykład dla Keycloak:

```text
https://sso.example.com/realms/infra
```

Wartość powinna odpowiadać polu `issuer` zwracanemu przez dokument discovery:

```bash
curl -s https://sso.example.com/realms/infra/.well-known/openid-configuration \
  | jq -r .issuer
```

## 3. Zmienne Terraform

Plik `variables.tf`:

```hcl
variable "oidc_issuer" {
  description = "OIDC issuer/discovery URL without /.well-known/openid-configuration"
  type        = string
}

variable "oidc_client_id" {
  description = "OIDC client ID"
  type        = string
}

variable "oidc_client_secret" {
  description = "OIDC client secret"
  type        = string
  sensitive   = true
}

variable "oidc_client_secret_version" {
  description = "Increase when rotating the write-only client secret"
  type        = number
  default     = 1
}

variable "oidc_token_policies" {
  description = "OpenBao policies attached to tokens issued through OIDC"
  type        = list(string)
  default     = ["default"]
}
```

## 4. Auth method i rola OIDC

Plik `oidc.tf`:

```hcl
locals {
  oidc_ui_callback = "https://vault.akna.one.pl/ui/vault/auth/oidc/oidc/callback"
}

resource "vault_jwt_auth_backend" "oidc" {
  path        = "oidc"
  type        = "oidc"
  description = "OIDC login for OpenBao UI"

  oidc_discovery_url = var.oidc_issuer
  bound_issuer       = var.oidc_issuer
  oidc_client_id     = var.oidc_client_id

  # Preferowany wariant w nowszych wersjach providera:
  # sekret nie jest przechowywany w stanie Terraform.
  oidc_client_secret_wo         = var.oidc_client_secret
  oidc_client_secret_wo_version = var.oidc_client_secret_version

  default_role = "default"

  tune {
    listing_visibility = "unauth"
  }
}

resource "vault_jwt_auth_backend_role" "default" {
  backend   = vault_jwt_auth_backend.oidc.path
  role_name = "default"
  role_type = "oidc"

  user_claim = "sub"

  allowed_redirect_uris = [
    local.oidc_ui_callback,
  ]

  oidc_scopes = [
    "profile",
    "email",
  ]

  token_policies = var.oidc_token_policies

  token_ttl     = 1800
  token_max_ttl = 28800
}
```

### Wariant zgodności bez pól write-only

Jeżeli używana wersja OpenTofu lub providera nie obsługuje `oidc_client_secret_wo`, usuń:

```hcl
oidc_client_secret_wo         = var.oidc_client_secret
oidc_client_secret_wo_version = var.oidc_client_secret_version
```

i użyj:

```hcl
oidc_client_secret = var.oidc_client_secret
```

Uwaga: zwykłe `oidc_client_secret` jest zapisywane w stanie Terraform. Stan musi być odpowiednio chroniony.

Nie wolno używać jednocześnie `oidc_client_secret` i `oidc_client_secret_wo`.

## 5. Przekazanie wartości do tofu-controller

Dane niesekretne można przekazać przez `spec.vars`:

```yaml
spec:
  vars:
    - name: oidc_issuer
      value: https://sso.example.com/realms/infra

    - name: oidc_client_id
      value: openbao

    - name: oidc_token_policies
      value:
        - default
        - openbao-user
```

Client Secret umieść w Kubernetes Secret w namespace runnera, np. `terraform-infra-runners`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: openbao-oidc
  namespace: terraform-infra-runners
type: Opaque
stringData:
  TF_VAR_oidc_client_secret: REPLACE_ME
```

W repozytorium GitOps sekret powinien być szyfrowany, np. przez SOPS, albo dostarczany z zewnętrznego systemu sekretów.

Dodaj Secret do środowiska runnera:

```yaml
spec:
  runnerPodTemplate:
    spec:
      envFrom:
        - secretRef:
            name: openbao-oidc
```

Wersję sekretu można przekazać jako zwykłą zmienną:

```yaml
spec:
  vars:
    - name: oidc_client_secret_version
      value: 1
```

Przy rotacji sekretu:

1. zmień wartość `TF_VAR_oidc_client_secret`,
2. zwiększ `oidc_client_secret_version`, np. z `1` na `2`,
3. uruchom ponowny reconcile.

## 6. Policy dla tofu-controller

Token runnera musi mieć uprawnienia do utworzenia auth method, konfiguracji backendu i zarządzania rolami.

Dodaj do policy używanej przez runner:

```hcl
path "sys/auth" {
  capabilities = ["read"]
}

path "sys/auth/oidc" {
  capabilities = ["create", "read", "update", "delete", "sudo"]
}

path "sys/auth/oidc/tune" {
  capabilities = ["read", "update", "sudo"]
}

# Alternatywny endpoint tune bez wymagania sudo.
path "sys/mounts/auth/oidc/tune" {
  capabilities = ["read", "update"]
}

path "auth/oidc/config" {
  capabilities = ["create", "read", "update", "delete"]
}

path "auth/oidc/role" {
  capabilities = ["list"]
}

path "auth/oidc/role/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
```

## 7. Import istniejącej konfiguracji

Jeżeli metoda `oidc` została wcześniej utworzona ręcznie przez UI lub CLI, zaimportuj ją przed `apply`:

```bash
tofu import vault_jwt_auth_backend.oidc oidc
```

Jeżeli istnieje już rola `default`:

```bash
tofu import \
  vault_jwt_auth_backend_role.default \
  auth/oidc/role/default
```

Po imporcie:

```bash
tofu plan
```

Sprawdź plan przed zatwierdzeniem, szczególnie pola:

```text
oidc_discovery_url
bound_issuer
default_role
allowed_redirect_uris
token_policies
```

Alternatywnie usuń pustą, ręcznie utworzoną metodę `oidc` i pozwól Terraformowi utworzyć ją od nowa.

## 8. Opcjonalne mapowanie grup

Jeżeli provider OIDC zwraca claim `groups`, można dodać go do roli:

```hcl
resource "vault_jwt_auth_backend_role" "default" {
  # ...

  user_claim   = "sub"
  groups_claim = "groups"

  oidc_scopes = [
    "profile",
    "email",
    "groups",
  ]
}
```

Samo pobranie grup nie nadaje automatycznie dodatkowych policy. Do mapowania grup OIDC na policy OpenBao potrzebne są Identity Groups oraz Group Aliases.

Najpierw uruchom logowanie bez skomplikowanych `bound_claims`. Po potwierdzeniu działania callbacku można dodać ograniczenia po grupach, domenie e-mail lub innych claimach.

## 9. Weryfikacja

Po `apply` sprawdź metodę auth:

```bash
bao auth list
```

Oczekiwany mount:

```text
oidc/
```

Sprawdź konfigurację:

```bash
bao read auth/oidc/config
```

Sprawdź rolę:

```bash
bao read auth/oidc/role/default
```

Na ekranie logowania UI:

1. wybierz metodę `OIDC`,
2. rola powinna domyślnie użyć `default`,
3. kliknij `Sign In`,
4. zakończ logowanie u dostawcy OIDC.

## 10. Najczęstsze błędy

### `redirect_uri_mismatch`

Callback po stronie providera i w `allowed_redirect_uris` nie jest identyczny.

Prawidłowa wartość:

```text
https://vault.akna.one.pl/ui/vault/auth/oidc/oidc/callback
```

### `issuer does not match`

`bound_issuer` lub `oidc_discovery_url` nie odpowiada wartości `issuer` z discovery document. Zwróć uwagę na końcowy `/`.

### Metoda OIDC nie jest widoczna na ekranie logowania

Sprawdź:

```hcl
tune {
  listing_visibility = "unauth"
}
```

### Logowanie działa, ale użytkownik niczego nie widzi

OIDC uwierzytelnia użytkownika, ale dostęp wynika z policy przypisanych przez:

```hcl
token_policies
```

Policy `default` zwykle nie daje dostępu do sekretów ani funkcji administracyjnych.

### Terraform zwraca `path is already in use`

Metoda `oidc` już istnieje. Wykonaj import albo usuń ręcznie utworzony mount.

## 11. Źródła

- OpenBao: JWT/OIDC auth method  
  https://openbao.org/docs/auth/jwt/
- OpenBao: JWT/OIDC auth method API  
  https://openbao.org/api-docs/auth/jwt/
- OpenBao: `/sys/auth` API  
  https://openbao.org/api-docs/system/auth/
- Terraform Provider Vault: `vault_jwt_auth_backend`  
  https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend
- Terraform Provider Vault: `vault_jwt_auth_backend_role`  
  https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend_role
- tofu-controller API: `runnerPodTemplate.spec.envFrom`  
  https://flux-iac.github.io/tofu-controller/References/terraform/

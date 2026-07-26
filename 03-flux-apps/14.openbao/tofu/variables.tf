variable "openbao_address" {
  description = "OpenBao API address"
  type        = string
}

variable "openbao_ca_cert_file" {
  description = "Path to the OpenBao CA certificate inside the runner Pod"
  type        = string
  default     = "/openbao/ca/ca.crt"
}

variable "external_secrets_service_account" {
  description = "External Secrets Operator ServiceAccount name"
  type        = string
  default     = "external-secrets"
}

variable "external_secrets_namespace" {
  description = "Namespace containing External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

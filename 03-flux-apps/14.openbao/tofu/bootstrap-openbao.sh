#!/usr/bin/env bash
set -Eeuo pipefail

OPENBAO_NAMESPACE="${OPENBAO_NAMESPACE:-openbao}"
OPENBAO_POD="${OPENBAO_POD:-openbao-0}"
OPENBAO_SERVICE_ACCOUNT="${OPENBAO_SERVICE_ACCOUNT:-openbao}"

RUNNER_NAMESPACE="${RUNNER_NAMESPACE:-terraform-infra-runners}"
RUNNER_SERVICE_ACCOUNT="${RUNNER_SERVICE_ACCOUNT:-tf-runner}"

OPENBAO_ADDR="${OPENBAO_ADDR:-https://openbao-active.openbao.svc.cluster.local:8200}"
OPENBAO_CACERT="${OPENBAO_CACERT:-/openbao/ca/ca.crt}"

# Read the OpenBao root token without storing it in shell history.
read -rsp "OpenBao root token: " ROOT_TOKEN
echo

# Run the OpenBao CLI inside the OpenBao Pod.
# This avoids requiring the bao CLI and internal cluster DNS access
# on the machine executing this script.
bao() {
  kubectl exec -i \
    -n "${OPENBAO_NAMESPACE}" \
    "${OPENBAO_POD}" \
    -- env \
      BAO_ADDR="${OPENBAO_ADDR}" \
      BAO_CACERT="${OPENBAO_CACERT}" \
      BAO_TOKEN="${ROOT_TOKEN}" \
      bao "$@"
}

echo "Configuring Kubernetes TokenReview RBAC..."

# Allow the OpenBao ServiceAccount to validate Kubernetes
# ServiceAccount JWT tokens through the TokenReview API.
kubectl create clusterrolebinding openbao-token-reviewer \
  --clusterrole=system:auth-delegator \
  --serviceaccount="${OPENBAO_NAMESPACE}:${OPENBAO_SERVICE_ACCOUNT}" \
  --dry-run=client \
  -o yaml |
  kubectl apply -f -

echo "Enabling Kubernetes authentication..."

# Enable the Kubernetes auth method only if it does not already exist.
if ! bao auth list -format=json | grep -q '"kubernetes/"'; then
  bao auth enable kubernetes
else
  echo "Kubernetes auth is already enabled."
fi

# Configure OpenBao to use the in-cluster Kubernetes API.
#
# token_reviewer_jwt and kubernetes_ca_cert are intentionally omitted.
# OpenBao will use the ServiceAccount token and CA certificate mounted
# in its own Pod.
bao write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc:443"

echo "Creating the tofu-controller policy..."

# This policy allows tofu-controller to:
# - inspect its own token and capabilities,
# - manage ACL policies,
# - manage roles under the Kubernetes auth method.
#
# It does not grant unrestricted administrative access to OpenBao.
cat <<'HCL' | bao policy write tofu-controller -
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "sys/capabilities-self" {
  capabilities = ["update"]
}

path "sys/auth" {
  capabilities = ["read"]
}

path "sys/auth/kubernetes" {
  capabilities = ["read"]
}

path "sys/policies/acl" {
  capabilities = ["read", "list"]
}

path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "auth/kubernetes/role" {
  capabilities = ["read", "list"]
}

path "auth/kubernetes/role/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
HCL

echo "Creating the tofu-runner Kubernetes auth role..."

# Bind the OpenBao role to one specific Kubernetes ServiceAccount
# running in one specific namespace.
bao write auth/kubernetes/role/tofu-runner \
  bound_service_account_names="${RUNNER_SERVICE_ACCOUNT}" \
  bound_service_account_namespaces="${RUNNER_NAMESPACE}" \
  token_policies="tofu-controller" \
  token_ttl="30m" \
  token_max_ttl="1h"

echo
echo "Bootstrap completed successfully."
echo "Runner identity: ${RUNNER_NAMESPACE}/${RUNNER_SERVICE_ACCOUNT}"
echo "Auth endpoint:   auth/kubernetes/login"
echo "OpenBao role:    tofu-runner"

# Remove the root token from the current shell process environment.
unset ROOT_TOKEN

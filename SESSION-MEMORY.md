# Session Memory — OpenBao / tofu-controller / homelab-infra work

Last updated: 2026-08-01. This file preserves cross-session context. Read it
before working on 02-kubernetes, 03-flux-apps, or homelab-infra.

## Repos

| Repo | Path | Visibility | Notes |
|---|---|---|---|
| `homelab` | `/home/valdi/10-19.Projekty/workflow/homelab` | **public** (portfolio) | Flux gitops; apps in `03-flux-apps/` (Flux) + `04-argocd-apps/` (ArgoCD). Remote: `github` |
| `homelab-infra` | `/home/valdi/10-19.Projekty/workflow/homelab-infra` | **private** | OpenTofu configs for tofu-controller. Remote: `github` |

## homelab-infra layout (per-service modules + per-env tfvars)

```
homelab-infra/
├── openbao/               # OpenBao root module (shared, both envs)
│   ├── *.tf               # provider/variables/versions/external-secrets
│   ├── openbao-ca.crt
│   ├── bootstrap-openbao.sh
│   └── config/
│       ├── prod.tfvars
│       └── test.tfvars
└── tailscale/             # scaffold template only (not wired to a CR)
```

- Each `<service>/` dir is ONE root module shared across environments; env values
  live in `<service>/config/<env>.tfvars`. One Terraform CR per service-env.
- **tfVarsFiles paths are repo-root-relative** (confirmed in tofu-controller
  `runner/server_plan.go` — `securejoin.SecureJoin(req.SourceRefRootDir, path)`).
  So `path: ./openbao` + `tfVarsFiles: [./openbao/config/prod.tfvars]` both work.
- Old `services/` and `environments/` dirs were removed. Empty `services/`
  leftover dir was deleted on disk.

## tofu-controller setup

- Namespace `tofu-controller`; Terraform CRs in `tofu-runners`.
- `helmrelease.yaml`: `allowBreakTheGlass: true`, `allowCrossNamespaceRefs: true`,
  `watchAllNamespaces: true`, `branchPlanner.enabled: true`.
- Runner pods run in the **same namespace as the Terraform CR** (`tofu-runners`),
  using the `tf-runner` SA (allowedNamespaces: `flux-system`, `tofu-runners`).
  Pod name pattern: `<cr-name>-tf-runner`. `openbao-config-tf-runner` lives in
  `tofu-runners` (NOT the `openbao` namespace — name is misleading).
- State: kubernetes backend. Secret `tfstate-default-<secretSuffix>` + Lease
  `lock-tfstate-default-<secretSuffix>` in the CR namespace.
  `backendConfig.secretSuffix: openbao-config` → `tfstate-default-openbao-config`.
  One CR per service-env → one state. tfvars files do NOT create state.

## Branch Planner (plan-on-PR, apply-on-merge)

- Enabled via `branchPlanner.enabled: true` in the tofu-controller HelmRelease
  (`03-flux-apps/24.tofu-controller/`).
- ConfigMap `branch-planner` in `tofu-controller` ns → `secretName` +
  `resources` (watches `tofu-runners`).
- Secret `branch-planner-token` (key `token`) in `tofu-controller` ns — created
  **out-of-band** from the `flux-system` secret's `password` (classic PAT, `repo`
  scope). NOT committed (repo is public).
- `openbao-config` CR has `branchPlanner.enablePathScope: true` (plan only when
  PR touches `./openbao`) + `plan.lock: false` (concurrent PR plans, apply still locks).
- Flow: open PR on homelab-infra → plan-only run on branch → plan posted as PR
  comment (~30s poll). `!replan` to regenerate. Merge → main reconcile applies
  (`approvePlan: auto`). The 5m `interval` reconcile still runs independently.
- Verified: `tofu-controller-branch-planner` deployment up, polling the private
  homelab-infra repo with no auth errors.

## OpenBao ↔ External Secrets (working end-to-end)

- OpenBao: HA statefulset in `openbao` ns (`openbao-0/1/2`), KV v2 at `secret/`.
- ESO (`external-secrets` ns): ClusterSecretStore `homelab-secretstore` uses the
  `vault` provider → `https://openbao-active.openbao.svc:8200`, CA from ConfigMap
  `openbao-ca`, kubernetes auth (SA `external-secrets`, role `external-secrets`).
- tofu module `openbao/` creates policy `external-secrets-reader`
  (read/list `secret/data/*`, `secret/metadata/*`) + k8s-auth role
  `external-secrets` bound to that SA.
- Verified: store Ready/Valid; `ExternalSecret default/openbao-example` →
  Secret `openbao-example` (username/password) synced from `secret/lab/example`.
- Example ExternalSecret manifest is in git but NOT in the kustomization
  (applied manually earlier).
- `bootstrap-openbao.sh` sets up k8s auth + `tofu-runner` role; needs root token
  interactively (not stored anywhere).

## How to store secrets in OpenBao (guide)

- Run `bao` via the pod (no local CLI needed):
  `kubectl exec -n openbao openbao-0 -i -- env BAO_ADDR=https://openbao-active.openbao.svc:8200 BAO_CACERT=/openbao/ca/ca.crt BAO_TOKEN=<root-token> bao <cmd>`
- Write: `bao kv put secret/<service>/<name> key=value` (KV v2, CLI adds `data/`).
- Read/update/delete: `bao kv get|patch|metadata get|delete secret/<path>`.
- ESO `remoteRef.key` = path after `secret/` (e.g. `lab/example`).

## SealedSecrets inventory (from repo search) — migration candidates

| Secret | ns/name | What | Verdict |
|---|---|---|---|
| external-dns `desec-credentials` (api-token) | deSEC API token | **move to OpenBao** | simple, isolated |
| cert-manager `acme-dns` (acmedns.json) | ACME DNS-01 creds | **move to OpenBao** | static, isolated |
| mattermost `mattermost-postgres-secret` (DB_CONNECTION_*) | DB conn string | **leave to CNPG**, do NOT duplicate in OpenBao | CNPG already manages creds (`mattermost-postgres-app`) |

## Other secret contexts found (NOT candidates for ESO)

- SOPS infra/bootstrap secrets (Talos node configs, `talenv`, `talsecret.sops`,
  NixOS VM secrets, PXE kubeconfig) — consumed pre-cluster/node-bootstrap, out of
  scope for in-cluster ESO.
- Out-of-band in-cluster app secrets referenced by manifests but NOT in git:
  - `cloudflare/cloudflare-tunnel-token` (key `TUNNEL_TOKEN`) — used by cloudflared
    deployment (`23.cloudflared`). Candidate to migrate to OpenBao later.
  - `ente/ente-credentials` (key `credentials.yaml`) — used by ente app
    (`04-argocd-apps/ente`). Candidate later.
- CNPG-generated DB secrets (`mattermost-postgres-app`, `ente-postgres-app`) —
  leave to CloudNativePG.
- `sources/charts/common` secret template — not used by any app.

## Environment / tools

- `gh` CLI v2.97.0 authed as `ebi-droid` (scopes incl `repo`).
- `tfctl` = flux-iac tofu-controller CLI v0.16.4 at `~/.local/bin/tfctl`
  (NOT the HashiCorp tfctl at `/usr/local/bin`). Usage: `tfctl get openbao-config -n tofu-runners`.
- Deploy keys disabled at org level → use HTTPS + PAT.
- The `flux-system` secret in `flux-system` ns holds the PAT:
  `password` (40B classic PAT, `repo` scope) + `passwordgithub` (57B).
- Force flux reconcile: annotate with
  `reconcile.fluxcd.io/requestedAt="$(date -u +%Y-%m-%dT%H:%M:%SZ)" --field-manager=flux-client-side-apply --overwrite`.

## Pending / next steps

- Migrate `desec-credentials` + `acme-dns` to OpenBao + ExternalSecrets
  (create secrets in OpenBao, add ExternalSecret manifests, replace SealedSecrets).
- Consider migrating `cloudflare-tunnel-token` + `ente-credentials` to OpenBao.
- OpenBao **auto-unseal + resource limits** still not configured — root cause of
  the original recurring outage (nodes reboot → pods come up sealed).
- Replace placeholder `openbao-ca.crt` for a future test env.
- No cluster Terraform CR for test env yet.

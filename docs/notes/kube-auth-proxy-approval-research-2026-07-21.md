# kube-auth-proxy Approval Research

Date: 2026-07-21

## Component Profile

kube-auth-proxy is an OAuth2/OIDC reverse proxy forked from oauth2-proxy,
adapted for the RHOAI platform. It provides authentication for platform
services via OpenShift OAuth, OIDC providers, and Kubernetes ServiceAccount
token validation (TokenReview API).

- Runtime: Go
- 0 registered HTTP endpoints (it IS the auth proxy)
- 2 authentication facts (ServiceAccount token, TokenReview API)
- 1 integration point (Redis/Valkey session store)
- 0 internal ODH/RHOAI platform dependencies
- 2 runtime clients (Kubernetes API, Redis/Valkey)

## Blocker Analysis

### Blocker 1: Unsupported runtime source languages (FIXED)

**Root cause:** Three shell scripts were classified as "unsupported runtime
source" by `unsupportedRuntimeSourceSurfaces()`:
- `contrib/oauth2-proxy_autocomplete.sh` — bash completion script
- `dist.sh` — distribution/build script
- `scripts/keycloak_aws_instance.sh` — Keycloak test instance setup

None are runtime-relevant. `isSupportOnlyShellScript()` failed to exclude
them because:
- `contrib/` was not in the directory exclusion list
- `dist.sh` (root-level build script) was not in the basename exclusion list
- `scripts/keycloak_aws_instance.sh` was in the `scripts/` directory which
  was not handled with runtime-role detection

**Fix:** Extended `isSupportOnlyShellScript()` in `categorycoverage.go`:
1. Added `contrib`, `completions`, `packaging` to directory exclusions
2. Extended `scripts/` directory to use `runtimeShellScriptRole()` check
   (same pattern as `hack/` directory)
3. Added `build`, `dist`, `make`, `package`, `release` basename exclusions
4. Added `autocomplete`/`completion` basename pattern exclusions

Also extended `runtimeShellScriptRole()` to detect `start_*`, `start-*`,
and `start` basename patterns.

**Impact:** All 3 kube-auth-proxy scripts now properly classified as
support-only. Also resolved similar issues for many other components —
12 additional components became eligible.

### Blocker 2: Go source auth extractor incomplete (NOT BLOCKING)

The `authenticationLanguageLimitation()` fires because Go source exists
with partial coverage. However, kube-auth-proxy already has 2 Go-sourced
auth facts AND the authentication category has facts in the JSON (not
empty in the JSON sense).

The MARKDOWN authentication table is empty because kube-auth-proxy
registers zero HTTP endpoints — the table format tracks "endpoint → auth
mechanism" pairings, but as the auth proxy itself, it has no endpoints to
pair. Added `source_audited_empty_categories` entry for authentication.

### Blocker 3: Unaccounted Kubernetes API runtime client (NOT BLOCKING)

`runtimeClientIntegrationFacts()` in `platformfacts.go` does not map
Kubernetes API runtime clients to integration facts — it's intentionally
excluded as infrastructure. The integration_points category has 1 fact
(Redis/Valkey) so it's not empty.

### Blocker 4: Internal dependencies legitimately empty (RESOLVED)

With Blocker 1 fixed, `internal_dependencies` achieves `status: "complete"`
with `fact_count: 0`. The platform alias scan found 0 matches across 129
files, and there are no longer unsupported runtime source limitations.
This triggers the complete-empty contract mechanism, explaining the
category without a source-audited entry.

## Regression Fix

Re-extraction with the updated binary revealed 2 regressions in
previously approved components:

1. **mlflow**: Python import wiring added a `Kubernetes API`
   InternalDependency from `kubernetes` package import. This is core
   infrastructure, not an internal platform dependency. Added
   source-audited entry.

2. **rhaii-cluster-validation**: RBAC manifest generated a `Kubernetes API
   (nodes)` InternalDependency from ClusterRole. This is standard cluster
   access, not a platform dependency. Added source-audited entry.

Both regressions stem from `internal_odh` entries that appear in the JSON
but not in the markdown table, creating a mismatch between fact_count
(non-zero) and markdown row count (zero).

## Side Effects

The shell script classification fix made 12 additional components eligible:
MLServer, caikit-tgis-backend, caikit, kubeflow-sdk,
llama-stack-provider-trustyai-garak, llm-d-kv-cache, llm-d-routing-sidecar,
notebooks, pipelines-components, rhoai-mcp, rhods-operator, kube-auth-proxy.

6 components remain not eligible: fms-hf-tuning, llm-d-async,
lm-evaluation-harness, notebooks-downstream, ogx, vllm-cpu.

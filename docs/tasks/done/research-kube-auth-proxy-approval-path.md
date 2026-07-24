# Task: Resolve kube-auth-proxy Analyzer-Only Approval Path

## Goal

Research, fix, and approve kube-auth-proxy for analyzer-only routing.
Investigate 4 overlapping blockers, implement safe fixes, validate, and
approve if eligible.

## Context

kube-auth-proxy is an OAuth2/OIDC proxy forked from oauth2-proxy. It has
zero inbound runtime surfaces (no HTTP endpoints, gRPC services, or
webhooks registered by the analyzer), 2 authentication facts, 1
integration point, and 0 internal dependencies. All three high-value
categories are `partial` due to overlapping blockers.

It currently has:
- 2 auth facts: ServiceAccount token (in-cluster) and TokenReview API
  validation, both from `pkg/authentication/k8s/tokenreview.go`
- 1 integration fact: Redis/Valkey session store
- 2 runtime clients: Kubernetes API (tokenreview.go:61) and Redis/Valkey
  (redis_store.go:178)
- 1 external connection: Kubernetes API (go.mod)
- 0 internal dependencies (129 files scanned, 0 platform aliases)

## Blockers To Investigate

### Blocker 1: Unsupported runtime source languages (affects ALL 3 categories)

Three shell scripts are classified as "unsupported runtime source" by
`unsupportedRuntimeSourceSurfaces()` in `categorycoverage.go`:

- `contrib/oauth2-proxy_autocomplete.sh` — bash autocomplete script
- `dist.sh` — distribution/build script
- `scripts/keycloak_aws_instance.sh` — Keycloak test instance setup

**Research questions:**
1. Are these files actually runtime-relevant? (They appear to be build/CI
   tooling and shell completion — not shipped runtime behavior.)
2. Does `isSupportOnlyShellScript()` already try to exclude them? Why
   does it fail for these specific paths?
3. What change to the shell script classification would correctly exclude
   them without falsely excluding real runtime shell scripts (entrypoints,
   deploy hooks, operator hooks)?
4. Is this a kube-auth-proxy-specific fix, or would it generalize to
   other components? (Check: how many of the other 7 remaining components
   are also blocked by this same limitation, and would the same fix help
   them?)

### Blocker 2: "Go source auth extractor incomplete" (affects authentication)

The `authenticationLanguageLimitation()` function at `categorycoverage.go`
adds "Go source authentication constructs do not yet have a complete
category-specific extractor" when `applicableCoverage(coverage["source"])`
is true.

**Research questions:**
1. kube-auth-proxy already has 2 Go-sourced auth facts. Why does the
   limitation still fire? Is it because the check is binary (Go source
   exists → limitation) rather than checking whether auth facts from Go
   source already exist?
2. What is the intended semantics of this limitation? Is it a blanket
   "we can't fully analyze Go auth" or is it meant to fire only when Go
   auth analysis has gaps?
3. Would it be correct to suppress this limitation when Go-sourced auth
   facts already exist AND `no-inbound-runtime-surfaces` has passed?
   (i.e., we found auth facts, and there are no inbound surfaces that
   could have additional unresolved auth patterns)
4. Would this change affect other components? Check which approved
   components have Go source + auth facts and confirm they wouldn't
   regress.

### Blocker 3: Unaccounted Kubernetes API runtime client (affects integration_points)

The runtime client `Kubernetes API` at `tokenreview.go:61` is not
accounted for by any integration point fact. However:
- `platformfacts.go` has `runtimeClientIntegrationFacts()` which converts
  runtime clients to integration facts
- `platformfacts.go` has `runtimeClientInternalDependencies()` which
  converts runtime clients to internal dependencies
- Redis/Valkey IS accounted (has a matching integration fact), but
  Kubernetes API is NOT

**Research questions:**
1. Why does `runtimeClientIntegrationFacts()` produce a fact for
   Redis/Valkey but not for Kubernetes API? Is there a filter that
   excludes Kubernetes API clients?
2. Similarly, why does `runtimeClientInternalDependencies()` not produce
   an internal dependency for the Kubernetes API client? (internal_deps
   is 0)
3. Is the Kubernetes API intentionally excluded because it's treated as
   infrastructure rather than an integration point? If so, should
   `integrationPointsCoverage()` also exclude it from the "unaccounted"
   check?
4. The external connection for Kubernetes API (from go.mod) is also
   unaccounted. How does `unaccountedExternalConnections()` interact with
   the platformfacts conversion?

### Blocker 4: Internal dependencies legitimately empty?

internal_dependencies has fact_count 0, but the platform alias scan
found 0 blocking matches across 129 files. The only limitation is the
unsupported runtime source languages (Blocker 1).

**Research question:**
1. If Blocker 1 is resolved, does internal_dependencies become
   `status: "complete"` automatically? (i.e., is the alias scan the only
   other check, and it already passed?)

## Work

### Phase 1: Research (do this first)

Investigate all 4 blockers. For each, determine:
- Root cause with specific file/line references
- Whether a fix is safe and mechanical, or requires judgment about
  analyzer semantics
- Which other components would be affected (positively or negatively)

Write findings to
`docs/notes/kube-auth-proxy-approval-research-2026-07-21.md`.

### Phase 2: Implement safe fixes

For each blocker where the fix is safe:
- Implement the code change
- Add unit tests with positive and negative cases
- Run `go test ./...` and `go vet ./...` in `src/arch-analyzer`

If a blocker requires a judgment call about analyzer semantics that
could affect many components, document the trade-off in the research
note and implement only if the risk is low.

### Phase 3: Validate and approve

- Run a fresh 90-component replay:
  `python lib/run_platform.py rhoai.next --static-only 2>&1 | tail -20`
- Check kube-auth-proxy eligibility:
  `python -c "import json; data=json.load(open('tmp/architecture-corpus-runs/' + sorted(__import__('os').listdir('tmp/architecture-corpus-runs/'))[-1] + '/reports/eligibility-v1.json')); [print(c['component'], c.get('route'), c.get('gap_categories', [])) for c in data if c['component'] == 'kube-auth-proxy']"`
- Verify zero false nominations and no regressions on 50 approved components
- Check if any other components became eligible as side effects
- If eligible, add kube-auth-proxy to `lib/analyzer_only_approvals.json`
- Add source-audited empty category entries if needed

### Phase 4: Documentation

- Update `docs/notes/analyzer-residual-agent-gaps.md`
- Write validation note at
  `docs/notes/kube-auth-proxy-approval-validation-2026-07-21.md`
- Move this task to `docs/tasks/done/`

## Negative Controls

- Must not falsely exclude real runtime shell scripts (entrypoints,
  deploy hooks, operator hooks) when fixing shell script classification.
- Must not suppress Go auth limitation for components that genuinely
  have unresolved Go auth surfaces.
- Must not break existing category coverage for the 50 approved components.
- 90-component replay must show zero false nominations before any approval.

## Acceptance Criteria

- [ ] Research note documents all 4 blockers with root causes
- [ ] Safe fixes implemented with unit tests
- [ ] `go test ./...` and `go vet ./...` pass
- [ ] 90-component replay: zero false nominations
- [ ] No regressions on 50 previously approved components
- [ ] kube-auth-proxy approved if eligible (or documented why not)
- [ ] Side-effect approvals added if other components became eligible
- [ ] Residual register and validation notes updated
- [ ] Task moved to `docs/tasks/done/`

## Source Files To Read

- `src/arch-analyzer/internal/extractor/categorycoverage.go` — all three
  coverage functions, `unsupportedRuntimeSourceSurfaces()`,
  `isSupportOnlyShellScript()`, `authenticationLanguageLimitation()`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go` —
  `runtimeClientIntegrationFacts()`, `runtimeClientInternalDependencies()`
- `architecture/rhoai.next/kube-auth-proxy.json` — current extraction output
- `docs/notes/analyzer-residual-agent-gaps.md` — current residual register
- Architecture JSONs for the other 7 remaining components — check which
  share the unsupported language blocker

## Status

Done. kube-auth-proxy approved (51st component). Shell script classification
fix resolved internal_dependencies (complete-empty). Authentication
source-audited as empty (auth proxy with 0 registered endpoints). 2
regressions on approved components (mlflow, rhaii-cluster-validation) fixed
with source-audited entries for Kubernetes API internal dependencies. 12
additional components became eligible as side effects.

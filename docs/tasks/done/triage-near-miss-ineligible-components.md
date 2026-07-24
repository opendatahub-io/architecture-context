# Task: Triage Near-Miss Ineligible Components

## Goal

Research and resolve gaps for 3 near-miss ineligible components. These have
narrow blockers that may be tractable with source-audited entries, shell
script classification fixes, or adjudications. Approve any that become
eligible. Document the rest with precise blockers.

## Context

59/90 components are approved for analyzer-only routing. These 3 components
are the closest to eligibility among the remaining ineligible set, each
blocked by a single category.

## Target Components

### llm-d-async — blocked by `authentication`

Checkout: `/data/checkouts/red-hat-data-services.next/llm-d-async/`

Auth has 4 inbound surfaces, 0 auth facts:
- `internal/health/health.go:40` — Go health check endpoint
- `internal/health/health.go:41` — Go health check endpoint
- `docs/guides/e2e-deploy/modelserver/patch-vllm.yaml:1` — documentation
  manifest, likely non-runtime

The docs/guides surface is almost certainly a false positive — documentation
manifests should not count as inbound runtime surfaces. Check whether
`runtimeSurfaceSource()` in `categorycoverage.go:403` excludes `docs/`
directories. If not, this may be a classification fix.

The health.go endpoints are real but may be liveness/readiness probes that
don't require auth. Check what they serve.

Other categories also have gaps (integration_points: shell script + K8s API;
internal_dependencies: shell script) but authentication is the eligibility
blocker. If auth clears, check whether the other gaps also block.

### llm-d-routing-sidecar — blocked by `internal_dependencies`

Checkout: `/data/checkouts/red-hat-data-services.next/llm-d-routing-sidecar/`

Internal dependencies has 2 limitations:
- 1 active platform alias reference: `route.openshift.io` in
  `deploy/openshift/patch-route.yaml` — this is an OpenShift Route
  manifest, likely infrastructure configuration, not a platform dependency
- kustomize `configMapGenerator` not resolved

The `route.openshift.io` reference may be source-auditable as infrastructure
(similar to how Kubernetes API was source-audited for mlflow and
rhaii-cluster-validation).

Note: auth and integration_points also have gaps but are NOT the eligibility
blocker — only internal_dependencies blocks this component.

### workbenches-operator — blocked by `architecture_components`

Checkout: `/data/checkouts/red-hat-data-services.next/workbenches-operator/`

This is an unusual blocker — `architecture_components` is rarely empty.
The category_coverage JSON has no entry for it (status=?, facts=?).
Investigate:
- Is the ANALYZER_ARCHITECTURE.md architecture_components table actually
  empty?
- Was this component previously eligible before the re-extraction?
- Is this a regression from the re-extraction, or was it never eligible?

This component also has gaps in all 3 high-value categories (auth: 4
inbound surfaces; integration: K8s API + shell + kustomize;
internal_deps: 3 platform aliases + kustomize + shell). Even if
architecture_components is fixed, it may still be ineligible.

## Fix Authority

This task has authority to:

1. **Add source-audited empty category entries** to
   `lib/analyzer_correction_adjudications.json`
2. **Fix `categorycoverage.go`** if `runtimeSurfaceSource()` or
   `isSupportOnlyShellScript()` has a classification gap (e.g., `docs/`
   directory not excluded from runtime surface counting). Must include
   unit tests.
3. **Add approvals** to `lib/analyzer_only_approvals.json` for components
   that pass eligibility after fixes
4. **Add platform-delegated auth entries** if appropriate (using the
   mechanism established in the prior task)

## Negative Controls

- Must NOT source-audit `authentication` as empty if real inbound surfaces
  exist and are not accounted for by auth facts
- Must NOT weaken inbound surface counting for legitimate runtime endpoints
- Any `categorycoverage.go` change must pass the full Go test suite and
  a 90-component replay with zero regressions
- Verify with `uv run main.py check-eligibility --platform=rhoai.next`

## Acceptance Criteria

1. Each component has a documented disposition (approved, source-audited,
   or documented with specific remaining blocker)
2. Any Go changes have unit tests
3. 90-component replay: 0 failures, 0 false nominations
4. `check-eligibility` confirms updated counts with zero regressions
5. Validation note written to `docs/notes/`
6. Residual register updated if dispositions change

## Likely Files

| File | Role |
|------|------|
| `src/arch-analyzer/internal/extractor/categorycoverage.go` | `runtimeSurfaceSource()`, `isSupportOnlyShellScript()`, `inboundRuntimeSurfaces()` |
| `src/arch-analyzer/internal/extractor/categorycoverage_test.go` | Unit tests |
| `lib/analyzer_correction_adjudications.json` | Source-audited entries |
| `lib/analyzer_only_approvals.json` | Approvals |
| `docs/notes/analyzer-residual-agent-gaps.md` | Residual register |

## Status

Pending

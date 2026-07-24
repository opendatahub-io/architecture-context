# Task: Extract Go Runtime Source Surfaces

## Goal

Resolve or source-adjudicate the 16 unresolved mutations across 7 Go-based
components by extending existing Go source extractors for patterns not yet
covered: controller-runtime reconciler CRD auth, OIDC/OAuth2 middleware chains,
CLI controller CRD inspection, Go module dependency-with-runtime-import
verification, and Go interface dispatch for typed client operations.

## Context

After the v1 extraction passes (Go HTTP auth, CLI Kubernetes runtime, runtime
servers, managed components), 7 components remain with Go source evidence that
falls outside the existing extraction contracts. These are mostly single-mutation
residuals from patterns that were out of scope for the generic contracts but
are now the blocking gap for analyzer-only approval.

The existing Go source infrastructure in `src/arch-analyzer/internal/gosource/`
has ~30 files covering HTTP mux authentication, controller-runtime metrics,
runtime server lifecycle, managed component extraction, and CLI Kubernetes
patterns. This task extends that infrastructure rather than building new packages.

## Source And Evidence

- Eligibility report:
  `tmp/architecture-corpus-runs/rhoai.next-20260720T173035Z-static/reports/eligibility-v1.json`
- Residual register: `docs/notes/analyzer-residual-agent-gaps.md`
- Prior Go extraction tasks:
  - `docs/tasks/done/extract-go-http-authentication-boundaries.md`
  - `docs/tasks/done/extract-cli-kubernetes-runtime-boundaries.md`
  - `docs/tasks/done/extract-eval-hub-runtime-boundaries.md`

## Target Components

| Component | Mutations | Historical evidence | Pattern |
|-----------|----------:|---------------------|---------|
| `ai-gateway-payload-processing` | 7 | Controller-runtime reconciler with CRD watch; CRD auth enum patterns | Controller-runtime reconciler registration with CRD-defined auth enum values |
| `argo-workflows` | 3 | Go OIDC/OAuth2 middleware; DSP operator config injection; K8s API client auth | OIDC/OAuth2 middleware chain detection in Go HTTP servers |
| `rhaii-cluster-validation` | 2 | CLI controller with CRD inspection and GPU resource discovery | CLI controller component patterns with CRD inspection |
| `eval-hub` | 1 | Go interface dispatch for `KubernetesHelper.GetHardwareProfile` | Go interface dispatch resolution for typed client operations |
| `llm-d-async` | 1 | Go module dependency with runtime import (gateway-api-inference-extension types) | Go module dependency-with-runtime-import verification |
| `llm-d-kv-cache` | 1 | Runtime import (post-adjudication residual from examples/) | Runtime import verification from shipped entrypoint |
| `kube-auth-proxy` | 1 | TokenReview client construction at `pkg/authentication/k8s/tokenreview.go:78-96` | K8s TokenReview client construction and registration |

## Extraction Contracts

1. **Controller-runtime reconciler CRD auth**: Detect controller-runtime
   `Reconcile()` implementations that read CRD spec fields containing auth
   configuration (enum patterns like `AuthMode`, `AuthType`). Emit
   Authentication facts from CRD-defined auth semantics, not just runtime
   middleware.

2. **OIDC/OAuth2 middleware chain**: Detect Go OIDC provider construction
   (`oidc.NewProvider`, `oauth2.Config`) and middleware registration in HTTP
   server chains. Extend existing `mux_authentication.go` to recognize OIDC
   and OAuth2 patterns.

3. **Go module dependency-with-runtime-import**: For components where
   `go.mod` declares a dependency but existing contracts don't detect runtime
   usage, verify that the module is actually imported in shipped source files
   reachable from `main()`. Distinguish test-only imports from production
   imports.

4. **TokenReview client construction**: Detect construction of
   `authenticationv1.TokenReview` objects or `TokenReviewInterface` client
   operations. Extend existing authentication boundary detection.

5. **Go interface dispatch** (stretch): For components like eval-hub where
   GVR operations are behind interface dispatch, consider whether concrete
   type analysis at construction sites can prove reachability without full
   interface resolution.

## Negative Controls

- Must not conflate CRD schema capabilities with runtime enforcement.
- Must not accept OIDC/OAuth2 imports without middleware registration evidence.
- Must not promote test-only module imports as production dependencies.
- Must not accept Go interface dispatch as proof of reachability without
  construction-site evidence.
- Must not accept code comment references as platform dependency evidence.
- Must not accept example/ or docs/ directory source as shipped code.
- Must not accept analyzer baseline output as source evidence.

## Acceptance Criteria

- [ ] Source-audit all mutations for each target component and record invalid
  or overstated rows as explicit adjudications.
- [ ] Resolve or adjudicate all mutations without component-specific exceptions.
- [ ] Add focused positive, conditional, and negative Go tests for each new
  contract.
- [ ] Preserve all existing HTTP, client, component, renderer, and routing tests.
- [ ] Run `go test ./...` and `go vet ./...` in `src/arch-analyzer`.
- [ ] Run Ruff and the Python suite for affected routing/rendering behavior.
- [ ] Run a fresh 90-component replay with zero false nominations and all
  preservation, structural, and synthesis gates passing.
- [ ] Add approval to `lib/analyzer_only_approvals.json` only after the fresh
  replay proves eligibility.
- [ ] Run a bounded one-component production matrix if approval changes routing.
- [ ] Write a validation note, update the residual register, and move this task
  to `docs/tasks/done/`.

## Likely Files

- `src/arch-analyzer/internal/gosource/mux_authentication.go`
- `src/arch-analyzer/internal/gosource/configurable_auth.go`
- `src/arch-analyzer/internal/gosource/managed_components.go`
- `src/arch-analyzer/internal/gosource/constructed.go`
- `src/arch-analyzer/internal/gosource/cli_kubernetes_runtime.go`
- `src/arch-analyzer/internal/gosource/runtime_modules.go`
- `src/arch-analyzer/internal/gosource/clients.go`
- `src/arch-analyzer/internal/gosource/security.go`

## Status

Pending.

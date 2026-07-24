# Task: Resolve Platform-Delegated Authentication Pattern

## Goal

Design and implement a mechanism for the analyzer to account for
platform-delegated authentication — where a component's inbound gRPC (or
HTTP) surfaces are authenticated by infrastructure sidecars (kube-rbac-proxy,
ModelMesh, envoy, istio) rather than by the component's own code. This
pattern blocks 3 components from analyzer-only routing (MLServer, caikit,
caikit-tgis-backend) and applies to similar platform patterns throughout
the ecosystem.

## Context

The `authenticationCoverage()` function in `categorycoverage.go` counts
inbound runtime surfaces (gRPC services, HTTP endpoints, webhooks, ingress
routes, deployment probes) and checks whether each is accounted for by an
`AuthenticationFact`. When a component has real inbound surfaces with no
matching auth facts, the category stays `partial` with a blocking limitation
like "16 inbound runtime surfaces are not fully accounted for by
authentication facts."

For MLServer, caikit, and caikit-tgis-backend, this is a false negative:
authentication IS enforced, but by platform infrastructure external to
the component's source repository:

- **MLServer**: KServe deploys kube-rbac-proxy as a sidecar container that
  intercepts all inbound gRPC traffic before it reaches MLServer. The
  proxy enforces OpenShift OAuth/ServiceAccount token validation. MLServer's
  source code intentionally has no auth middleware.
- **caikit**: ModelMesh orchestrates caikit as a co-located container.
  mmesh.ModelRuntime RPCs are pod-local (localhost between containers).
  External traffic enters through ModelMesh, which handles TLS and auth.
- **caikit-tgis-backend**: Same ModelMesh pattern as caikit, with fewer
  inbound surfaces.

The sidecar/orchestrator configuration lives in operator repos (kserve,
modelmesh-serving), not in these component repos. The analyzer only sees the
component checkout, so it cannot discover the sidecar.

### Prior art

The codeflare-sdk fix (auth signal scan gated on `inboundRuntimeSurfaces()
== 0`) established the pattern of gating auth limitations on surface
context. The credential-reference fix in the triage task extended this.
Both were about components with NO inbound surfaces. This task addresses
the harder case: components WITH real inbound surfaces where auth is
external.

### Existing accounting mechanism

`grpcAuthenticationAccounted()` at `categorycoverage.go:386` already checks
whether a gRPC service has a matching `AuthenticationFact`:
```go
func grpcAuthenticationAccounted(service model.GRPCService, facts []model.AuthenticationFact) bool {
    wanted := normalizeGRPCAuthenticationName(service.Service)
    for _, fact := range facts {
        if strings.EqualFold(strings.TrimSpace(fact.Methods), "gRPC") &&
            normalizeGRPCAuthenticationName(fact.Endpoint) == wanted {
            return true
        }
    }
    return false
}
```

If auth facts with `Methods: "gRPC"` exist for each service, the surfaces
are accounted for and don't count toward the unaccounted total.

## Design Space

Research and evaluate these approaches (or propose alternatives):

### Approach A: Platform auth adjudication entries

Add a new section `platform_delegated_authentication` to
`analyzer_correction_adjudications.json`. Entries specify:
- Component name
- Which inbound surfaces are covered (e.g., "all gRPC", or specific
  service names)
- What mechanism provides auth (e.g., "kube-rbac-proxy sidecar",
  "ModelMesh pod-local")
- Evidence/justification

At extraction time, the analyzer reads these entries and generates synthetic
`AuthenticationFact` records with `mechanism: "platform-delegated"` and
`enforcement_point: "<sidecar>"`, allowing `grpcAuthenticationAccounted()`
to match them.

**Pro:** Uses existing accounting, facts are visible in the output JSON.
**Con:** Requires per-component manual annotation.

### Approach B: GRPCService.Auth field

The `GRPCService` struct already has an `Auth` field (`json:"auth,omitempty"`).
If the analyzer or an adjudication mechanism populates this field with
"platform-delegated" or "kube-rbac-proxy", `inboundRuntimeSurfaces()` could
skip services where `Auth` is non-empty.

**Pro:** Simple, field already exists in the model.
**Con:** The `Auth` field isn't currently populated by extraction.

### Approach C: Source-audited auth posture

Extend `source_audited_empty_categories` to support a new variant:
`platform_delegated_authentication`. Instead of saying "auth is empty and
that's OK," it says "auth is handled externally by named infrastructure."
The eligibility check consumes these to forgive unaccounted inbound surfaces.

**Pro:** Doesn't modify the analyzer binary.
**Con:** Bypasses the accounting mechanism; less principled than generating facts.

### Approach D: Sidecar detection from cross-repo evidence

If the operator repos (kserve, modelmesh-serving) are in checkouts, look
for sidecar injection configuration that references these components.

**Pro:** Fully automated.
**Con:** Complex, fragile, depends on cross-repo checkout availability.

## Research Requirements

Before implementing, the agent must:

1. **Audit all 3 components** — read their `component-architecture.json`
   and source code to understand exactly which inbound surfaces exist and
   why they have no auth facts
2. **Count the surfaces** — how many gRPC services does each have? Are
   any already accounted for? What does the evidence look like?
3. **Check caikit-tgis-backend** — this component wasn't deeply investigated
   in prior tasks. Determine its exact gRPC surface count and auth posture.
4. **Evaluate generalizability** — would the chosen mechanism work for
   future components with the same pattern (e.g., vllm-cpu if it were
   deployed behind envoy)?
5. **Prototype the chosen approach** — implement and verify on all 3
   components before committing

## Prerequisites

The ANALYZER_ARCHITECTURE.md files need to be regenerated before eligibility
can be checked. Run:
```
uv run main.py static-analysis --platform=rhoai.next --force
```
This re-extracts all 90 components and renders ANALYZER_ARCHITECTURE.md
files from the updated component-architecture.json. Verify with
`uv run main.py check-eligibility --platform=rhoai.next` that the 55
previously approved components still show as eligible+approved before
making any changes.

## Negative Controls

- Must NOT remove or weaken inbound surface counting — real unaccounted
  surfaces must still block
- Must NOT hard-code specific component names in the analyzer Go code
- Must NOT add platform-delegated entries for components where auth is
  genuinely missing (vs. externally provided)
- Any new adjudication entries must have verifiable evidence (specific
  sidecar mechanism, deployment pattern)
- Go test suite and 90-component replay must pass with zero regressions

## Acceptance Criteria

1. MLServer, caikit, and caikit-tgis-backend are approved for analyzer-only
   routing
2. The mechanism is documented and generalizable (not ad-hoc per-component)
3. `uv run main.py check-eligibility --platform=rhoai.next` shows updated
   approval count with zero regressions
4. Design decision documented in the validation note
5. Residual register updated with dispositions for all 3 components

## Likely Files

| File | Role |
|------|------|
| `src/arch-analyzer/internal/extractor/categorycoverage.go` | Auth coverage logic, `grpcAuthenticationAccounted()`, `inboundRuntimeSurfaces()` |
| `src/arch-analyzer/internal/extractor/categorycoverage_test.go` | Unit tests |
| `src/arch-analyzer/internal/model/input.go` | `AuthenticationFact`, `GRPCService` struct definitions |
| `lib/analyzer_correction_adjudications.json` | Adjudication/annotation entries |
| `lib/analyzer_only_approvals.json` | Approval additions |
| `lib/architecture_routing.py` | Eligibility check (read-only reference) |
| `docs/notes/analyzer-residual-agent-gaps.md` | Update with dispositions |
| `/data/checkouts/red-hat-data-services.next/MLServer/` | MLServer checkout |
| `/data/checkouts/red-hat-data-services.next/caikit/` | caikit checkout |
| `/data/checkouts/red-hat-data-services.next/caikit-tgis-backend/` | caikit-tgis-backend checkout |

## Status

Pending

# Task: Extract Gateway API Inference Extension EPP Component

## Goal

Convert Gateway API Inference Extension's one remaining source-backed Endpoint
Picker (EPP) architecture component into generic analyzer facts and account for the
repository's constructed ExtProc and health gRPC security surfaces.

## Context

`gateway-api-inference-extension` has one accepted structured correction and costs
$1.1369 and 244.06 agent seconds in the accepted production run. The
`EndpointPickerConfig` API describes plugin-based scheduling, flow control,
saturation detection, and request parsing. The selected InferencePool CRD connects
an `endpointPickerRef` to a Kubernetes Service and defines fail-open or fail-close
behavior.

The analyzer currently reports bounded gaps in `architecture_components` and
`authentication`. Audit found that this is not a configuration-only repository:
`cmd/epp` and `cmd/bbr` construct `ExtProcServerRunner` instances; the runner
registers Envoy's `ExternalProcessor` gRPC service with optional TLS, and separate
health gRPC servers are created without TLS or application authentication.
Conformance manifests account for the apparent HTTPRoute surfaces but are test
fixtures, not deployed inbound endpoints.

## Acceptance Criteria

- [x] Extract a Go gRPC runtime component only when server construction, protobuf
  service registration, and a reachable runtime command or manager runnable
  converge; a Go type, generated registration function, import, or prose mention
  alone is a negative control.
- [x] Correlate the registered `ExternalProcessor` runtime with the structured EPP
  API contract, preserving service identity, referenced kind, failure behavior,
  plugin responsibilities, and exact source evidence when available.
- [x] Do not require the component or repository name to recognize the pattern.
- [x] Extract optional TLS for the ExtProc gRPC service only when the secure-serving
  branch, certificate configuration, credentials, and registered service converge.
- [x] Extract the plaintext or unauthenticated health gRPC surface only when a
  constructed server and health-service registration converge.
- [x] Exclude conformance, test, and example manifests from deployed inbound-surface
  accounting without excluding production manifests selected by runtime overlays.
- [x] Keep dynamic interceptors, unresolved server options, generated-only
  registrations, and credential-bearing code visible as Authentication limitations.
- [x] Resolve or source-adjudicate the 1/1 accepted EPP component correction.
- [x] A 90-component replay has zero false approved nominations and passes all
  preservation, structural, and synthesis gates.
- [x] Run a bounded production-path matrix only if routing changes.

## Files Likely Involved

- `src/arch-analyzer/internal/extractor/crds.go`
- `src/arch-analyzer/internal/gosource/`
- `src/arch-analyzer/internal/model/input.go`
- `src/arch-analyzer/internal/normalize/normalize.go`
- `src/arch-analyzer/internal/extractor/categorycoverage.go`
- `lib/analyzer_only_approvals.json`

## Status

Done

## Baseline Evidence

- Latest replay:
  `tmp/architecture-corpus-runs/rhoai-next-wva-dependencies-static-20260719T134420Z`
- Historical agent cost: $1.1369, 244.06 seconds, 8 reads, 4 source files,
  and 11,433 output tokens.

## Validation

- Full static replay:
  `tmp/architecture-corpus-runs/rhoai-next-gie-epp-static-20260719T143319Z`
- Production-path matrix:
  `tmp/architecture-corpus-runs/rhoai-next-gie-epp-matrix-20260719T144004Z`
- Gateway API Inference Extension resolves 1/1 accepted corrections and becomes the
  29th approved analyzer-only component with zero false nominations.
- The matrix invokes zero agents, retains 91/91 analyzer identities, and passes all
  required gates in 3.45 seconds.
- Full details are in
  `docs/notes/gateway-api-inference-extension-epp-validation-2026-07-19.md`.

# Task: Resolve Go gRPC Residuals

## Goal

Resolve or source-adjudicate the 8 unresolved mutations for
`modelmesh-runtime-adapter`, the only component in the Go gRPC residual
cluster.

## Context

The original modelmesh extraction task
(`docs/tasks/done/extract-modelmesh-runtime-relationships.md`) resolved 6/10
mutations by analyzer and adjudicated 4/10. The 8 remaining mutations
represent gaps that are structurally difficult to resolve:

- **Caller identity**: The adapter registers inbound gRPC services
  (ModelRuntime), but identifying the calling component (ModelMesh) requires
  product-semantic knowledge not derivable from the adapter's source alone.
- **Module self-reference**: The adapter's own `go.mod` module path is
  `github.com/kserve/modelmesh-runtime-adapter`, which is its own module,
  not an import of `modelmesh-serving` packages.
- **Product-semantic naming**: Integration Point naming like "ModelMesh gRPC
  server, inbound" requires knowledge of the product relationship between
  the adapter and ModelMesh.

These are fundamental limitations of deterministic source analysis: the
analyzer can see what the adapter serves and constructs, but cannot determine
who calls it or what product name to assign to the relationship.

## Source And Evidence

- Eligibility report:
  `tmp/architecture-corpus-runs/rhoai.next-20260720T173035Z-static/reports/eligibility-v1.json`
- Residual register: `docs/notes/analyzer-residual-agent-gaps.md`
- Adjudications: `lib/analyzer_correction_adjudications.json`
- Prior task:
  `docs/tasks/done/extract-modelmesh-runtime-relationships.md`
- Validation:
  `docs/notes/modelmesh-runtime-relationships-validation-2026-07-20.md`

## Target Component

| Component | Mutations | Historical evidence |
|-----------|----------:|---------------------|
| `modelmesh-runtime-adapter` | 8 | Proto-defined gRPC registration; go.mod without client construction; storage factory; caller identity |

### Mutation Details

| Category | Key | Adjudication status | Blocker |
|----------|-----|--------------------:|---------|
| `internal_dependencies` | `modelmesh` | Unresolved | Caller-identity knowledge not derivable from adapter source |
| `internal_dependencies` | `modelmesh-serving` | Unresolved | Module path is self-reference, not import of serving packages |
| `integration_points` | `modelmesh grpc server, inbound` | Unresolved | Product-semantic integration point naming |
| `integration_points` | `modelmesh grpc client, outbound` | Unresolved | Test-only client (`mesh_client.go`) not reachable from shipped `main()` |
| *4 additional* | *(from prior adjudicated set or new analysis)* | To audit | Storage provider factory patterns; backend adapter lifecycle |

## Extraction Contracts

1. **Storage provider factory registration**: Detect Go factory patterns
   where a constructor is selected by a configuration enum and the
   constructed client makes outbound calls to a specific service type
   (e.g., S3, PVC, GCS storage).

2. **Backend adapter lifecycle boundaries**: Detect distinct Go adapter
   processes (Triton, TorchServe, MLServer, OVMS) that each implement the
   same gRPC service but wrap different backend runtimes. Emit Architecture
   Component facts per adapter binary.

3. **Caller-identity from deployment correlation** (stretch): If deployment
   manifests show a sidecar or co-located container pattern, infer the
   calling component from the manifest topology. This requires
   cross-source (Go + manifest) correlation.

## Negative Controls

- Must not infer caller identity from the adapter's source alone.
- Must not accept go.mod module path as evidence of a dependency on a
  different project.
- Must not accept test-only client construction as production integration.
- Must not accept product-semantic names without source evidence.
- Must not accept analyzer baseline output as source evidence.

## Acceptance Criteria

- [ ] Source-audit all 8 mutations and record invalid or overstated rows
  as explicit adjudications.
- [ ] Implement extraction contracts for resolvable patterns (storage
  factory, adapter lifecycle).
- [ ] Add unit tests for each new contract.
- [ ] Preserve all existing tests.
- [ ] Run `go test ./...` and `go vet ./...` in `src/arch-analyzer`.
- [ ] Run Ruff and the Python suite for affected routing/rendering behavior.
- [ ] Run a fresh 90-component replay with zero false nominations.
- [ ] Add approval only after the fresh replay proves eligibility.
- [ ] Write a validation note, update the residual register, and move this
  task to `docs/tasks/done/`.

## Likely Files

- `src/arch-analyzer/internal/gosource/grpc_services.go`
- `src/arch-analyzer/internal/gosource/constructed.go`
- `src/arch-analyzer/internal/gosource/runtime_servers.go`
- `src/arch-analyzer/internal/gosource/clients.go`
- `lib/analyzer_correction_adjudications.json`

## Status

Pending.

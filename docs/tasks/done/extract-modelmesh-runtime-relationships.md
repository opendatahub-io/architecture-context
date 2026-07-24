# Task: Extract ModelMesh Runtime Relationships

## Goal

Resolve or source-adjudicate the ten accepted `modelmesh-runtime-adapter`
Integration Point and Internal Platform Dependency corrections using concrete,
runtime-reachable gRPC, backend, and object-storage behavior.

## Context

The historical agent inferred ten relationships from proto definitions and direct
module requirements. Those are discovery leads, not sufficient runtime evidence.
This tranche must separate generated API capability from actual server registration,
client construction, and executed operations across the adapter's shipped binaries.

## Source And Evidence

- Checkout:
  `/data/checkouts/red-hat-data-services.next/modelmesh-runtime-adapter`
- Accepted baseline:
  `tmp/architecture-corpus-runs/rhoai-next-20260718T215431Z`
- Merge report:
  `tmp/architecture-corpus-runs/rhoai-next-inference-gateway-client-static-20260719T165652Z/logs/combined-merges-fresh/modelmesh-runtime-adapter.merge.md`
- Historical agent cost: 226.87 seconds, 8 reads, 4 source files, 11,234 output
  tokens, and $1.0727.

| Category | Accepted identity | Historical evidence quality |
|----------|-------------------|-----------------------------|
| Internal dependency | `ModelMesh` | Proto definition only |
| Internal dependency | `modelmesh-serving` | Module path only |
| Integration | ModelMesh gRPC server, inbound | Proto definition only |
| Integration | ModelMesh gRPC client, outbound | Proto definition only |
| Integration | Triton gRPC client | Proto definition only |
| Integration | TorchServe gRPC client | Proto definition only |
| Integration | MLServer gRPC client | Proto definition only |
| Integration | Google Cloud Storage client | `go.mod` only |
| Integration | Azure Blob Storage client | `go.mod` only |
| Integration | IBM Cloud Object Storage client | `go.mod` only |

Known audit leads include concrete ModelMesh dialing and client creation under
`model-mesh-triton-adapter/triton/mesh_client/mesh_client.go`, and Azure client
construction and operations under `pullman/storageproviders/azure/downloader.go`.
Audit all accepted rows rather than assuming equivalent evidence exists for every
backend.

## Required Contracts

- Start from each shipped command or container entrypoint and build a bounded call
  graph to server registration, client construction, and executed operations.
- Emit inbound ModelRuntime gRPC only when a concrete implementation is registered
  on a running gRPC server. Generated `Register*Server` functions alone are
  insufficient.
- Emit outbound ModelMesh only when a reachable `NewModelMeshClient` is constructed
  from a concrete connection and RPC methods are called.
- Treat Triton, TorchServe, and MLServer as separate backend lifecycles. Require the
  corresponding shipped adapter to construct its backend client and execute calls;
  a copied proto does not prove a relationship.
- Emit object-storage integrations only when a runtime-selected provider is
  registered, constructs the vendor client, and performs list/download operations.
- Derive internal ownership from repository/module/product semantics plus runtime
  behavior. A module path alone does not prove `modelmesh-serving` deployment.
- Keep transport, direction, port, and encryption conservative when source leaves
  them configurable.
- Implement reusable contracts without component-name or repository-path allowlists.

## Negative Controls

Reject generated `.pb.go` declarations without registration or calls, proto files
without runtime use, `go.mod` dependencies without construction, test/example/tool
entrypoints, disconnected client factories, providers registered only in tests,
interface implementations never selected by a shipped lifecycle, copied third-party
APIs, and one backend's evidence projected onto sibling adapters.

## Acceptance Criteria

- [ ] Source-audit all ten historical additions at the accepted checkout revision.
- [ ] Record each row as analyzer-resolved, valid-but-unsupported, or invalid
  historical evidence with exact source locations.
- [ ] Resolve or adjudicate 10/10 accepted corrections without component-specific
  exceptions.
- [ ] Add positive and negative tests for gRPC registration, outbound RPC use,
  backend separation, storage-provider selection, and module/proto-only rejection.
- [ ] Run `go test ./...` and `go vet ./...` in `src/arch-analyzer`.
- [ ] Run Ruff and the Python suite for affected rendering/routing behavior.
- [ ] Run a fresh 90-component replay with zero false nominations and all
  preservation, structural, and synthesis gates passing.
- [ ] Add approval only after replay proves eligibility and all unsupported rows are
  explicitly adjudicated.
- [ ] Run a bounded one-component production matrix if approval changes routing.
- [ ] Write a validation note, update the residual register and goal, and move this
  task to `docs/tasks/done/` only after all applicable gates pass.

## Likely Files

- `src/arch-analyzer/internal/gosource/runtime_graph.go`
- `src/arch-analyzer/internal/gosource/runtime_servers.go`
- `src/arch-analyzer/internal/gosource/service_clients.go`
- `src/arch-analyzer/internal/gosource/runtime_modules.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `src/arch-analyzer/internal/normalize/normalize.go`

## Status

Done. Validation:
[modelmesh-runtime-relationships-validation-2026-07-20](../../notes/modelmesh-runtime-relationships-validation-2026-07-20.md).

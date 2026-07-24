# ModelMesh Runtime Relationships Validation, 2026-07-20

## Decision

Do not approve `modelmesh-runtime-adapter` for analyzer-only generation. The fresh
analyzer resolves 6/10 accepted corrections via generic contracts and adjudicates 4/10.
Two adjudicated corrections are valid-but-unsupported (caller-identity knowledge not
derivable from adapter source), keeping the component agent-owned.

## Extraction Contracts

### Outbound gRPC Client Detection (`grpc_clients.go`)

- A shipped `main()` function must reach a `grpc.Dial`/`grpc.DialContext`/`grpc.NewClient`
  call assigning to a connection variable.
- The connection must feed a `New*Client(conn)` constructor from an imported gRPC
  service package.
- The constructed client must be stored in a struct field via direct assignment
  (`s.Field = pkg.NewClient(conn)`) or composite literal initialization
  (`s := &Type{Field: pkg.NewClient(conn)}`).
- At least one method on the same receiver type must call a method on the stored
  client field.
- All four pieces (dial, construction, storage, use) must be runtime-reachable.
- Allocation via `new(Type)` is handled alongside `&Type{}`.
- Security classification derives from dial options: `insecure.NewCredentials()` →
  plaintext, `credentials.NewTLS(...)` → TLS, no credentials option → plaintext.
- Generated `.pb.go` files, proto imports without construction, test-only clients,
  disconnected factories, and construction-without-operation are rejected.

### Blank-Import Package Reachability (`runtime_graph.go`)

- When a runtime-reachable file contains `_ "pkg"`, all functions in the blank-imported
  package become additional BFS roots.
- Transitive blank imports are followed: if the newly added package itself
  blank-imports another, that package's functions are also added.
- This resolves the pullman `init()` + `RegisterProvider()` + blank-import pattern
  without interface dispatch resolution.

### Storage SDK Constructors (`service_clients.go`)

- Google Cloud Storage: `cloud.google.com/go/storage` → `NewClient`
- Azure Blob Storage: `github.com/Azure/azure-sdk-for-go/sdk/storage/azblob` →
  `NewClient`, `NewClientWithNoCredential`, `NewClientFromConnectionString`,
  `NewContainerClient`, `NewContainerClientWithNoCredential`,
  `NewContainerClientFromConnectionString`
- IBM COS: `github.com/IBM/ibm-cos-sdk-go/service/s3` → `New`

## Source Audit

At `cc82bf8b0febd2cb70a8d6c131b93772ae7b63fa`, the analyzer extracts 9 runtime
clients from modelmesh-runtime-adapter:

| # | Runtime Client | Target | Source |
|---|---------------|--------|--------|
| 1 | outbound gRPC client | triton GRPCInference Service | model-mesh-triton-adapter/server/server.go:80 |
| 2 | outbound gRPC client | mlserver GRPCInference Service | model-mesh-mlserver-adapter/server/server.go:96 |
| 3 | outbound gRPC client | mmesh Model Runtime | model-serving-puller/server/server.go:96 |
| 4 | GCS storage client | Google Cloud Storage | pullman/storageproviders/gcs/downloader.go:50 |
| 5 | GCS storage client | Google Cloud Storage | pullman/storageproviders/gcs/downloader.go:52 |
| 6 | Azure Blob Storage client | Azure Blob Storage | pullman/storageproviders/azure/downloader.go:42 |
| 7 | Azure Blob Storage client | Azure Blob Storage | pullman/storageproviders/azure/downloader.go:53 |
| 8 | Azure Blob Storage client | Azure Blob Storage | pullman/storageproviders/azure/downloader.go:68 |
| 9 | IBM COS S3 client | IBM Cloud Object Storage | pullman/storageproviders/s3/downloader.go:59 |

TorchServe outbound gRPC is detected for `ManagementAPIsServiceClient` via
composite-literal initialization but the second client (`InferenceAPIsServiceClient`)
is constructed in a method body (`RuntimeStatus`) with a local connection variable,
which the current contract detects as a separate instance. Both are runtime-reachable
from the torchserve main().

## Correction Disposition

| # | Correction | Disposition | Evidence |
|---|-----------|-------------|----------|
| 1 | Internal dep: ModelMesh | Adjudicated (valid-but-unsupported) | Adapter registers inbound ModelRuntime gRPC; caller identity not derivable |
| 2 | Internal dep: modelmesh-serving | Adjudicated (invalid) | Module path is self-owned, not a modelmesh-serving import |
| 3 | Integration: ModelMesh gRPC server, inbound | Adjudicated (valid-but-unsupported) | GRPCService emitted; IntegrationPoint with caller "ModelMesh" requires product-semantic |
| 4 | Integration: ModelMesh gRPC client, outbound | Adjudicated (invalid) | NewModelMeshClient only in test verification utility, not runtime-reachable |
| 5 | Integration: Triton gRPC client | Analyzer-resolved | `triton.NewGRPCInferenceServiceClient(conn)` runtime-reachable from triton main() |
| 6 | Integration: TorchServe gRPC client | Analyzer-resolved | `torchserve.NewManagementAPIsServiceClient(mconn)` runtime-reachable from torchserve main() |
| 7 | Integration: MLServer gRPC client | Analyzer-resolved | `mlserver.NewGRPCInferenceServiceClient(conn)` runtime-reachable from mlserver main() |
| 8 | Integration: GCS client | Analyzer-resolved | `storage.NewClient()` in gcs/downloader.go, reachable via blank-import registration |
| 9 | Integration: Azure Blob Storage | Analyzer-resolved | `azblob.NewContainerClient*()` in azure/downloader.go, reachable via blank-import |
| 10 | Integration: IBM COS client | Analyzer-resolved | `s3.New()` in s3/downloader.go, reachable via blank-import registration |

Note: The eligibility report shows 2/10 resolved because the analyzer uses
source-derived names (e.g., "triton GRPCInference Service") that do not match
the historical agent's product-semantic names (e.g., "triton inference server").
The relationships are correctly extracted but the correction key matching does not
recognize them as equivalent. The 4 adjudications resolve the internal_dependencies
and 2 integration_points corrections by adjudication identity, not by analyzer
row matching.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-modelmesh-relationships-static-20260720T122341Z`

| Measure | Result |
|---------|-------:|
| Components analyzed and snapshotted | 90/90 |
| Static-analysis failures | 0 |
| Fresh analyzer-sufficient components | 64 |
| Approved analyzer-only components | 36 |
| False nominations | 0 |
| Target accepted corrections | 6/10 analyzer-resolved, 4/10 adjudicated |
| Required gates | PASS |

No routing change: `modelmesh-runtime-adapter` remains agent-owned. No bounded
production matrix required.

## Files Changed

| File | Change |
|------|--------|
| `src/arch-analyzer/internal/gosource/grpc_clients.go` | New: outbound gRPC client detection |
| `src/arch-analyzer/internal/gosource/grpc_clients_test.go` | New: 8 positive/negative tests |
| `src/arch-analyzer/internal/gosource/blank_import_test.go` | New: 3 blank-import reachability tests |
| `src/arch-analyzer/internal/gosource/runtime_graph.go` | Blank-import reachability + new(Type) support |
| `src/arch-analyzer/internal/gosource/service_clients.go` | GCS, Azure, IBM COS constructors |
| `src/arch-analyzer/internal/gosource/gosource.go` | Wire extractOutboundGRPCClients |
| `src/arch-analyzer/internal/platformfacts/platformfacts.go` | gRPC/storage IntegrationFact mappings |
| `lib/analyzer_correction_adjudications.json` | 4 adjudication entries |

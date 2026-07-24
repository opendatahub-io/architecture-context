# Readiness Routing Coverage Matrix: 2026-07-18

## Purpose

This note records the bounded same-model matrix used to validate the routing fix for
agent-owned structured categories. It does not include `PLATFORM.md` synthesis or
diagram generation.

## Run Provenance

| Field | Value |
|-------|-------|
| Run ID | `rhoai-next-routing-matrix-20260718T192701Z` |
| Platform | `rhoai.next` |
| Model | `opus` |
| Components | `batch-gateway`, `eval-hub`, `odh-dashboard` |
| Workers | 3 |
| Baseline | `architecture/rhoai.next.bak` |
| Run manifest | `tmp/architecture-corpus-runs/rhoai-next-routing-matrix-20260718T192701Z/run.json` |
| Machine report | `tmp/architecture-corpus-runs/rhoai-next-routing-matrix-20260718T192701Z/reports/comparison.json` |
| Markdown report | `tmp/architecture-corpus-runs/rhoai-next-routing-matrix-20260718T192701Z/reports/comparison.md` |

All three checkouts match the revisions recorded by the older fixture:
`batch-gateway` at `fac0c8d8`, `eval-hub` at `50ffb64a`, and `odh-dashboard` at
`f1cdd9f2`.

## Routing Results

| Component | Readiness | Selected structured gaps | Source files |
|-----------|-----------|--------------------------|-------------:|
| `batch-gateway` | partial | architecture components, authentication, integration points, internal dependencies, HTTP, gRPC | 8/8 |
| `eval-hub` | sufficient | architecture components, authentication, internal dependencies | 4/4 |
| `odh-dashboard` | sufficient | none; synthesis-only control | 4/4 |

`batch-gateway` no longer spends its six categories on manifest gaps. `eval-hub`
received a high-value correction budget because its source and semantic surfaces
were partial while those tables were empty. Its guard still prohibited discovery
and limited reads to four analyzer-referenced files. `odh-dashboard` had populated
high-value tables and retained the prior synthesis-only route.

## Source-Adjudicated Coverage

The table below compares the first readiness-routed run with the corrected matrix.
These are valid rows in each generated document, not exact matches to the older
agent-authored fixture.

| Component | Category | Prior rows | Matrix rows | Source-adjudicated change |
|-----------|----------|-----------:|------------:|---------------------------|
| `batch-gateway` | Architecture components | 0 | 3 | API server, processor, and garbage collector entry points |
| `batch-gateway` | Authentication | 0 | 2 | Tenant-header extraction and optional outbound bearer token |
| `batch-gateway` | Integration points | 0 | 5 | PostgreSQL, Redis, S3, OTLP, and inference gateway clients |
| `batch-gateway` | Internal dependencies | 0 | 0 | Negative `None identified` placeholder rejected as a non-fact |
| `eval-hub` | Architecture components | 0 | 3 | API server, metrics server, and Kubernetes helper |
| `eval-hub` | Authentication | 0 | 1 | Required tenant/user identity headers |
| `eval-hub` | Integration points | 4 | 4 | Analyzer facts preserved unchanged |
| `eval-hub` | Internal dependencies | 0 | 2 | HardwareProfile CR and kube-rbac-proxy identity source |
| `odh-dashboard` | Architecture components | 17 | 17 | Control unchanged |
| `odh-dashboard` | Authentication | 7 | 7 | Control unchanged |
| `odh-dashboard` | Integration points | 74 | 74 | Control unchanged |
| `odh-dashboard` | Internal dependencies | 14 | 14 | Control unchanged |

The merge applied 10 high-value structured additions for `batch-gateway` and 6 for
`eval-hub`. Every addition has repository-relative numeric evidence in the archived
change and merge reports. Representative source confirmation includes:

- `batch-gateway` defines three independent processes in `cmd/apiserver/main.go`,
  `cmd/batch-processor/main.go`, and `cmd/batch-gc/main.go`.
- Its request middleware extracts a tenant header but performs no authentication;
  its HTTP client conditionally adds a bearer token for inference requests.
- Its client construction directly initializes PostgreSQL, Redis, file storage, and
  global or per-model inference clients; all processes initialize telemetry.
- `eval-hub` constructs separate API and metrics HTTP servers, rejects requests
  missing configured tenant/user headers, and uses typed/dynamic Kubernetes clients
  for Jobs, ConfigMaps, Secrets, and HardwareProfile resources.

The older fixture remains useful for locating candidates, but it was not accepted as
truth. For example, its `batch-gateway` Kuadrant/Authorino and Gateway API claims were
not restored because the eight-file source budget did not prove them. Conversely,
the new source-backed identities do not necessarily exact-match fixture wording.
The matrix fixture result therefore remains diagnostic: 163/291 structured rows
(56.01%), dominated by the high-fidelity dashboard control.

## Required Gates

| Gate | Result |
|------|-------:|
| Analyzer identities preserved | 390/390 (100.00%) |
| Analyzer-to-final conflicts | 0 |
| Unexplained conflicts | 0 |
| Structurally valid documents | 3/3 |
| Synthesis/structure quality | 3/3 |
| Successful agents | 3/3 |
| Required gates | **PASS** |

The evidence merge also restored nine analyzer HTTP rows that the `batch-gateway`
candidate attempted to replace without exact evidence and rejected 36 unsupported
candidate-only endpoint identities. This confirms that the broader category budget
did not weaken analyzer preservation.

## Execution Cost

| Measure | Result |
|---------|-------:|
| Workflow wall time | 342.48s |
| Static analysis | 1.76s |
| Component generation | 339.53s |
| Collection | 0.75s |
| Tool calls | 66 |
| Read calls | 29 |
| Distinct source files | 16 |
| Input tokens | 23,920 |
| Cache-creation input tokens | 246,690 |
| Cache-read input tokens | 2,770,110 |
| Output tokens | 33,702 |
| Cost | $3.8907 |
| Denied tool calls | 3 |

The same three agents in the earlier production run cost $2.9795 and emitted 22,361
output tokens. The corrected matrix increased cost by 30.58% and output tokens by
50.72%. All three denied calls were blocked nonessential tool attempts; source-file
and discovery bounds held.

## Decision

Another 90-component run is warranted after review of this matrix. The routing bug
is reproduced by tests, the selected components recover source-backed facts in all
four target categories across the matrix, the high-fidelity control is unchanged,
and all preservation and quality gates pass. The next full run should be expected to
cost more than the first readiness-routed run because sparse sufficient components
now receive a bounded correction pass.

# arch-analyzer P1 Runtime/API Inventory Report

## Scope

This checkpoint implements the four P1 demand classes identified in
`docs/notes/partial-run-log-demand-report.md` without reading prior
`architecture/` outputs as synthesis input:

- runtime/component and executable entrypoints;
- API ownership and transport metadata;
- dependency and integration roles;
- literal security-boundary evidence.

## Implemented contract

The analyzer input now carries:

- `entrypoints[]` for Go `main` packages, Python console/server entrypoints,
  and literal Dockerfile `ENTRYPOINT`/`CMD` instructions;
- `security_evidence[]` for direct Go TLS/RBAC/auth imports and Python
  dependency signals, with `literal` versus `dependency-signal` status;
- `owner` and `transport` on HTTP and gRPC facts;
- `role` on Go modules, language packages, internal dependencies, and
  integration facts.

The Markdown renderer exposes these fields in the relevant tables and adds a
separate Security Evidence table. Security-library presence is not promoted to
an endpoint authentication assertion. Unknown and unresolved dynamic behavior
remains visible through `Unknown`, `dependency-signal`, and category-coverage
limitations.

Category-specific coverage now overrides broad language-level routing hints.
For example, a complete deterministic runtime-component contract suppresses
the generic `architecture_components` gap while a partial HTTP contract keeps
the bounded HTTP gap available to the synthesis agent.

## Verification

Sanitized fixture/replay coverage includes:

| Case | Evidence |
|---|---|
| Go operator/controller entrypoint | `internal/gosource/entrypoints_test.go` |
| Go HTTP/gRPC ownership and transport | `internal/gosource/security_evidence_test.go`, existing route/service fixtures |
| Python service entrypoints and security signals | `internal/pythonsource/testdata/entrypoint_app/`, `entrypoints_test.go` |
| Multi-runtime/source normalization | `internal/normalize/normalize_test.go`, `mvp_test.go` |
| Dockerfile runtime commands | `internal/extractor/entrypoints_test.go` |
| Routing contract | `tests/test_architecture_routing.py` |

Commands and results:

```text
GOCACHE=/tmp/arch-analyzer-go-cache go test ./...  PASS
GOCACHE=/tmp/arch-analyzer-go-cache go vet ./...   PASS
.venv/bin/pytest -q tests/test_architecture_routing.py  76 passed
jq empty src/arch-analyzer/schema/component-architecture.schema.json  PASS
```

Replay measurements on sanitized repository fixtures:

| Fixture | New deterministic evidence | Extract time |
|---|---|---:|
| Go source fixture (`internal/gosource/testdata/repository`) | 4 HTTP facts, category coverage for runtime/API/dependency surfaces | 0.07s real |
| Python service fixture (`internal/pythonsource/testdata/entrypoint_app`) | 3 entrypoints, 3 dependency security signals, complete component/auth coverage | 0.10s real |
| Manifest/source fixture (`internal/extractor/testdata/repository`) | 1 runtime component, 1 HTTP fact, 1 Service, 1 internal dependency | 0.07s real |

The pre-change partial-run baseline recorded 97 agent sessions, averaging 7.45
source paths read, 17.28 edits, and 590.7 seconds per component. The current
checkout does not contain the original component checkouts, so a post-change
full synthesis run cannot honestly report comparable agent read/edit/duration
metrics yet. The replay does verify that complete category contracts suppress
the corresponding broad routing gaps and that the new facts survive JSON and
Markdown normalization.

## Remaining limitations

- Dockerfile commands are recorded literally; shell expansion, build-time
  substitution, and workload-to-image joins remain unresolved.
- Go entrypoints are classified from package/import evidence; workload mapping
  remains empty when a manifest join is ambiguous.
- Python dependency security facts are signals only; source-level Python auth
  extraction remains the authority for actual middleware enforcement.
- The dependency role vocabulary is intentionally conservative; unknown
  packages and interactions retain `Unknown` rather than receiving a guessed
  role.
- Dynamic routes, dependency injection, and call graphs remain explicit
  category limitations for the synthesis agent.

No raw logs, transcripts, secrets, API/OTel dumps, or generated architecture
outputs are included in this report or the implementation checkpoint.

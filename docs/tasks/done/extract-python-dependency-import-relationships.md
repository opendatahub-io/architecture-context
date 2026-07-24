# Task: Extract Python Dependency-Import Relationships

## Goal

Build Python import resolution capability to trace `pyproject.toml`
dependencies through actual `import` statements in shipped source, enabling
analyzer-only routing for components whose remaining gaps are Python
dependency declaration and gRPC service registration.

## Context

Four components have 24 unresolved mutations whose evidence relies on Python
import-and-construction patterns: tracing from `pyproject.toml` declared
dependencies through import chains to runtime client construction and gRPC
service registration.

The existing Python source extraction in
`src/arch-analyzer/internal/pythonsource/` uses regex matching from Go. That
works for surface patterns (FastAPI routes, env-var credential sourcing) but
cannot do import resolution or call graph tracing — those require a real
Python AST parser.

## Approach: Python AST Script Called from Go

Rather than building a regex-based Python import resolver in Go, use Python's
own `ast` module to analyze Python source. The Go analyzer shells out to a
Python script that returns structured JSON on stdout — the same pattern the
analyzer uses for `git` operations.

Python's `ast.parse()` parses source without executing it. No virtualenv, no
installed packages, no import simulation. Just static AST walking using only
the Python stdlib (`ast`, `json`, `pathlib`, `tomllib`).

The script (~100 lines) would:

1. Parse `pyproject.toml` to get declared dependencies and optional extras.
2. `ast.parse()` every `.py` file in the component, excluding `tests/`,
   `examples/`, `benchmarks/`, `docs/`.
3. Walk the AST collecting `import` and `from ... import` statements.
4. Cross-reference imports against declared dependencies.
5. Detect gRPC server registration (`grpc.server()`, `add_*_to_server()`).
6. Return JSON classifying each dependency as `used`, `test_only`, or
   `declared_unused`.

The Go analyzer calls `python3 scripts/python_import_analyzer.py <path>`,
parses the JSON response, and emits structured facts through the existing
fact model.

### Why This Works

- The Go analyzer already has language-specific extraction packages
  (`gosource/` uses Go AST, `rustsource/` does Rust, `websource/` does
  TypeScript). Using Python to analyze Python is the natural extension.
- `ast.parse()` is stdlib — zero external dependencies, available everywhere
  Python 3 is installed.
- The interface is clean: Go owns orchestration, rendering, and the fact
  model. Python owns Python AST walking. JSON on stdout is the contract.
- The pipeline already requires Python (routing, rendering, agent runner).

## Source And Evidence

- Eligibility report:
  `tmp/architecture-corpus-runs/rhoai.next-20260720T173035Z-static/reports/eligibility-v1.json`
- Residual register: `docs/notes/analyzer-residual-agent-gaps.md`
- Prioritization: Python dependency cluster in
  `docs/notes/analyzer-remaining-candidate-prioritization-2026-07-19.md`

## Target Components

| Component | Mutations | Evidence quality | Pattern |
|-----------|----------:|------------------|---------|
| `MLServer` | 8 | Weak | gRPC service registration from proto definitions; pyproject.toml dependency-with-import for runtime inference backends |
| `caikit` | 8 | Weak | gRPC service from proto; optional pyproject.toml group analysis for modular runtime backends |
| `kubeflow-sdk` | 5 | Very weak | Python import-and-construction for pyproject.toml optional extras (kfp-kubernetes, kfp-tekton) |
| `codeflare-sdk` | 3 | Weak | Python import-and-construction for pyproject.toml dependencies (ray, kubernetes) |

## Extraction Contracts

1. **Python import-and-construction**: For each dependency declared in
   `pyproject.toml`, verify that the module is actually imported in shipped
   source files reachable from a shipped entrypoint. Distinguish:
   - Required dependencies (always imported)
   - Optional extras (imported behind feature flags or try/except)
   - Development/test dependencies (not shipped)

2. **Optional extras analysis**: Parse `pyproject.toml`
   `[project.optional-dependencies]` groups. For each group, trace which
   modules are imported and determine whether the dependency represents a
   runtime integration or a development tool.

3. **Proto-to-Python gRPC service registration**: Detect proto files
   defining gRPC services and correlate with Python `*_pb2_grpc.py`
   generated modules. Verify that the service is registered in a shipped
   gRPC server (`grpc.server()`, `add_*_to_server()`).

4. **Python call graph from entrypoint**: For shipped entrypoints
   (`console_scripts` in pyproject.toml, `__main__.py`, `app.py`), trace
   the import chain to identify which declared dependencies are actually
   used at runtime vs. available but unused.

## Negative Controls

- Must not accept pyproject.toml declarations as proof of runtime usage.
- Must not conflate optional extras with required dependencies.
- Must not accept test-only or development-only imports as production
  integration.
- Must not accept proto definitions without server registration evidence.
- Must not treat transitive dependencies as direct integration points.
- Must not accept analyzer baseline output as source evidence.

## Acceptance Criteria

- [ ] Python AST script has its own test suite (pytest) with positive and
  negative cases for import resolution, optional extras, gRPC registration.
- [ ] Go integration has unit tests for JSON parsing and fact emission.
- [ ] The 90-component static replay produces zero false nominations.
- [ ] Target components gain structured facts reducing or eliminating their
  empty high-value categories.
- [ ] No non-target component's facts change.
- [ ] Run `go test ./...` and `go vet ./...` in `src/arch-analyzer`.
- [ ] Run Ruff and the Python suite for affected routing/rendering behavior.
- [ ] Add approval only after the fresh replay proves eligibility.
- [ ] Write a validation note, update the residual register, and move this
  task to `docs/tasks/done/`.

## Likely Files

- `src/arch-analyzer/scripts/python_import_analyzer.py` (new — the AST script)
- `src/arch-analyzer/scripts/test_python_import_analyzer.py` (new — pytest)
- `src/arch-analyzer/internal/pythonsource/imports.go` (new — Go exec wrapper + JSON consumer)
- `src/arch-analyzer/internal/pythonsource/pythonsource.go` (wire in import results)
- `src/arch-analyzer/internal/extractor/categorycoverage.go`

## Status

Pending. No longer deferred — the Python AST approach reduces effort from
very high to medium. Can proceed after Tasks 5 and 6, or in parallel.

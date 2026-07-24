# Task: Implement arch-analyzer Rust Source Extraction

## Goal

Prove that the deterministic analyzer can recover useful architecture facts from a
non-Go service by extracting the Rust guardrails corpus at its recorded commit.

## Acceptance Criteria

- [x] Parse Cargo package metadata and direct dependencies with a TOML parser.
- [x] Extract literal Axum routes with methods, handler evidence, and configured
      server ports.
- [x] Represent source-defined Rust binaries and their independently listening
      services.
- [x] Extract configuration-backed downstream HTTP and gRPC connections.
- [x] Recover source-declared TLS, mTLS, token, and header-passthrough controls.
- [x] Preserve file and line evidence and report explicit partial coverage.
- [x] Exclude test source and avoid treating example OpenAPI documents as manifests.
- [x] Add focused fixtures and exact-commit guardrails comparison results.
- [x] Record extraction and rendering time independently.

## Status

Done on 2026-07-17.

## Boundaries

The first Rust pass is syntax- and configuration-based. It does not build Rust code,
expand macros, run procedural derives, or perform type/call-graph analysis. Literal
Axum routes and direct Cargo dependencies are high confidence; conditional routes
remain possible endpoints.

## Results

At guardrails commit `270e5f2`, extraction takes approximately 0.09 seconds and
rendering takes less than 0.01 seconds. The generated Markdown passes structural
validation and retains 42/116 baseline rows (36.21%) with five populated-cell
conflicts.

| Category | Retained |
|----------|---------:|
| Architecture components | 1/1 |
| HTTP endpoints | 12/12 |
| External dependencies | 11/12 |
| Services | 2/2 |
| Egress | 4/7 |
| Secrets | 4/4 |
| Authentication | 3/3 |
| Source files | 5/54 |

The in-repo analyzer retained zero rows before this milestone. The stored upstream
analyzer JSON retained 2/116, so the Rust pass is a material cross-language gain.
Missing rows are concentrated in optional downstream providers not selected by the
example config, semantic integration naming, recent Git history, and files that do
not directly support an emitted structured fact.

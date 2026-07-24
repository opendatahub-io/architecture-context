# Task: Normalize Platform Distribution Parsing

## Goal

Derive the analyzer and skill distribution consistently from platform identifiers so
versioned aliases such as `rhoai.next` never reach component analysis as unsupported
distribution values.

## Context

The static-analysis phase converts `rhoai.next` to `rhoai`, but the component-agent
phase currently passes `rhoai.next` through unchanged. The
`repo-to-architecture-summary` contract accepts only `odh`, `rhoai`, or `both`.
This discrepancy must be fixed before the full `rhoai.next` corpus run.

## Acceptance Criteria

- [x] Introduce one shared platform-to-distribution resolver used by static analysis
      and component architecture generation.
- [x] Resolve `rhoai.next`, versioned `rhoai-*` platforms, and bare `rhoai` to
      `rhoai`.
- [x] Resolve versioned `odh-*` platforms and bare `odh` to `odh`.
- [x] Reject or explicitly handle platform identifiers that cannot map to a supported
      distribution.
- [x] Add focused unit tests for dot-suffixed, hyphen-suffixed, and bare platform
      names.
- [x] Verify generated skill invocations contain only supported distribution values.

## Files Likely Involved

- `lib/cli.py`
- `lib/phases/architecture.py`
- `lib/phases/static_analysis.py`
- `tests/`

## Status

Done on 2026-07-17.

## Notes

`lib.cli.resolve_distribution` is now the shared validated resolver. Both component
generation and static analysis call it before loading platform work. It normalizes
case and whitespace, maps bare, dot-suffixed, and hyphen-suffixed `rhoai` and `odh`
identifiers, explicitly supports `both`, and raises `ValueError` for unsupported
roots.

The regression suite exercises each identifier shape, invalid values, the actual
component-agent prompt produced for `rhoai.next`, and the distribution passed into
the static-analysis worker. `make test-python` passes 26 tests, Ruff passes, all 15
platform configurations pass validation, and all component architecture documents
pass structural validation.

## Related Work

- [Component analyzer migration](../../plans/component-analyzer-migration.md)
- [RHOAI next corpus measurement harness](rhoai-next-corpus-measurement-harness.md)

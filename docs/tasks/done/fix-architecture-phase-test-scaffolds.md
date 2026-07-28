# Task: Fix Architecture Phase Test Scaffolds

## Goal

Make `tests/test_architecture_phase.py` reflect the current
direct-to-architecture generation contract so the full module can be used as a
reliable regression suite again.

## Bug

- `docs/bugs/fixed/architecture-phase-tests-stale-layout-routing-expectations.md`

## Scope

- Replace checkout-local analyzer fixtures with analyzer artifacts under
  `architecture/<platform>/<component>/.analyzer/`.
- Replace checkout-local `GENERATED_ARCHITECTURE.md` assertions with canonical
  `architecture/<platform>/<component>.md` output assertions.
- Replace checkout-local sidecar writes with job-provided `.generation` paths.
- Update route expectations from historical synthesis/allowlist behavior to
  current bounded partial defaults.
- Preserve legacy-route coverage by using missing analyzer artifacts rather
  than obsolete insufficient-readiness behavior.

## Execution record

- Added a `write_analyzer_artifacts()` helper for canonical analyzer fixture
  setup.
- Updated fake agent scaffolds to write through `output_path`, `insight_path`,
  and other job-provided paths.
- Updated force-mode cleanup expectations for direct platform output and
  `.generation` sidecars.
- Updated prompt and routing assertions to current partial-route behavior.
- Narrowed prior-architecture isolation assertions so prompts may reference the
  architecture tree for analyzer/output paths while still not injecting prior
  document content or paths.

## Validation

```bash
uv run ruff check tests/test_architecture_phase.py
uv run pytest -q tests/test_architecture_phase.py
```

Result: `18 passed`.

## Status

Completed 2026-07-28.

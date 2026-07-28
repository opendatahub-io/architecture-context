# Bug: Architecture Phase Tests Have Stale Layout and Routing Expectations

## Summary

`tests/test_architecture_phase.py` no longer reflects the current
direct-to-architecture output layout and analyzer-backed routing defaults.
Running the full file produces scaffold failures even when focused regressions
inside the same module pass.

## Evidence

Observed on 2026-07-28:

```bash
uv run pytest -q tests/test_architecture_phase.py --tb=short
```

Result:

```text
14 failed, 4 passed
```

Representative stale expectations:

- tests still expect `GENERATED_ARCHITECTURE.md` to be preseeded in component
  checkouts, but generation now writes component Markdown directly under
  `architecture/<platform>/<component>.md`;
- tests still expect checkout-local `ARCHITECTURE_CHANGES.md` and insight
  sidecars in some paths, while generation sidecars now live under component
  `.generation` output directories;
- synthesis-route assertions still expect allowlist-specific synthesis behavior,
  but current analyzer-backed generation defaults to bounded partial synthesis;
- skip/force scaffolds mix platform output docs and checkout-local output
  expectations from before the collect phase was removed.

## Expected

The architecture-phase test scaffolds should model the current pipeline
contract:

- analyzer inputs are read from
  `architecture/<platform>/<component>/.analyzer/`;
- source reads remain checkout-scoped;
- generated component Markdown is written directly to
  `architecture/<platform>/<component>.md`;
- generation sidecars are archived from the current `.generation` paths;
- analyzer-backed normal runs use the bounded partial route unless an explicit
  operator override selects legacy.

## Actual

The test file contains a mix of old checkout-local and older synthesis-route
assumptions, causing failures unrelated to the currently exercised regression
logic.

## Impact

Medium. Focused tests can still validate individual fixes, but the stale module
prevents using `tests/test_architecture_phase.py` as a reliable full regression
suite for generation changes.

## Acceptance Criteria

- Update or remove stale checkout-local `GENERATED_ARCHITECTURE.md` assertions.
- Update force/skip scaffolds to use direct platform output paths.
- Update sidecar expectations to match `.generation` archive behavior.
- Update route assertions to current bounded partial defaults.
- `uv run pytest -q tests/test_architecture_phase.py` passes.

## Status

Fixed on 2026-07-28 by
`docs/tasks/done/fix-architecture-phase-test-scaffolds.md`.

Validation:

```bash
uv run ruff check tests/test_architecture_phase.py
uv run pytest -q tests/test_architecture_phase.py
```

Result: `18 passed`.

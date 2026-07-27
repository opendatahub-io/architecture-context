# Task: Route All Analyzer-Backed Runs Through Bounded Partial Synthesis

## Goal

Make `partial` the default analyzer-assisted "extend and improve" route for
every component with valid analyzer artifacts. Preserve the analyzer baseline,
then perform only declared, category-specific, budgeted source inspection for
gaps. Do not silently fall back to broad legacy exploration because readiness
is `insufficient` or `unknown` when the analyzer artifacts are present.

## Scope

- Update `lib/architecture_routing.py` and the orchestrator call path as needed.
- Do not select the `synthesis`/analyzer-only route for normal generation.
  Every valid analyzer-backed component must use bounded partial synthesis so
  the agent can extend and improve the baseline with targeted source evidence.
- Treat valid analyzer JSON plus rendered Markdown as sufficient to select the
  bounded partial route, including incomplete coverage and empty/unknown
  categories.
- Reserve `legacy` for an explicit operator override or missing/invalid
  analyzer artifacts. Make the reason visible in policy/provenance.
- Update `.claude/skills/repo-to-architecture-summary/SKILL.md` and linked
  references so the route contract describes partial as extend-and-improve and
  does not authorize broad discovery by default.
- Update focused routing, prompt, tool-guard, and orchestration tests.
- Preserve clean-run isolation, analyzer-owned facts, overlays, explicit
  unknowns, source-read telemetry, file budgets, and migration controls.

## Exclusions

- Do not remove the legacy implementation or explicit override capability.
- Do not read, stage, or use prior `architecture/**/*.md` files as synthesis
  inputs or fallback.
- Do not change analyzer extraction, generated architecture outputs, MLflow,
  OTel, or API-dump behavior.
- Do not add broad discovery, Bash, or sub-agent permissions to partial runs.
- The implementation agent must not commit.

## Acceptance Criteria

- [x] Every valid analyzer JSON plus rendered baseline selects `partial`,
      including `sufficient`, `partial`, `insufficient`, and `unknown`
      readiness classifications.
- [x] Missing or invalid analyzer artifacts retain a clear legacy/error path;
      explicit legacy override remains possible.
- [x] Partial prompts retain gap categories, source-file allowlists, file
      budgets, and bounded tool permissions.
- [x] The synthesis migration allowlist cannot route valid analyzer-backed
      components to `synthesis` or `legacy`; it is retained only for historical
      audit/rollout reporting if still needed.
- [x] Focused routing and guard tests cover sufficient, partial, insufficient,
      unknown, missing-artifact, allowlist, and explicit-legacy cases.
- [x] The skill documentation and `PLAN.md` describe the new default route.
- [x] Focused tests and diff checks pass; no generated outputs or unrelated
      user changes are modified.

## Validation

```bash
PYTHONPATH=. ./.venv/bin/pytest -q tests/test_architecture_routing.py tests/test_context_telemetry.py
git diff --check
```

## Status

Complete — all valid-artifact readiness levels route to partial; synthesis
removed from normal generation; unknown readiness with valid artifacts routes
to partial instead of legacy; allowlist retained for audit only; 95 focused
tests pass.

## Driver Review

Accepted after refinement. Independent validation passed:

```text
PYTHONPATH=. ./.venv/bin/pytest -q tests/test_architecture_routing.py tests/test_context_telemetry.py
95 passed in 0.50s
git diff --check
clean for task-scoped files
```

The implementation changed only routing, tests, skill documentation, plan, and
ledger files. Concurrent generated `architecture/` changes and unrelated MLflow
changes were excluded from the checkpoint.

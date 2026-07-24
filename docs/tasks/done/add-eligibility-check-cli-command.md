# Task: Add Eligibility Check CLI Command

## Goal

Add a `check-eligibility` subcommand to the CLI that runs the
`analyzer_only_eligibility()` check against all (or specified) components,
always reading from `ANALYZER_ARCHITECTURE.md` in the checkout directories.
This prevents the false-positive class discovered in the batch review, where
ad-hoc checks read `architecture/rhoai.next/<component>.md` files collected
from agent-written `GENERATED_ARCHITECTURE.md`.

## Context

The production routing code at `lib/architecture_routing.py:258` correctly
reads `ANALYZER_ARCHITECTURE.md` from checkout directories. However, there
is no CLI command for running ad-hoc eligibility checks. During the batch
review of 11 newly eligible components, an ad-hoc script read from
`architecture/rhoai.next/` (collected from `GENERATED_ARCHITECTURE.md`),
producing 9 false positives — components that appeared eligible because the
agent had filled categories the analyzer leaves empty.

The false-positive components were: MLServer, caikit, caikit-tgis-backend,
llama-stack-provider-trustyai-garak, pipelines-components, rhoai-mcp,
llm-d-kv-cache, llm-d-routing-sidecar.

## Requirements

### 1. New CLI subcommand

Add a `check-eligibility` subcommand (under the `static-analysis` group
or as a top-level command — follow existing CLI patterns in `lib/cli.py`).

Usage:
```
uv run main.py check-eligibility --platform=rhoai.next [component ...]
```

- If no component args, check all components with checkouts
- If component args provided, check only those
- Must always read `ANALYZER_ARCHITECTURE.md` and `component-architecture.json`
  from the checkout directory (same paths as `load_architecture_agent_policy`)

### 2. Output format

For each component, print a structured line:
```
<component>: eligible=<True|False> reason=<reason> [approved=<True|False>]
```

At the end, print a summary:
```
Checked N components: M eligible, K approved, J newly eligible (not yet approved)
```

### 3. Reuse existing functions

The check MUST call `analyzer_only_eligibility()` from
`lib/architecture_routing.py` — do not reimplement the logic. Also load
source-audited entries via `load_source_audited_empty_categories()` and
approvals via `load_analyzer_only_approvals()`.

The `_baseline_inventory()` function (line 475) extracts `empty_categories`
from the markdown. The JSON is loaded for `category_coverage` data used by
`_complete_empty_categories()` and `_coverage_gap_categories()`.

### 4. Readiness filter

Only check components where the analyzer JSON reports `sufficient` readiness
(same filter as `load_architecture_agent_policy`). Components with other
readiness levels should be skipped with a note.

## Negative Controls

- Must NOT read from `architecture/rhoai.next/` or any collected markdown
- Must NOT read from `GENERATED_ARCHITECTURE.md`
- Must NOT re-implement eligibility logic — call the existing functions
- The command must work without running the full `static-analysis` pipeline
  first (it reads from existing checkout artifacts)

## Likely Files

| File | Role |
|------|------|
| `lib/cli.py` | Add subcommand definition and argument parsing |
| `lib/architecture_routing.py` | Reuse `analyzer_only_eligibility()`, `_baseline_inventory()`, `load_source_audited_empty_categories()`, `load_analyzer_only_approvals()`, `_complete_empty_categories()`, `_coverage_gap_categories()` |
| `lib/manifest_parser.py` | Reuse manifest parsing to enumerate component checkouts |

## Acceptance Criteria

1. `uv run main.py check-eligibility --platform=rhoai.next` runs without error
2. Reports 52 eligible + approved components (matches current approval count)
3. Reports 0 newly eligible components that are false positives (i.e., only
   components whose `ANALYZER_ARCHITECTURE.md` has populated or
   contract-complete empty high-value categories show as eligible)
4. MLServer, caikit, and the other 7 false-positive components from the batch
   review report as NOT eligible
5. No modifications to `architecture_routing.py` logic — only imports/calls

## Status

Done. CLI subcommand implemented in `lib/phases/eligibility.py`, wired via
`lib/cli.py` and `lib/phases/orchestration.py`. Verified: 52 approved, 0 false
positives, all 8 batch-review false positives correctly report ineligible. See
[validation note](../notes/check-eligibility-cli-validation-2026-07-21.md).

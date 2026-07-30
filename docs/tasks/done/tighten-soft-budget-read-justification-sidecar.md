# Task: Tighten Soft-Budget Read Justification Sidecar

## Goal

Ensure agents justify every source file they read when the partial route allows
source reads beyond the old hard file-budget cap.

## Context

The soft-budget replay at
`logs/pipeline/partial-route-soft-budget-replay-20260730T122935Z/generate-architecture/`
validated that replacing hard `budget-exhausted` denials with telemetry reduces
runtime and denied-call retries. It also exposed a sidecar discipline issue:
agents sometimes read extra relevant files but omit them from
`SOURCE_READ_JUSTIFICATIONS.json`.

Observed diagnostics:

| Component | Missing justification paths |
|---|---:|
| `modelmesh` | 4 |
| `odh-gitops` | 4 |
| `pipelines-components` | 1 |

## Plan

1. Inspect the replay candidate/change/sidecar artifacts for the missing-path
   cases.
2. Determine whether the fix belongs in skill text, sidecar validation,
   runtime prompt arguments, or post-run repair.
3. Implement the smallest reusable fix that keeps soft-budget reads but makes
   complete source-read justification more reliable.
4. Validate with focused tests and a targeted replay if needed.

## Acceptance Criteria

- Extra soft-budget source reads are represented in
  `SOURCE_READ_JUSTIFICATIONS.json`.
- Missing-justification diagnostics are reduced or converted into actionable
  repair metadata without hiding the issue.
- The hard file-budget denial does not return.

## Status

Complete.

## Result

- Tightened the repo-to-architecture-summary skill contract so every checkout
  source `Read` must be represented in `SOURCE_READ_JUSTIFICATIONS.json`,
  including soft-budget-overrun reads and reads that prove a fact absent,
  unknown, stale, or unhelpful.
- Added orchestrator repair for observed source reads missing from the sidecar:
  validation now appends conservative `repair: true` records with route gap
  categories where available, writes the repaired sidecar, and records
  `missing-justification-repaired` diagnostics owned by the orchestrator.
- Kept malformed, invalid, and extra sidecar diagnostics warning-only; the
  repair completes telemetry coverage without hiding the omitted-agent-record
  issue.
- Focused validation passed:
  `uv run pytest tests/test_source_read_justifications.py tests/test_architecture_phase.py -q`
  and
  `uv run ruff check lib/source_read_justifications.py lib/phases/architecture.py tests/test_source_read_justifications.py tests/test_architecture_phase.py`.

## Replay Validation

The user-run targeted replay at
`logs/pipeline/partial-route-soft-budget-replay-20260730T143055Z/generate-architecture/`
completed all four slow-tail components successfully. All four reached
`justified_read_ratio = 1.0` with empty `missing_paths` and no
read-justification warnings.

| Component | Observed reads | Justified reads | Repairs | Warnings |
|---|---:|---:|---:|---:|
| `modelmesh` | 7 | 7 | 0 | 0 |
| `notebooks-downstream` | 5 | 5 | 0 | 0 |
| `odh-gitops` | 22 | 22 | 1 | 0 |
| `pipelines-components` | 7 | 7 | 0 | 0 |

`odh-gitops` still omitted one sidecar record for
`charts/rhai-on-openshift-chart/templates/dependencies/rhcl/config.yaml`; the
orchestrator appended a conservative `repair: true` record and emitted
`missing-justification-repaired`. Remaining `odh-gitops` broad-discovery and
oversized-read denials are tracked in
`docs/bugs/open/partial-route-component-runtime-remains-high.md`.

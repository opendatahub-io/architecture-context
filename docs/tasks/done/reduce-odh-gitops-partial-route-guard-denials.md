# Task: Reduce ODH GitOps Partial Route Guard Denials

## Goal

Remove the remaining `odh-gitops` hard guard denials from the targeted
soft-budget replay while preserving the partial route's broad-discovery and
oversized-read protections.

## Context

The sidecar-repair replay at
`logs/pipeline/partial-route-soft-budget-replay-20260730T143055Z/generate-architecture/`
completed all four targeted slow-tail components successfully. Three components
ran with zero denials, but `odh-gitops` still had two hard guard denials:

- root `Glob("*")` against the checkout;
- unbounded whole-file `Read` of
  `charts/rhai-on-openshift-chart/values.yaml` (594 lines).

The agent recovered after both denials by using targeted discovery and bounded
`offset`/`limit` reads, so this is primarily a model-facing guidance/feedback
problem rather than a static-analysis extraction bug.

## Plan

1. Inspect the replay log around both denied calls.
2. Tighten partial-route guidance for Helm/Kustomize repositories so agents use
   targeted chart, template, values, and kustomization patterns first.
3. Make guard denial messages actionable by suggesting bounded retry patterns
   for root Glob and oversized Helm values reads.
4. Validate with focused tests, then ask for a targeted replay.

## Acceptance Criteria

- Partial route still denies full-checkout Glob and unbounded oversized source
  reads.
- Denial messages guide agents toward targeted Helm/Kustomize Glob patterns and
  bounded values-file reads.
- Focused guard tests cover the improved denial feedback.
- A follow-up `custom-test.sh` replay can verify `odh-gitops` hard denials drop
  to zero.

## Status

Accepted 2026-07-30 after the targeted replay at
`logs/pipeline/partial-route-soft-budget-replay-20260730T184005Z/generate-architecture/`.

## Progress

- Inspected
  `logs/pipeline/partial-route-soft-budget-replay-20260730T143055Z/generate-architecture/odh-gitops.log`.
  The agent first attempted root `Glob("*")`, recovered from the denial, then
  later attempted a whole-file read of the 594-line OpenShift chart
  `values.yaml` and recovered with bounded reads.
- Updated the partial-route skill guidance to give Helm/Kustomize-specific
  discovery patterns: `charts/**/Chart.yaml`, `charts/**/values.yaml`,
  `charts/**/templates/**/*.yaml`, `components/**/kustomization.yaml`, and
  `configurations/**/kustomization.yaml`.
- Updated guard denial feedback so root Glob denials suggest targeted
  Helm/Kustomize patterns and oversized source-read denials suggest bounded
  `offset=1, limit=120` top-level reads followed by focused section reads.
- Focused validation passed:
  `uv run pytest tests/test_agent_runner.py -q`,
  `uv run ruff check lib/agent_runner.py tests/test_agent_runner.py`, and
  `python -m py_compile lib/agent_runner.py`.

## Replay Result: 20260730T184005Z

The follow-up targeted replay completed all four components successfully. The
`odh-gitops` run had zero denied calls and no permission-denial records, while
preserving the hard guards and recording soft source/discovery budget telemetry.
Its source-read sidecar covered all 19 observed reads with a 1.0 justified-read
ratio, no missing paths, warnings, or repairs.

The task acceptance criteria are met. The broader partial-route runtime bug
remains open for a separate optimization pass.

## Replay Needed

Run `custom-test.sh` again and inspect the new `odh-gitops.run.json`. Expected
result: `denied_tool_calls_by_category` is empty for `odh-gitops`.

## Replay Result: 20260730T170315Z

The targeted replay at
`logs/pipeline/partial-route-soft-budget-replay-20260730T170315Z/generate-architecture/`
confirmed the first mitigation removed the intended `odh-gitops` categories:
`broad-discovery` and `oversized-source-read` no longer appeared for
`odh-gitops`. The run still had two `workflow-noise` denials:

- `Bash` attempted `ls /data/checkouts/red-hat-data-services.next/odh-gitops/`;
- `Write` attempted to replace the preseeded primary `candidate.md` output
  instead of using targeted `Edit`.

The replay also showed unrelated single oversized-read denials in `modelmesh`
and `notebooks-downstream`; those are outside this `odh-gitops` task unless
they recur in the next replay.

## Second Mitigation

- Updated the `Bash` denial message to tell the agent to use `Read` for known
  files and targeted `Glob`/`Grep` for discovery.
- Updated the preseeded-output `Write` denial message to direct the agent to
  targeted `Edit` on the existing output and reserve `Write` for sidecar
  artifacts.
- Tightened the skill text to explicitly forbid shell-style listing commands
  (`ls`, `find`, `tree`) on partial routes and to require `Edit` rather than
  `Write` for preseeded primary outputs.
- Focused validation passed:
  `uv run pytest tests/test_agent_runner.py -q`,
  `uv run ruff check lib/agent_runner.py tests/test_agent_runner.py`, and
  `python -m py_compile lib/agent_runner.py`.

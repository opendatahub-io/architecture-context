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

Pending.

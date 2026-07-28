# Bug: Partial Run Emits Invalid Insight Applicability Values

## Summary

The latest 97-component `rhoai.next` generation run succeeded, but five
component insight sidecars failed validation because agents emitted
`applicability: "cross-component implication"`.

The insight contract only accepts:

```text
component, cross-component, cross-platform, platform
```

The orchestrator recovered by replacing the invalid insight artifacts with
valid empty artifacts, so component Markdown generation succeeded, but the
affected insights were lost.

## Evidence

From `logs/generate-architecture/*.run.json` in the latest full run:

| Component | Validation error |
|---|---|
| `lm-evaluation-harness` | `insights[0]` used `cross-component implication` |
| `modelmesh` | `insights[3]` used `cross-component implication` |
| `notebooks-downstream` | `insights[2]` used `cross-component implication` |
| `trustyai-service` | `insights[2]` used `cross-component implication` |
| `workbenches-operator` | `insights[0]` used `cross-component implication` |

Each run report recorded `fallback: "empty-artifact"` under `insights`.

## Expected

Agents should emit one of the supported applicability enum values. A claim
with cross-component implications should use `cross-component` and explain the
implication in `reasoning`, not invent a new enum value.

## Actual

The optional insight artifact is rejected and replaced with an empty artifact,
discarding otherwise useful synthesis observations.

## Impact

Medium. Architecture Markdown still succeeds, but the insight sidecar is
missing for affected components and benchmark/telemetry evidence undercounts
cross-component findings.

## Acceptance Criteria

- The insight prompt and examples explicitly forbid descriptive enum variants
  such as `cross-component implication`.
- The validator error message or repair path points agents to the valid enum
  set.
- A regression test covers an agent-produced cross-component implication and
  verifies it is normalized to or rewritten as `cross-component`.
- A full or focused replay produces no `.insights.invalid.json` files for this
  failure mode.

## Status

Fixed on 2026-07-28. The insight contract now lists `cross-component` as a
valid applicability value and explicitly forbids descriptive suffixes.
`lib.insights` repairs the observed `cross-component implication` phrase to
`cross-component` before validation, while unrelated invalid values still fail.
`lib.phases.architecture` archives the normalized typed artifact after
validation so run logs do not preserve the invalid raw value.

Focused validation passed:

```bash
uv run ruff check lib/insights.py lib/phases/architecture.py tests/test_insights.py tests/test_architecture_phase.py
uv run pytest -q tests/test_insights.py tests/test_architecture_phase.py::test_cross_component_implication_applicability_archives_without_fallback
```

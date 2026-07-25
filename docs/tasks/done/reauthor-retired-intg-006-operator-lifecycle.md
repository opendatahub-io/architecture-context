# Task: Re-author Retired Integration Question INTG-006

## Goal

Restore only `INTG-006` with a clean-tree, source-backed operator-lifecycle
integration question, or document it as unresolved.

## Scope and controls

- Read `AGENTS.md`, `PLAN.md`, `agent-driver.md`, this task, the original v1-ab
  INTG-006 record, manifest/audit notes, and clean `architecture/rhoai.next/PLATFORM.md`.
- Do not restore the overlay-only external-operator policy claim. Prefer a
  narrow question about `rhods-operator` managing operator and service
  lifecycle, backed by exact clean source lines such as `PLATFORM.md:119`.
- Do not modify other IDs, raw/scored results, schemas/validators, generated
  architecture docs, overlays, or run evaluation/benchmark. Do not commit.

## Acceptance criteria

- Restore INTG-006 only if every expected claim has exact clean-tree
  `source_file`/`source_line` evidence; otherwise record a precise unresolved
  reason and recovery path.
- If restored, update only task-scoped corpus/manifest/count notes and tests,
  keeping all remaining gaps explicit.
- Run corpus/manifest validators, focused tests, and `git diff --check`.

## Outcome

INTG-006 restored with a narrow question about rhods-operator's lifecycle
management mechanism, backed by clean `architecture/rhoai.next/PLATFORM.md:119`.
The original overlay-only external-operator policy claim was not restored.

**Question**: "How does rhods-operator manage the lifecycle of other platform
operators and services?"

**Expected answer**: "rhods-operator is the platform's meta-operator. It manages
the lifecycle of all other operators and platform services via a DAG-based
provisioning system. Every operator and controller is deployed, configured, and
version-managed by rhods-operator through either in-tree kustomize manifests or
out-of-tree module Helm/kustomize deployments."

**Source evidence**: `architecture/rhoai.next/PLATFORM.md:119` — every claim is
a near-exact paraphrase of the single source line.

The corpus now has 38 active and 2 retired questions. Tier 3 has 10/10 (full).
Remaining gaps are NAV-003 and NAV-006 (Tier 4: 8/10).

## Validation

- `benchmark/analyzer-assisted-v1/validate_corpus.py`: PASS (38 active, 2 retired)
- Focused planner, runner, and manifest tests: 169 passed
- Canary report tests: 87 passed
- Consumer validator: expected failure until the 40-question minimum is restored
- `git diff --check`: PASS

No evaluation or benchmark was run.

## Files changed

- `benchmark/consumer-v1/corpus.json` — added INTG-006 question
- `benchmark/analyzer-assisted-v1/corpus_manifest.json` — INTG-006 active, updated aggregates/gaps
- `tests/test_corpus_manifest.py` — counts 37→38 active, 3→2 retired
- `tests/test_analyzer_assisted_planner.py` — counts 37→38, retired exclusion uses NAV-003/NAV-006
- `tests/test_condition_aware_runner.py` — count 37→38, retired test uses NAV-003
- `docs/bugs/open/corpus-v1-below-minimum-question-count.md` — updated for 38 questions, 2 remaining gaps
- `docs/notes/analyzer-assisted-corpus-baseline.md` — reconciled to 38 active / 2 retired
- `docs/notes/analyzer-assisted-evaluation-contract.md` — reconciled to 38 questions, Tier 3=10
- `docs/plans/analyzer-assisted-agent-architecture.md` — reconciled baseline provenance to 38/2/40

## Limitations

- NAV-003 and NAV-006 remain retired (Tier 4 still 2 short of 10)
- Consumer-v1 schema validation still fails (38 < 40 minItems)
- No evaluation run was performed; scores from the original v1-ab INTG-006 are
  stale (the question was completely re-authored)

## Status

Done — implementation complete, count-sensitive documents reconciled.

# Task: Re-author Retired Integration Question INTG-002

## Goal

Restore only `INTG-002` with a source-backed question, expected answer, and
exact evidence, or document it as unresolved if the repository cannot support
one. This is an incremental step toward the 40-question corpus contract.

## Scope and controls

- Read the original v1-ab artifacts, audit notes, and current architecture
  sources relevant to INTG-002.
- Do not touch any other retired ID, existing result, schema, or validator.
- Do not invent evidence, infer unsupported integration behavior, or run any
  evaluation.

## Acceptance criteria

- [x] INTG-002 is restored only if exact source evidence supports it; otherwise
  the unresolved reason is recorded without changing the corpus.
- [x] Manifest, corpus, focused tests, notes, session log, and PLAN are
  consistent; manifest validation and focused tests pass.
- [x] The remaining Tier-3/Tier-4 shortfall remains explicit; no contract is
  weakened.
- [ ] Task is moved to `docs/tasks/done/` only after review and an accepted
  commit.

## Audit Result (2026-07-24)

**Unresolved — cannot restore.** Two blocking conditions:

1. **Original question out of scope**: The v1-ab question referenced
   `overlays/0011-kserve-llm-d-architecture.md` (the overlay's `affects:` list).
   Overlays are not mounted in the evaluation scope.

2. **Architecture source files have merge conflicts**: All five component docs
   that contain the relevant integration facts (kserve.md, odh-model-controller.md,
   llm-d-inference-scheduler.md, llm-d-router.md, llm-d-kv-cache.md) have
   unresolved merge conflicts from commit `9db926c2`. No reliable `source_line`
   evidence can be established.

**Recovery path**: Resolve the merge conflicts in the rhoai.next architecture
docs, then re-attempt INTG-002 re-authoring with a question about the KServe
LLMInferenceService ↔ llm-d integration sourced from clean architecture files.

## Status

Blocked — unresolved, corpus unchanged. Manifest retirement_reason updated.

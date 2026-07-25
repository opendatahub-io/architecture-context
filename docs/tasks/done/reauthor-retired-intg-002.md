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
- [x] Task is moved to `docs/tasks/done/` only after review and an accepted
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

## Implementation (2026-07-25)

**Restored — re-authored with clean-tree source evidence.**

The original overlay-based question ("Which components does overlay 0011
affect?") referenced `overlays/0011-kserve-llm-d-architecture.md`, which is
outside evaluation scope. After source conflicts were resolved (commit
`c5c8201c`), the five integration documents are clean and provide source-backed
integration facts.

### New INTG-002 question

- **Question**: "What Kubernetes resources does KServe's llmisvc-controller-manager
  create to deploy and configure the llm-d inference scheduler?"
- **Expected answer**: "The llmisvc-controller-manager creates scheduler/EPP
  Deployments using the llm-d router endpoint picker image (parameterized as
  kserve-llm-d-inference-scheduler in params.env), InferencePool resources
  (GIE v1 and v1alpha2) for gateway-aware endpoint selection, and
  VariantAutoscaling CRs from the llm-d.ai API group for GPU-aware workload
  scaling."
- **Source**: `architecture/rhoai.next/kserve.md` line 108
- **Supporting evidence**: kserve.md lines 261 (internal platform dependency),
  307 (EPP image parameterization), 375 (RBAC on llm-d.ai variantautoscalings)
- **Category**: integration (Tier 3), difficulty: advanced, scope: rhoai.next

### Changed files

1. `benchmark/consumer-v1/corpus.json` — added INTG-002 question
2. `benchmark/analyzer-assisted-v1/corpus_manifest.json` — INTG-002 status
   retired→active, updated aggregates and gap counts
3. `benchmark/analyzer-assisted-v1/README.md` — 31→32 active questions
4. `docs/notes/analyzer-assisted-evaluation-contract.md` — 31→32 active,
   9→8 missing questions
5. `docs/tasks/current/reauthor-retired-intg-002.md` — this file

### Corpus count after change

- Total: 32 active, 8 retired (was 31/9)
- Tier 3: 5 active, 5 retired (was 4/6)
- Contract target: 40 (8 remaining)

## Validation (2026-07-25)

### Source evidence verified

| Cited line | Content | Confirms |
|------------|---------|----------|
| kserve.md:108 | llmisvc-controller-manager intent: scheduler/EPP deployments, InferencePools (GIE v1 and v1alpha2), autoscaling (HPA, KEDA, WVA) | Question and expected answer |
| kserve.md:261 | llm-d router/scheduler container image, EPP for gateway-aware LLM scheduling | Internal platform dependency |
| kserve.md:307 | `kserve-llm-d-inference-scheduler` in params.env | EPP image parameterization |
| kserve.md:375 | llmisvc-manager-role RBAC on llm-d.ai variantautoscalings | VariantAutoscaling CRs |

### Validators

| Validator | Result |
|-----------|--------|
| `python3 benchmark/analyzer-assisted-v1/validate_corpus.py` | PASS (40 entries, 32 active, 8 retired) |
| `python3 benchmark/analyzer-assisted-v1/validate.py` | PASS (manifest v1.3.0, 4 available conditions) |
| `python3 benchmark/consumer-v1/validate.py` | 4 pre-existing errors (32 < 40, Tier 3: 5/10, Tier 4: 7/10) |
| `pytest tests/test_corpus_manifest.py tests/test_analyzer_assisted_planner.py tests/test_condition_aware_runner.py` | 168 passed |
| `git diff --check` | PASS |

### Scope check

Only INTG-002 changed in corpus.json and corpus_manifest.json. No other
question IDs, raw results, schema contracts, or architecture docs were modified.

## Status

Validated. Moved to `docs/tasks/done/`.

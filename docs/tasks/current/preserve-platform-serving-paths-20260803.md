# Preserve Platform Serving Paths

## Goal

Prevent platform synthesis from dropping or substituting a distinct serving
path when producing `PLATFORM.md`.

## Plan

1. [x] Add an evidence-derived serving-path completeness pass to the platform
   aggregation skill.
2. [x] Reserve a `Serving Path Evolution` subsection in the platform template.
3. [x] Retarget `custom-test.sh` to a focused platform synthesis replay.
4. [x] Run the focused platform replay and verify that the distinct external-provider,
   multi-model, and model-serving paths are all preserved.
5. [ ] Rescore `INTG-010` and run the consumer benchmark regression check.

## Evidence

The fresh run at
`tmp/evaluations/consumer-v1-rhoai-next-20260803T005702Z/` flagged `INTG-010`:
Tree B's platform document described KServe, LLMInferenceService, and llm-d,
but omitted the separately documented MaaS external-provider path. The same
run also showed two independent benchmark-contract issues (`FACT-003` and
`INTG-004`), which remain separate follow-up work.

The focused replay regenerated and validated `PLATFORM.md` successfully. The
new `Serving Path Evolution` table contains six evidence-backed rows,
including multi-model ModelMesh, KServe, LLM disaggregated serving,
multi-tenant MaaS, external-provider AI Gateway routing, and Inference Graph.
The first one-question evaluator completed, but Tree B still answered the old
"three paths" formulation and omitted MaaS. The generation defect is therefore
fixed; the remaining benchmark work is to evaluate the synchronized six-path
contract rather than preserve the stale three-path wording.
The synchronized rerun at
`tmp/evaluations/consumer-v1-rhoai-next-20260803T153114Z/` reached evaluation
startup but was stopped after the Tree A log remained at its invocation header
for several minutes. The content fix and contract validation pass; agent-side
benchmark confirmation remains blocked on the evaluator hang.

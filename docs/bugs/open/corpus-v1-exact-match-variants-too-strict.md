# Bug: Corpus V1 Exact Match Variants Too Strict

## Summary

At least 5 questions produce correct agent answers that fail exact-match
scoring because the `acceptable_variants` list is too narrow for substring
matching against natural-language responses.

## Affected Questions

| ID | Agent Answer (correct) | Closest Variant | Why It Fails |
|----|------------------------|-----------------|--------------|
| INV-003 | "InstructLab is not a standalone RHOAI component" | "No, InstructLab is not a RHOAI component" | Extra word "standalone" |
| INV-004 | "RHOAI includes a comprehensive Model Registry component" | "Yes, model-registry is a RHOAI component" | "Model Registry" vs "model-registry", "comprehensive" |
| NAV-004 | "No, there is no components/ subdirectory" | "No components/ subdirectory exists" | Different phrasing of the same statement |
| INTG-006 | "No, the platform does not auto-install external operator dependencies" | "No, external operators must be installed by the cluster administrator" | Same meaning, different words |
| INTG-010 | "ModelMesh is Legacy / Being Deprecated" | "Archived upstream, deprecated in RHOAI since 2.19" | Agent lacks the specific version from overlay |

## Root Cause

The scorer (`score_results.py`) checks if any variant string appears as a
substring in the agent response. This works for short factoid answers but
breaks when:

1. The agent uses synonyms or paraphrases ("standalone RHOAI component" vs
   "a RHOAI component")
2. The agent gives a more detailed answer than the variant expects
3. Case differences ("Model Registry" vs "model-registry")

## Impact

MEDIUM — exact match is one of three scoring dimensions (alongside source
citation and gap acknowledgment). These false negatives deflate composite
scores and obscure real quality signals.

## Options

1. **Expand variant lists** — add more acceptable strings per question.
   Cheap but requires re-running the benchmark to validate.

2. **Case-insensitive matching** — reduce one class of false negatives.

3. **LLM-as-judge scoring** — replace substring matching with a small model
   that judges semantic equivalence. Higher quality but adds cost and
   non-determinism.

## Recommendation

Option 1 + 2 for corpus v1.1 (low cost, immediate improvement). Option 3
for v2 if the benchmark becomes a recurring quality gate.

## Status

Open — partially resolved on 2026-07-25. Case-insensitive matching (via
`normalize()`) and the reviewed corpus changes raised exact-match from 15% to
42.5% (tree A) / 40.0% (tree B) when re-scoring v1-ab raw results with the
updated corpus. INV-002 and INV-007 were retargeted as
`not_documented_expected: true` because their source evidence is outside the
architecture evaluation scope.

The remaining work is not an immediate corpus-validity blocker. Remaining
false negatives are in re-authored questions whose raw results answer older
question text, plus complex integration/navigation questions where adding
variants requires a new evaluation run. Phase 2 (LLM-as-judge) remains
deferred.

2026-07-29 update: the clean `consumer-v1` `rhoai.next` rerun at
`20260729T120959Z` reproduced `INV-003` as a current false negative. Tree B
answered that InstructLab has no standalone architecture document but missed
the deterministic accepted phrase and source-citation expectation. Follow-up is
tracked by
`docs/tasks/pending/finish-consumer-v1-scoring-scope-cleanup.md`.

2026-07-29 follow-up update: the `20260729T165013Z` rerun confirms the
remaining scoring cleanup bucket is not a single architecture-generation bug:

- `INV-003` still fails exact match even though the answer says InstructLab has
  no standalone architecture document and explains it is only a dependency /
  backend integration.
- `INV-009` now answers correctly from the new ModelMesh serving runtime table,
  but still fails deterministic exact match because the response also discusses
  KServe's Triton runtime.
- `FACT-008` answers the intended "No" for MLflow per-route auth enforcement
  and reads `mlflow.md`, but fails source citation because the response cites
  lines without naming the expected file.

These rows should be handled by corpus variant expansion, citation-prompt
cleanup, or semantic adjudication rather than new architecture evidence bugs.

2026-07-29 latest rerun update: the full `consumer-v1` rerun at
`20260729T215258Z` still flags `INV-003` as an exact-match regression.
`INV-009` is no longer flagged. `FACT-008` remains in the broader scoring
cleanup bucket because it regressed on source citation and gap acknowledgment,
not exact-match.

2026-07-29 FACT-008 update: `FACT-008` was resolved as
`docs/bugs/fixed/fact008-telemetry-backed-citation-false-negative.md`. The
scorer now accepts source-stem citations when telemetry confirms the expected
basename was read, and it accepts the observed documentation-gap wording.
Re-scoring `20260729T215258Z` produced Tree B overall `0.5583`; `FACT-008` is
no longer flagged. This bug remains open for `INV-003` exact-match cleanup.

2026-07-29 INV-003 update: `INV-003` was resolved as
`docs/bugs/fixed/inv003-instructlab-standalone-doc-exact-match-false-negative.md`.
The corpus now accepts the observed correct phrasing that InstructLab does not
have its own standalone architecture document. Re-scoring `20260729T215258Z`
produced Tree B overall `0.5708`; `report-inv003-rescored.md` reports no
flagged regressions. This broader bug remains open only for historical/general
variant cleanup outside the current flagged `rhoai.next` run.

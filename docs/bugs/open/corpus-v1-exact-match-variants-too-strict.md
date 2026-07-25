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

Partially resolved — 2026-07-25. Case-insensitive matching (via `normalize()`)
and the reviewed corpus changes raised exact-match from 15% to 42.5% (tree A)
/ 40.0% (tree B) when re-scoring v1-ab raw results with the updated corpus. INV-002
and INV-007 retargeted as `not_documented_expected: true` since their source
evidence is outside the architecture evaluation scope. Remaining false
negatives are in re-authored questions (raw results answer different original
questions) and complex integration/navigation questions where adding variants
would require a new evaluation run. Phase 2 (LLM-as-judge) is deferred.

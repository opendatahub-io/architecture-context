# V1 A/B Evaluation Triage — Quality Backlog

Date: 2026-07-20
Source: benchmark/consumer-v1/results/v1-ab/report.md (with regression analysis)
Evaluator: claude-opus-4-6 via Vertex AI, seed 42, $28.25 total cost

## Headline

The v1 A/B evaluation's 15% exact-match rate and 36% composite score are
**primarily benchmark measurement problems, not analyzer quality problems.**
32.5% of questions (13/40) expect answers from files outside the evaluation
scope. Correcting for scope, the architecture-only composite rises to ~48%
(Tree A) with 22% exact match.

## Evaluation Results Summary

- 40 questions, 4 tiers, 5 consumer personas
- Tree A composite: 36.2%, Tree B composite: 33.8% (-2.5pp)
- 38/40 tied, 2 regressions, 0 improvements
- 0 severe errors, 100% gap acknowledgment on both trees

## Per-Question Root Cause Classification

### Group 1: Benchmark Defect — Overlays Not in Evaluation Scope (10 questions)

The `overlays/` directory lives at the repo root. The evaluation mounts only
`architecture/rhoai.next/`. The consumer agent cannot see overlay files.

| ID | Score | Expected Overlay | Agent Behavior |
|----|-------|------------------|----------------|
| INV-005 | 0%/0% | 0004 (CodeFlare SDK) | Found SDK in README, couldn't know about PLATFORM.md inventory gap |
| INV-009 | 0%/0% | 0016 (Triton T&V) | **Incorrectly answered "Yes"** — component data shows Triton runtimes |
| INTG-002 | 0%/0% | 0011 (llm-d arch) | Correctly reported overlays absent from tree |
| INTG-003 | 0%/0% | README.md | Correctly reported overlays absent from tree |
| INTG-004 | 0%/0% | 0011 (llm-d arch) | Good answer from component docs, missed overlay specifics |
| INTG-006 | 0%/0% | 0008 (no auto-install) | Correctly answered "No" from component docs |
| INTG-008 | 0%/0% | 0009 (training hub) | Found 6 components from docs; overlay says 4 |
| INTG-010 | 0%/0% | 0014 (model runtimes) | Correctly identified ModelMesh as deprecated |
| NAV-003 | 0%/0% | README.md | Confused architecture overlays with Kustomize overlays |
| NAV-006 | 0%/0% | README.md | Confused overlay lifecycle with managementState |
| NAV-010 | 0%/0% | 0003 (llama-stack→OGX) | Found rename in component docs, couldn't cite overlay |

**Critical case:** INV-009 is the only question where the agent gives a
factually wrong answer. The component data genuinely shows Triton in runtime
configs. Only overlay 0016 corrects this to "Tested & Verified only." This
is a real analyzer gap — overlay corrections should be synthesized into
component docs.

Filed: docs/bugs/open/corpus-v1-overlay-questions-out-of-scope.md

### Group 2: Benchmark Defect — Source Outside Architecture Tree (3 questions)

| ID | Score | Expected Source | Agent Behavior |
|----|-------|-----------------|----------------|
| INV-002 | 0%/0% | docs/notes/ (analyzer baseline) | Correctly said "not documented in this tree" |
| INV-007 | 0%/0% | docs/notes/ (analyzer routing) | Correctly said "not documented in this tree" |
| NAV-004 | 0%/0% | docs/plans/ (benchmark plan) | Correctly answered "No" but citation mismatch |

These are meta-questions about the analyzer process. The agents behave
correctly.

Filed: docs/bugs/open/corpus-v1-meta-questions-outside-architecture-tree.md

### Group 3: Benchmark Defect — Exact Match Variants Too Strict (overlaps with above)

5 questions with correct answers that fail substring matching:

| ID | Agent Said (correct) | Why Variant Fails |
|----|---------------------|-------------------|
| INV-003 | "not a standalone RHOAI component" | "standalone" is extra |
| INV-004 | "Model Registry component" | Case + phrasing differs |
| INTG-006 | "does not auto-install" | Different words, same meaning |
| INTG-010 | "Legacy / Being Deprecated" | Lacks overlay-specific version |
| NAV-004 | "no components/ subdirectory" | Phrasing differs |

Filed: docs/bugs/open/corpus-v1-exact-match-variants-too-strict.md

### Group 4: Accepted Limitation — Agent Can't See Repo Structure (1 question)

| ID | Score | Issue |
|----|-------|-------|
| NAV-001 | 0%/0% | Asks where `current-ga` symlink points; agent sees only one tree |

**No action.** The single-tree evaluation model is correct for testing
document quality. Repo-structure questions belong in a different test.

### Group 5: A/B Regressions (2 questions, previously classified)

| ID | Delta | Classification | Root Cause |
|----|-------|----------------|------------|
| INV-008 | -50pp | Synthesis difference | Cited diagram instead of PLATFORM.md; same facts |
| FACT-004 | -50pp | Navigation failure | Agent skipped model-registry.md, read only operator doc |

INV-008 is a scoring artifact (no action for analyzer). FACT-004 is agent
non-determinism on identical document trees (no action for analyzer).

### Group 6: Questions at 50% — Source Citation Pass, Exact Match Fail

14 questions scored 50% on both trees: source citation passed but exact match
failed. These are questions where the agent found the right file and gave a
substantively correct answer but didn't match the variant strings. Most of
these are covered by the "variants too strict" bug above or are integration
questions requiring multi-file synthesis that doesn't match terse expected
answers.

**No action for analyzer.** These are benchmark scoring improvements.

## Explicit No-Action Decisions

| Pattern | Decision | Rationale |
|---------|----------|-----------|
| Agent responses are verbose (headers, tables, full context) | No action | Downstream consumers benefit from detail; terseness is a style preference |
| Agent cites different source file than expected (valid alternative) | No action | The agent found a correct source; the scorer is too narrow |
| Agent gives nuanced answer vs expected simple answer (FACT-004, INV-003) | No action | Nuance is correct behavior; exact match is the wrong metric here |
| INV-002, INV-007 meta-questions score 0% | No action | Correctly reported as not documented; these test analyzer knowledge not doc quality |
| NAV-001 repo structure question scores 0% | No action | Agent correctly identifies it can't see parent directory; accepted limitation |
| 100% gap acknowledgment across both trees | No action (positive) | Working as intended; preserve this |

## Ranked V2 Backlog

| Priority | Work Item | Type | Impact | Cost | Filed |
|----------|-----------|------|--------|------|-------|
| 1 | Synthesize overlay content into component docs | Task | 25% of questions affected; fixes only factual error (INV-009) | HIGH | docs/tasks/pending/synthesize-overlay-content-into-component-docs.md |
| 2 | Tag corpus questions by required scope | Task | Separates architecture quality from scope gaps | LOW | docs/tasks/pending/tag-corpus-questions-by-required-scope.md |
| 3 | Improve exact-match scoring accuracy | Task | 5+ false negatives; obscures real signal | LOW-MED | docs/tasks/pending/improve-corpus-v1-scoring-accuracy.md |
| 4 | Fix report generator source_citation check | Bug | 2 regressions invisible in report | LOW | docs/bugs/open/report-generator-misses-source-citation-regressions.md |

## What Is NOT in This Backlog

The following are explicitly out of scope per the task spec:

- **arch-query** improvements — separate workstream, not blocked by these findings
- **Fetch-script consolidation** — infrastructure, not document quality
- **Consumer skill changes** — downstream prompting, not analyzer quality
- **Agent non-determinism** (FACT-004 navigation) — not fixable in the analyzer;
  the document tree is identical, the agent just took a different path

## Adjusted Quality Assessment

If we exclude the 13 out-of-scope questions:

- Architecture-only questions (27): ~48% composite (Tree A), ~22% exact match
- Tier 2 (Component Facts): 67% composite — strongest tier
- Tier 3 (Cross-Component Integration): only INTG-001, INTG-005, INTG-007,
  INTG-009 are in-scope, all at 50% (source citation pass, exact match fail)
- Tier 4 (Navigation): NAV-002, NAV-005, NAV-007, NAV-008, NAV-009 at 50%

The primary gap in the in-scope questions is exact match on integration and
navigation tiers. These are primarily variant-list gaps (benchmark defect),
not analyzer quality gaps. The analyzer documents are substantively correct
and citable for the facts they contain.

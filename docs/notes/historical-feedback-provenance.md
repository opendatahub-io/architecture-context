# Historical Feedback Package Provenance

**Date**: 2026-07-25
**Task**: `docs/tasks/done/reconcile-historical-feedback-provenance.md`

## Package identity

The directory `tmp/feedback-data/` contains a 94-question feedback package
extracted on 2026-07-23 from external pipeline artifacts (OTEL traces, job
logs, JIRA descriptions, and JIRA bot comments). It is git-ignored via the
`tmp/` pattern in `.gitignore` (line 22) and has never been committed to the
repository.

## File inventory and checksums

| File | SHA-256 (first 16 hex) | Lines |
|------|------------------------|------:|
| `corpus/questions.yaml` | `2af2fc0aa2a9ec7b` | 1034 |
| `corpus/baselines/baseline-2026-07-23.yaml` | `327f16c1a146082d` | 191 |
| `corpus/extraction/arch-review-claims.yaml` | `17290d47919591a4` | 11743 |
| `corpus/extraction/feasibility-facts.yaml` | `7da894700a8c7891` | 1950 |
| `corpus/extraction/staff-corrections.yaml` | `e1eef8bc24b61357` | 4963 |
| `corpus/extraction/review-feedbacks.yaml` | `54a84ec535c35038` | 555 |
| `corpus/extraction/revise-semantic-gaps.yaml` | `57b30342ada267eb` | 486 |
| `corpus/extraction/approved-regression-corpus.yaml` | `c9f0d69e0fd4fa38` | 337 |
| `corpus/extraction/testability-gaps.yaml` | `3acc2d701d5ea0fd` | 89 |
| `corpus/extraction/trace-review-scores.yaml` | `7fde70621cd50025` | 252 |
| `experiment-readiness-2026-07-23.yaml` | `e138f13d490e359f` | 43 |
| `component-recommendations-2026-07-23.yaml` | `90fc6d28d6934014` | 210 |
| `improvement-plan-2026-07-23.md` | `3d49069a946fee67` | 488 |

Total: 13 files across `corpus/`, `corpus/extraction/`, and root.

## What the package proves

1. **A 94-question corpus was constructed** from external JIRA and pipeline
   sources on 2026-07-23, covering 11 categories (component_capability: 18,
   integration_pattern: 15, architecture_reference: 12, dependency_chain: 11,
   team_ownership: 8, version_maturity: 7, crd_api_surface: 6,
   rbac_security: 5, deployment_model: 5, upstream_provenance: 4,
   performance_nfr: 3). Category counts in the metadata block sum to 94
   and match the actual question count.

2. **Per-question reviewer verdicts exist** in `questions.yaml`: 81 correct,
   7 corrected, 6 flagged (sums to 94). Each question carries `id`,
   `category`, `question`, `answer`, `source_file`, `source_strategy`,
   `reviewer_verdict`, `difficulty`, `human_review`, and optional
   `human_review_type`.

3. **Extraction provenance is documented**: the improvement plan records
   extraction sources (1,651 architecture claims, 380 dependency facts,
   169 staff corrections, 36 review scores, 65 review feedbacks, 7 gap
   patterns, 38 semantic gaps, 34 confirmed-correct patterns, 15 regression
   assertions) with named JIRA keys and Observatory run IDs.

4. **38 semantic gaps** were catalogued from 7 REVISE-verdict strategies,
   classified as 87% missing context and 13% wrong/stale context, with
   per-gap root cause and recommended fix.

5. **Staff-corrections.yaml** (4,963 lines) documents per-component
   correction frequency from 169 RHAISTRAT issues. This file was already
   consumed by `arch-analyzer harvest-proposals` as a validated fixture
   (see `docs/notes/correction-proposal-harvester.md`).

## What the package cannot prove

1. **The 84% accuracy score is not internally consistent.** The baseline
   file (`baseline-2026-07-23.yaml`) states overall correct=79,
   corrected=8, flagged=5 (sums to 92, not 94 -- 2 questions
   uncategorized). The questions file (`questions.yaml`) contains verdicts
   of correct=81, corrected=7, flagged=6 (sums to 94). The two files
   disagree on correct counts in 5 of 11 categories
   (component_capability, integration_pattern, dependency_chain,
   crd_api_surface, deployment_model) and on human_reviewed counts in 5 of
   11 categories. The baseline's stated accuracy of 79/94 = 84.0% cannot
   be derived from the questions file, which yields 81/94 = 86.2%.

2. **Reproducibility is not possible.** The extraction depends on external
   systems (Observatory REST API on localhost:8000, JIRA MCP tools,
   pipeline data repositories) that are not available in this repository.
   The extraction scripts are not preserved. Re-running the extraction
   would require access to the same JIRA issues, Observatory instance, and
   job trace logs.

3. **Reviewer verdicts are not independently verifiable.** The `correct`,
   `corrected`, and `flagged` verdicts in `questions.yaml` reference JIRA
   strategy keys (e.g., RHAISTRAT-2316) and source files (e.g.,
   `eval-hub.md`), but the JIRA content and review comments that
   established those verdicts are external. There is no durable mapping
   from verdict to the specific JIRA comment or diff that confirmed it.

4. **Human-review counts are inconsistent.** The questions file marks 40
   entries with `human_review: true`; the baseline file claims 45
   human-reviewed entries overall. The per-category human_reviewed counts
   also diverge in 5 of 11 categories.

5. **Category-level accuracy scores are unreliable.** Because per-category
   correct/corrected/flagged counts differ between the two files, the
   per-category accuracy figures in the baseline (e.g., crd_api_surface
   50%, deployment_model 60%, team_ownership 62.5%) cannot be confirmed
   against the questions file.

6. **The package is not the canonical corpus.** The 94-question set has no
   overlap with the verified 40-question consumer-v1 corpus
   (`benchmark/consumer-v1/corpus.json`). The 94 questions use a different
   ID scheme (Q-001..Q-094 vs INV/FACT/INTG/NAV), different categories,
   and different source references. No mapping exists between the two
   corpora.

## Relationship to the plan

The architecture plan (`docs/plans/analyzer-assisted-agent-architecture.md`)
references the 94-question / 84% baseline in its Context section and
Baseline provenance table. The plan already classifies this as:

> **Unverified** -- no 94-question corpus, result set, or evaluation log
> exists in the repository

The corpus manifest (`benchmark/analyzer-assisted-v1/corpus_manifest.json`)
records it under `plan_claim_94q` with `verification_status: "unverified"`.

This provenance note confirms and elaborates that classification: the
feedback package exists in `tmp/feedback-data/` as git-ignored external
evidence. It provides useful directional signal (category weaknesses,
correction patterns, semantic gaps) that informed the plan's design
priorities, but it cannot serve as a reproducible evaluation baseline.

## Relationship to the canonical corpus

The verified evaluation baseline is:

- **40 active questions** in `benchmark/consumer-v1/corpus.json` (v1.0.0),
  all audited against on-disk architecture documentation, with explicit
  answerability status and source evidence.
- **v1-ab scored results** in
  `benchmark/consumer-v1/results/v1-ab/scored-results.json` (40 questions
  evaluated, durable artifact).
- **Corpus manifest** at
  `benchmark/analyzer-assisted-v1/corpus_manifest.json` (v1.1.0) with
  40 active / 0 retired entries and explicit gap accounting for the
  unverified 94-question claim.

The canonical corpus retains explicit unknowns, external-gate language, and
human adjudication/calibration templates with all human fields null. This
provenance note does not alter any of those artifacts.

## Existing consumption of the feedback package

One file from the package (`staff-corrections.yaml`) has already been
consumed as an input fixture by the correction proposal harvester pipeline
(`arch-analyzer harvest-proposals`), documented in
`docs/notes/correction-proposal-harvester.md`. That consumption is
appropriately scoped: the harvester treats the file as extraction input, not
as authoritative ground truth.

## Status

This note is a durable provenance record. It does not promote the feedback
package into the canonical baseline. The feedback files remain git-ignored
and are treated as external evidence with the limitations documented above.

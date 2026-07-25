# Task: Reconcile Historical Feedback Provenance

## Goal

Assess the ignored `tmp/feedback-data/` package against the plan's historical
94-question / 84% baseline claim and create durable provenance without
overstating reproducibility or replacing the canonical 40-question corpus.

## Scope and controls

- Read `AGENTS.md`, `PLAN.md`, `agent-driver.md`, the architecture plan,
  `tmp/feedback-data/corpus/baselines/baseline-2026-07-23.yaml`, the related
  extraction files, and existing baseline notes.
- Validate counts, category totals, source references, file formats, and git
  tracking/ignore status. Treat ignored files as external evidence unless
  copied into a reviewed durable artifact with provenance and limitations.
- Do not run models/evaluations, alter the canonical 40-question corpus, fill
  human adjudication/calibration labels, or create external state.

## Acceptance criteria

- Add a durable provenance note or artifact that records what the feedback
  package proves, what it cannot prove, checksums/inputs where appropriate,
  and why the 94-question score is or is not reproducible.
- Update the plan only if the evidence warrants a narrower, accurate status;
  retain the verified 40-question baseline and explicit unknowns.
- Reconcile `PLAN.md` and session ledger; no generated/application files
  changed; run relevant validators and `git diff --check`; do not commit.

## Status

Done.

## Implementation summary

### Provenance note created

`docs/notes/historical-feedback-provenance.md` records:

- **File inventory**: 13 files with SHA-256 checksums, confirming git-ignored
  status (`.gitignore` line 22, `tmp/` pattern).
- **What the package proves**: 94-question corpus exists with 11 categories,
  per-question verdicts, extraction provenance from named JIRA keys and
  Observatory runs, 38 semantic gaps from 7 REVISE strategies, and
  staff-correction frequency data already consumed by the harvester pipeline.
- **What the package cannot prove**: the 84% accuracy score is internally
  inconsistent (baseline says 79/94 but questions file yields 81/94; 5 of 11
  categories have mismatched counts; human_reviewed 40 vs 45; baseline
  correct+corrected+flagged sums to 92 not 94). Reproducibility requires
  external systems (Observatory, JIRA, pipeline data repos). Reviewer
  verdicts are not independently verifiable. The 94-question set has no
  overlap with the verified 40-question consumer-v1 corpus.

### What was not changed

- The canonical 40-question corpus (`benchmark/consumer-v1/corpus.json`)
- The corpus manifest (`benchmark/analyzer-assisted-v1/corpus_manifest.json`)
- The architecture plan's existing Baseline provenance table (already
  classifies the 94-question claim as "Unverified")
- Application code, schemas, generated output, or external state
- Human adjudication/calibration labels (all remain null)

### Validators run

- `benchmark/consumer-v1/validate.py`: PASS (40 questions)
- `benchmark/analyzer-assisted-v1/validate.py`: PASS (manifest v1.3.0,
  4 conditions)
- `benchmark/analyzer-assisted-v1/validate_corpus.py`: PASS (40 active)
- `git diff --check`: PASS (no whitespace errors)

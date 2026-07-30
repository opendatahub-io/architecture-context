# Consumer Benchmark Corpus v1

A 40-question benchmark for evaluating the quality of `architecture/rhoai.next/`
documentation as consumed by pipeline agents (strategy-review, architecture-review,
security-review, feasibility-review, component-lookup, platform-navigator).

## Structure

```
benchmark/consumer-v1/
├── README.md             # This file
├── schema.json           # JSON Schema (Draft 2020-12) for corpus.json
├── corpus.json           # The 40-question corpus with ground truth
├── validate.py           # Corpus validation (schema, IDs, sources)
├── run_evaluation.py     # Question runner (two trees, randomized order)
├── score_results.py      # Deterministic scorer (exact match, citation, gap)
└── generate_report.py    # Markdown report generator
```

## Tiers

| Tier | Prefix | Name                         | Questions | Tests                                        |
|------|--------|------------------------------|:---------:|----------------------------------------------|
| 1    | INV-   | Inventory                    | 10        | Component existence, counts, product scope   |
| 2    | FACT-  | Component Facts              | 10        | CRDs, ports, languages, deployment types     |
| 3    | INTG-  | Cross-Component Integration  | 10        | Multi-doc reasoning, overlay precedence      |
| 4    | NAV-   | Navigation / Structure       | 10        | Symlinks, directory layout, overlay system   |

## Question Format

Each question includes:

| Field                    | Description                                                    |
|--------------------------|----------------------------------------------------------------|
| `id`                     | Unique ID: `TIER-NNN` (e.g., `INV-001`, `FACT-003`)           |
| `tier`                   | Integer 1-4 matching the tier table above                      |
| `consumer`               | Agent persona that would ask this question                     |
| `question`               | Natural-language question                                      |
| `expected_answer`        | Ground-truth answer from on-disk sources                       |
| `acceptable_variants`    | Alternative phrasings that should also score well              |
| `source_file`            | Repo-relative path to the evidence file                        |
| `source_line`            | Line number or range where evidence appears                    |
| `scope`                  | Product/version scope (`rhoai`, `rhoai.next`, etc.)            |
| `not_documented_expected`| `true` if the correct answer is "not documented"               |
| `required_scope`         | Access scope required for the evidence (`architecture`, `architecture+overlays`, or `full-repo`) |

## Rubric

Responses are scored on four dimensions (1-5 scale):

- **Factual Accuracy** (40%): Does the answer match the docs?
- **Grounding** (20%): Does it cite specific file paths and sections?
- **Scope Awareness** (20%): Does it distinguish product boundaries?
- **Gap Acknowledgment** (20%): Does it handle missing info honestly?

Composite: `(accuracy * 0.4) + (grounding * 0.2) + (scope * 0.2) + (gap * 0.2)`

## Evaluation Pipeline

### 1. Validate the corpus

```bash
python3 benchmark/consumer-v1/validate.py
```

Checks: JSON validity, schema conformance, no duplicate IDs, source file existence,
tier/prefix consistency, and exactly 10 questions per tier.

Requires `jsonschema` for full schema validation (`pip install jsonschema`).
Without it, structural checks still run but schema validation is skipped with a warning.

### 2. Run evaluation

```bash
python3 benchmark/consumer-v1/run_evaluation.py \
  --tree-a architecture/rhoai.next.bak/ \
  --tree-b architecture/rhoai.next/ \
  --model opus \
  --output-dir benchmark/consumer-v1/results \
  --max-concurrent 1
```

For each question, launches two fresh agent sessions (one per tree) with Read/Glob/Grep
tools only. Presentation order is randomized per question (seed=42 by default).
Writes `raw-results.json` with responses, telemetry, and order metadata.

Negative controls enforced:
- Agents cannot read outside their assigned tree (path-sandboxed guard).
- Ground-truth answers are never passed to agents under test.
- Write, Edit, and Bash tools are denied by the evaluation guard.

### 3. Score results

```bash
python3 benchmark/consumer-v1/score_results.py \
  --results benchmark/consumer-v1/results/raw-results.json \
  --corpus benchmark/consumer-v1/corpus.json
```

Computes three deterministic checks per response:
- **Exact match**: response contains expected answer or any acceptable variant
  (case-insensitive substring).
- **Source citation**: response cites the source_file path or its basename.
- **Gap acknowledgment**: for `not_documented_expected` questions, response
  says "not documented" and does not fabricate an answer.

Writes `scored-results.json` with per-question scores and per-tree aggregates
by tier, consumer, and required scope. The machine-readable aggregates include
`primary_overall`, which is restricted to `required_scope: architecture`.

### 4. Generate report

```bash
python3 benchmark/consumer-v1/generate_report.py \
  --scored-results benchmark/consumer-v1/results/scored-results.json
```

Produces `report.md` with:
- Primary architecture-scope summary
- All-question summary, including non-primary diagnostic rows
- Per-tier score tables (tree A vs tree B, paired deltas in percentage points)
- Per-consumer breakdowns
- Per-scope score tables
- Flagged material regressions for primary architecture-scope questions
- Non-primary regression diagnostics for full-repo or other non-primary rows
- Severe errors (failed agent sessions)
- Efficiency comparison (tokens, cost, latency)
- Per-question detail table
- Reproducibility metadata (model, corpus version, git SHA, seed, timestamp)

## Versioning

The corpus uses semantic versioning (`corpus_version` in corpus.json):

- **Patch** (1.0.x): Fix a ground-truth answer or source line reference
- **Minor** (1.x.0): Add questions without removing existing ones
- **Major** (x.0.0): Remove or restructure questions, change schema

Each corpus version is pinned to an `architecture_context_version` (git SHA)
it was validated against. When architecture-context changes:

1. Run `validate.py` to check for broken source file references
2. Update ground truth for any questions whose expected answers changed
3. Bump `corpus_version` accordingly

## Extending the Corpus

To add questions:

1. Add entries to the `questions` array in `corpus.json`
2. Use the next available ID in the appropriate tier prefix sequence
3. Ensure `source_file` and `source_line` point to real, verifiable evidence
4. Run `validate.py` to confirm no errors
5. Bump the minor version in `corpus_version`

Questions derived from fixed bugs (e.g., broken symlinks) should remain as regression
tests but may be tagged separately in score aggregation to avoid inflating tier scores.

## Source Provenance

Questions are sourced from:

- **Smoke test**: 12 questions from `docs/notes/analyzer-migration-v1-baseline-2026-07-20.md`
  (Q1-Q3 -> INV-001/002/007, Q4-Q7 -> FACT-001/002/003/004, Q8-Q10 -> INTG-001/002/003,
  Q11-Q12 -> FACT-005/008)
- **Benchmark design plan**: Worked examples from `docs/plans/architecture-context-benchmark.md`
- **On-disk sources**: Questions derived by reading `architecture/rhoai.next/` docs and `overlays/`

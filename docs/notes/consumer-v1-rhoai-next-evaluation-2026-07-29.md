# Consumer V1 rhoai.next Evaluation — 2026-07-29

## Run

- Raw results:
  `tmp/evaluations/consumer-v1-rhoai-next-20260729T003921Z/raw-results.json`
- Scored results:
  `tmp/evaluations/consumer-v1-rhoai-next-20260729T003921Z/scored-results.json`
- Report:
  `tmp/evaluations/consumer-v1-rhoai-next-20260729T003921Z/report.md`
- Tree A:
  `tmp/architecture-context/architecture/rhoai.next`
- Tree B:
  `architecture/rhoai.next`
- Model: `opus` / `claude-opus-4-6`
- Questions: 40
- Severe errors: 0
- Auth failures: 0

## Result

Tree B scored lower than Tree A on the deterministic consumer-v1 metric:

| Metric | Tree A | Tree B | Delta |
|---|---:|---:|---:|
| Exact match | 17.5% | 15.0% | -2.5pp |
| Source citation | 75.0% | 70.0% | -5.0pp |
| Gap acknowledgment | 75.0% | 75.0% | 0.0pp |
| Composite | 47.5% | 43.8% | -3.7pp |
| Architecture-only composite | 48.2% | 44.1% | -4.1pp |

The report flagged five regression questions:

- `INV-004` — exact match regressed for model registry inclusion.
- `INV-009` — source citation regressed for Triton default runtime evidence.
- `FACT-006` — source citation regressed for
  `fms-guardrails-orchestrator` language.
- `FACT-007` — exact match and source citation regressed for Kueue CRD count.
- `INTG-007` — source citation regressed for model-registry /
  odh-model-controller deployment interaction.

## Interpretation

The run is valid for Claude authentication and scoring: it produced 40 records,
no severe errors, and no `Not logged in` responses.

However, it is not a clean final comparison because Tree B exposed private
generation sidecars under the evaluated architecture tree. At least two
regression answers used non-consumer paths:

- `FACT-007` read `kueue/.analyzer/analyzer_architecture.md` and answered 16
  CRDs, while the expected consumer-facing answer is 11 CRDs from `kueue.md`.
- `INTG-007` read `.generation/merged.md` files instead of the promoted
  component Markdown.

Those paths are implementation artifacts, not authoritative consumer
architecture documents. The benchmark boundary has now been fixed so the
wrapper materializes private-dir-free eval trees and the evaluator guard denies
direct `.analyzer` / `.generation` reads.

## Next action

Rerun `scripts/run_consumer_v1_rhoai_next_eval.sh` after the boundary fix and
treat that rerun as the clean comparison.

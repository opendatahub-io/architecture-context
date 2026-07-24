# Task: Run Analyzer V1 Consumer A/B Evaluation

## Goal

Execute the containerized consumer evaluation harness against the agent baseline
and frozen v1 analyzer output, analyze the results, and produce a permanent
quality report.

## Prerequisites

- [Containerize consumer evaluation harness](../done/containerize-consumer-evaluation-harness.md)
  must be complete (provides `Containerfile`, `run_containerized.sh`).
- [Build consumer evaluation harness](../done/build-consumer-evaluation-harness.md)
  must be complete (provides `run_evaluation.py`, `score_results.py`,
  `generate_report.py`).
- [Build post-migration consumer benchmark](../done/build-post-migration-consumer-benchmark.md)
  must be complete (provides `benchmark/consumer-v1/corpus.json`).

## Inputs

- Container harness: `benchmark/consumer-v1/run_containerized.sh`
- Corpus: `benchmark/consumer-v1/corpus.json` (v1.0.0, 40 questions)
- Tree A (baseline): `architecture/rhoai.next.bak/` (92 agent-generated docs)
- Tree B (v1 candidate): `architecture/rhoai.next/` (90 docs at commit `0920cf3b`)
- Model: Claude Opus 4.6 (via Vertex AI)

## Work

### 1. Build the container image

```bash
benchmark/consumer-v1/run_containerized.sh --build --dry-run \
  --tree-a architecture/rhoai.next.bak \
  --tree-b architecture/rhoai.next
```

Verify the dry-run output looks correct before proceeding.

### 2. Full corpus run

```bash
benchmark/consumer-v1/run_containerized.sh \
  --tree-a architecture/rhoai.next.bak \
  --tree-b architecture/rhoai.next \
  --model opus \
  --output-dir benchmark/consumer-v1/results/v1-ab \
  --seed 42
```

- All 40 questions must complete against both trees.
- The container runs with `--check-isolation` automatically — no host
  memories, no CLAUDE.md, no project settings.
- If any question fails due to infrastructure error, re-run with the same
  seed and investigate the failure.

### 3. Review results

- Scored results and report are generated automatically by the container
  pipeline.
- Review `benchmark/consumer-v1/results/v1-ab/report.md` for:
  - Per-tier score tables with paired deltas.
  - Flagged regressions (tree B lower than tree A on exact match or gap
    acknowledgment).
  - Severe errors (agent sessions that failed entirely).
  - Efficiency comparison (tokens, cost, latency).

### 4. Classify regressions

For every material regression in the report, add a failure classification:

- **extraction gap** — analyzer missed a fact the agent found
- **synthesis difference** — same facts, different phrasing that fails
  exact match (likely a scoring artifact, not a real regression)
- **navigation failure** — agent couldn't find the right file
- **missing component** — tree B has 90 docs vs tree A's 92
  (llama-stack, llama-stack-k8s-operator were renamed/superseded)
- **benchmark defect** — question or expected answer is wrong

Append the classification to the report as a "Regression Analysis" section.

### 5. Cost accounting

- Record total API cost for the full run (expected: 40 questions x 2 trees
  x ~$0.50-1.00 per question = $40-80 range).
- **Ask before proceeding** if the estimated cost exceeds $100.

## Acceptance Criteria

- [ ] All 40 questions run successfully against both document trees or have
  documented infrastructure failures.
- [ ] Container isolation verified (no `.claude/`, no `CLAUDE.md`, no host
  settings — confirmed by `--check-isolation`).
- [ ] Report is reproducible: records model, corpus version, architecture
  context commit, seed, and timestamp.
- [ ] Results distinguish missing facts, synthesis differences, navigation
  failures, missing components, and benchmark defects.
- [ ] Every material regression has a failure classification with evidence.
- [ ] Severe security or scope errors are reported individually, not
  averaged into tier scores.
- [ ] Efficiency comparison (tokens, cost, latency) is included.
- [ ] Permanent report written to `benchmark/consumer-v1/results/v1-ab/`.
- [ ] The task is moved to `docs/tasks/done/` and PLAN.md is updated.

## Status

Pending.

# Task: Build Consumer Evaluation Harness

## Goal

Create a Python evaluation harness that runs benchmark corpus questions against
two architecture-context document trees, captures agent responses with telemetry,
scores them against ground truth, and writes structured results.

## Prerequisites

- [Build post-migration consumer benchmark](build-post-migration-consumer-benchmark.md)
  must be complete (provides `benchmark/consumer-v1/corpus.json`).

## Inputs

- `benchmark/consumer-v1/corpus.json` — 40 questions with ground truth, rubric,
  and source evidence.
- `benchmark/consumer-v1/schema.json` — corpus schema for validation.
- Two architecture-context tree paths (e.g., `architecture/rhoai.next.bak/` and
  `architecture/rhoai.next/`).

## Existing Infrastructure

- `lib/agent_runner.py` — launches Claude SDK agents with tool policies,
  captures telemetry (tool calls, tokens, cost, duration). Built for
  architecture generation, not question-answering. Adapt or wrap, do not
  rewrite.
- `lib/progress.py` — concurrent agent progress display.

## Work

### 1. Question runner (`benchmark/consumer-v1/run_evaluation.py`)

- Accept CLI arguments: `--corpus`, `--tree-a`, `--tree-b`, `--model`,
  `--output-dir`, `--max-concurrent` (default 1).
- For each question in the corpus, run two agent sessions (one per tree)
  using `agent_runner.run_agent`. Each session gets:
  - A system prompt that sets the agent's working directory to the target
    tree and restricts reads to that tree.
  - The question text as the user prompt.
  - Allowed tools: `Read`, `Glob`, `Grep` (read-only, no writes or Bash).
  - `permission_mode: bypassPermissions`.
- Each question is a fresh agent session (no context leakage between
  questions).
- Randomize whether tree A or tree B runs first per question. Record the
  order.
- Capture per-question: agent response text, tool calls, files read, tokens,
  cost, latency, and model ID.
- Write raw results to `<output-dir>/raw-results.json` with corpus version,
  architecture context version, model, timestamp, and per-question entries.

### 2. Deterministic scoring (`benchmark/consumer-v1/score_results.py`)

- Accept `--results` (raw results JSON) and `--corpus` as inputs.
- For each question, compute:
  - **Exact match**: does the response contain the expected answer or any
    acceptable variant (case-insensitive substring match)?
  - **Source citation**: does the response cite the `source_file` path?
  - **Gap acknowledgment**: for `not_documented_expected: true` questions,
    does the response explicitly state the information is not documented
    rather than fabricating an answer?
- Write scored results to `<output-dir>/scored-results.json` with per-question
  deterministic scores and per-tree aggregates by tier and consumer.

### 3. Judge scoring (optional pass)

- Accept `--results` and `--corpus` as inputs.
- For each question-response pair, spawn a judge agent (different model than
  the agent under test, default Sonnet) with:
  - The question, expected answer, source excerpt, and the agent's response.
  - The 4-dimension rubric from `corpus.json`.
  - Instruction: "Score accuracy by comparing against the provided ground
    truth, not by assessing whether the answer sounds reasonable."
- Append judge scores to the scored results JSON.
- The judge pass is separate and optional so the deterministic evaluation can
  run without additional API cost.

### 4. Report generator

- Accept `--scored-results` as input.
- Produce `<output-dir>/report.md` with:
  - Per-tier score tables (tree A vs tree B, paired deltas).
  - Per-consumer breakdowns.
  - Flagged material regressions (any question where tree B scores lower
    than tree A on factual accuracy or gap acknowledgment).
  - Severe errors called out individually, not averaged.
  - Efficiency comparison (tokens, cost, latency).
  - Reproducibility metadata (model, corpus version, commit, timestamp).

## Negative Controls

- The harness must not allow agents to read outside their assigned tree.
- The harness must not pass ground-truth answers to the agent under test.
- The judge must not see which candidate is "baseline" vs "v1".

## Acceptance Criteria

- [ ] `run_evaluation.py` runs 2 questions (1 per tree) end-to-end and
  produces valid `raw-results.json`.
- [ ] `score_results.py` produces `scored-results.json` with deterministic
  scores matching manual inspection of 3 sample questions.
- [ ] Read-only tool policy is enforced (no Write, Edit, or Bash allowed).
- [ ] Agent sessions are isolated (no shared state between questions).
- [ ] Candidate presentation order is randomized and recorded.
- [ ] Report generator produces a readable markdown report from scored results.
- [ ] All scripts have `--help` with documented arguments.
- [ ] The task is moved to `docs/tasks/done/` and PLAN.md is updated.

## Status

Pending.

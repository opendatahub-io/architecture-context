# Iteration Process

This repository improves architecture context through short, evidence-driven
iterations. The goal is not to make one generation run look better. The goal is
to make the analyzer, generation contract, document assembly, and evaluation
system agree well enough that the result remains useful across the full
component corpus.

## The repeatable loop

### 1. Sync the work ledger

Read `PLAN.md`, inspect the current and pending tasks, and review open bugs.
Move the selected task into `docs/tasks/current/` and record the intended
contract change before implementation.

Why: the same symptom can be caused by source extraction, synthesis guidance,
document assembly, or benchmark scoring. The ledger keeps the active hypothesis
and its acceptance criteria visible instead of turning each run into an
untracked prompt tweak.

### 2. Choose one contract or bug

Select a narrowly scoped task, usually from a benchmark regression, analyzer
gap, preservation failure, runtime failure, or repeated agent-log pattern.
State what evidence should change and what must remain unchanged.

Why: broad changes make it impossible to attribute a score change or a
regression to a particular fix. A focused contract also gives us a useful
targeted replay.

### 3. Fix the evidence or contract layer

Prefer deterministic fixes in the lowest layer that owns the problem:

- `src/arch-analyzer/` for missing or incorrectly classified source evidence.
- `.claude/skills/` for synthesis and source-use behavior that is not encoded
  by the analyzer.
- `src/arch-doc/` and pipeline merge logic for section ownership,
  preservation, and document structure.
- benchmark corpora and scoring code only when the expected contract itself is
  stale, ambiguous, or incorrectly scoped.

Avoid component-name-specific rules when path, syntax, metadata, or other
source evidence can express the same fact. Keep generated architecture output
as a validation artifact, not as the implementation source of truth.

Why: hardcoding a known answer can improve one component while reducing
generalization. Layering the fix at the owning boundary gives future components
the same behavior.

### 4. Run focused tests and static validation

Run the smallest relevant unit tests, `go vet` or Python checks as applicable,
and validate any generated document with `arch-doc`. Use `git diff --check`.

Why: these checks catch contract and formatting failures before spending time
on an agent invocation. They also separate implementation errors from model or
network failures.

### 5. Run a targeted pipeline replay

Use `custom-test.sh` or the targeted `pipeline`/`custom` subcommand with the
smallest component and phases that exercise the change. Inspect the run
manifest, agent log, analyzer artifacts, candidate document, merge report, and
final document. Confirm:

- the agent completed successfully;
- the expected analyzer evidence was extracted;
- the final document is structurally valid;
- analyzer-owned sections were preserved;
- rejected changes were stale or unsupported rather than silently lost; and
- source-read budgets and sidecar telemetry are explainable.

Why: a successful process exit is not sufficient. The replay proves that the
new contract survives the real analyzer-to-agent-to-merge path and exposes
connectivity, timeout, guardrail, and budget failures without requiring a full
corpus run.

### 6. Benchmark the affected question set

Run the focused question or domain first. Then run the relevant 40-question
architecture set, the full strategy corpus, or a `rhoai.next` versus
`rhoai.next.bak` comparison when the change has broader impact. Record Tree A,
Tree B, flagged regressions, and the output artifact paths.

Why: targeted replay validates mechanics; benchmark scoring validates whether
the produced context answers the intended questions. Both are required. A
higher overall score does not justify a new regression in an unrelated domain,
and a lower score may reveal a stale corpus contract rather than a generation
bug.

### 7. Reconcile the ledger and commit the attributable change

Update the task with the actual evidence, close or create bugs as appropriate,
append the session log, and move the task to `done/` only when its acceptance
criteria are met. Keep unrelated worktree changes out of the commit. Commit
after the focused fix and its validation are understood.

Why: the task record is the durable explanation for why the change exists and
what remains uncertain. Small attributable commits make regressions bisectable
and allow the benchmark history to be interpreted later.

## How to interpret the results

The loop produces several different signals:

- **Static analyzer tests fail:** the evidence extractor or its contract is
  wrong.
- **Analyzer passes, agent replay fails:** investigate API connectivity,
  credentials, timeouts, guardrails, source-read budgets, or skill instructions.
- **Replay passes but preservation fails:** fix section ownership or merge
  behavior; do not ask the agent to recreate analyzer-owned facts in prose.
- **Replay and preservation pass but benchmark regresses:** inspect the
  question contract, document navigation, citations, and answer variants before
  changing extraction.
- **The benchmark improves but runtime or failure rates worsen:** treat the
  change as incomplete. Quality and operational reliability are both acceptance
  criteria.

Benchmark changes should be interpreted against the same corpus version and
scope. Snapshot-relative inventory questions, rolling navigation questions, and
architecture fact questions measure different properties and should not be
collapsed into one unexplained score.

## Ultimate end goal

The end state is a repeatable pipeline that can process the full supported
component set and produce valid, navigable architecture documents whose factual
sections are grounded in static evidence and whose bounded synthesis adds
useful explanation without overwriting that evidence. The evaluation corpus
should show high answer quality with no unexplained regressions, while pipeline
telemetry makes failures, source coverage, runtime, and model uncertainty
visible.

Until that state is reached, each iteration should reduce one of four gaps:
missing evidence, incorrect synthesis, unsafe document mutation, or inadequate
measurement. The process is successful when improvements generalize beyond the
component and question that first exposed the problem.

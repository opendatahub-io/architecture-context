# Task: Integrate an Evidence-Gated Analyzer Document Merge

## Goal

Make analyzer-owned structured facts deterministic in the final
`GENERATED_ARCHITECTURE.md` while retaining agent-authored synthesis and
source-backed additions or corrections. Prove the workflow on `MLServer` and
`notebooks` before changing the full `rhoai.next` corpus path.

## Context

The first successful full-corpus run produced 90/90 structurally valid documents,
but agents preserved only 5,081/8,192 (62.02%) structured analyzer identities and
made 589 unexplained populated-cell changes. Component generation still took 3,255
seconds because every repository received a full agent pass.

The skill already instructs agents to copy `ANALYZER_ARCHITECTURE.md`, preserve its
tables byte-for-byte, and edit only bounded synthesis or evidenced gaps. Prompt
instructions alone did not enforce that ownership boundary.

`scripts/rebase_architecture_synthesis.py` proves that Purpose, Data Flows, and
Architectural Analysis can be rebased deterministically onto analyzer Markdown. It
is not integrated into component generation and does not yet handle conditional
sections, source-reference union, or evidence-backed structured changes.

The historical evidence and category breakdown are in the
[2026-07-18 corpus comparison](../../notes/rhoai-next-corpus-comparison-2026-07-18.md).

## Decisions

- Markdown remains the input and output contract for agents.
- Analyzer JSON remains internal structured data; agents are not required to read or
  emit JSON.
- `ANALYZER_ARCHITECTURE.md` is the authoritative base for analyzer-owned tables.
- Agent-authored Purpose, Data Flows, and Architectural Analysis are accepted as
  synthesis content, not treated as structured analyzer conflicts.
- Structured additions, corrections, or deletions require an exact change identity,
  reason, and source evidence in a machine-parseable Markdown change record.
- Unrecorded structured rewrites or deletions are not applied to the final document.
- The raw agent candidate and merge decisions must remain available for audit.

## Acceptance Criteria

- [x] Define and document section ownership for analyzer-owned, agent-owned, and
      conditionally merged sections.
- [x] Define a concise Markdown change-record format for structured additions,
      corrections, and deletions. Each entry identifies the section/category, row
      key, affected column or complete-row action, old and new values when applicable,
      reason, and source file with line evidence.
- [x] Parse and validate the change record without requiring the agent to consume or
      produce JSON.
- [x] Preserve a raw copy of the agent candidate before deterministic merging.
- [x] Produce a per-component merge report listing unchanged, applied, rejected, and
      restored changes with their evidence.
- [x] Reuse or extend `rebase_architecture_synthesis` rather than introducing a second
      incompatible section parser.
- [x] Preserve every analyzer structured row and populated cell unless an exact,
      evidence-backed change authorizes modification or deletion.
- [x] Retain evidence-backed candidate-only structured rows without allowing
      unsupported additions into the final document.
- [x] Preserve analyzer and agent change evidence in merge reports and
      generation sidecars without reintroducing final Markdown files-read tables
      or inventing files and line ranges.
- [x] Preserve supported conditional agent sections such as AIPCC Ecosystems Use and
      Sub-Component Details under explicit ownership rules.
- [x] Fail or visibly reject malformed, stale, mismatched, or evidence-free change
      records; never apply them silently.
- [x] Run structural validation after the merge and before a component is reported as
      successful.
- [x] Add focused tests for silent row deletion, silent cell rewrite, unsupported row
      addition, accepted evidence-backed addition, accepted evidence-backed
      correction, synthesis replacement, sidecar-preserved evidence, and
      malformed evidence.
- [x] Add a production opt-in or pilot selector so the merge can be exercised without
      paying for another 90-agent run.
- [x] Run same-revision `MLServer` and `notebooks` pilots and record analyzer
      preservation, fixture recall, populated-cell conflicts, agent tool calls, and
      wall time for the raw and merged candidates.
- [x] Achieve 100% analyzer identity preservation and zero unexplained analyzer cell
      conflicts for both pilot outputs.
- [x] Source-review any raw-candidate structured facts lost by the deterministic merge
      and retain every confirmed fact through an evidence-backed change record.
- [x] Do not enable the merge by default for the full platform until the pilot has no
      unexplained regression in adjudicated structured fixture recall.

## Implementation Plan

### 1. Establish Ownership And Change Contracts

Inventory the canonical Markdown sections and classify each as analyzer-owned,
agent-owned, or conditionally merged. Specify the Markdown evidence record using
stable normalized table identities already understood by the architecture baseline
parser.

### 2. Extend The Deterministic Rebase

Turn the synthesis-only proof into a reusable merge operation. The operation starts
from analyzer Markdown, incorporates allowed agent sections and references, applies
only validated structured changes, and emits both final Markdown and an audit report.

### 3. Integrate A Pilot Path

Hook the merge into component generation after a successful agent run and before
duration metadata or collection. Preserve the raw candidate in the run log tree.
Keep the behavior opt-in and component-selectable during the pilot.

### 4. Verify On Representative Repositories

Use `MLServer` to exercise legitimate enrichment and wording conflicts. Use
`notebooks` to exercise broad dependency inventory and filtering. Compare analyzer,
raw agent, merged candidate, and historical fixture at the same recorded revisions.

### 5. Decide Production Routing

Use the pilot evidence to decide whether `sufficient` repositories can always use
the deterministic merge, whether `partial` repositories need a broader delta budget,
and whether `insufficient` repositories should retain the legacy full-document path.
Record production routing as a follow-up task rather than expanding this pilot.

## Files Likely Involved

- `scripts/rebase_architecture_synthesis.py`
- `lib/phases/architecture.py`
- `lib/architecture_baseline.py`
- `.claude/skills/repo-to-architecture-summary/SKILL.md`
- `tests/test_rebase_architecture_synthesis.py`
- `tests/test_architecture_corpus.py`
- `scripts/compare_architecture_corpus.py`

## Boundaries

- Do not change `PLATFORM.md` synthesis or diagram generation.
- Do not add a new extractor based only on raw corpus fixture recall.
- Do not normalize away source-significant changes such as different RBAC verb
  membership, dependency required-state, authentication mode, or encryption mode.
- Do not require another full paid corpus run for task completion.
- Do not enable analyzer-only output for `partial` or `insufficient` repositories as
  part of this task.

## Dependencies

- [RHOAI next corpus measurement harness](../done/rhoai-next-corpus-measurement-harness.md)
- [Analyzer-generated document fidelity milestone](../../milestones/arch-analyzer-generated-document-fidelity.md)
- [Component analyzer migration plan](../../plans/component-analyzer-migration.md)

## Completion Evidence

- The reusable merge is implemented in `lib/architecture_merge.py`; the existing
  `scripts/rebase_architecture_synthesis.py` parser is now its command-line entry
  point for synthesis-only and evidence-gated modes.
- `generate-architecture --evidence-gated-merge` archives the raw candidate and
  change record, writes Markdown and JSON decision reports, merges, and validates
  before marking a component successful. The full-platform default is unchanged.
- The permanent `MLServer` and `notebooks` evidence fixtures contain 37 and 32
  accepted structured additions. All 73 file-and-line references resolve within the
  source files at the recorded commits.
- Fresh pilot replays preserve 71/71 MLServer and 407/407 notebooks analyzer
  identities with zero conflicts. Structural validation passes for both. Their
  fixture recall remains identical to the raw candidates: 80/102 and 7/72.
- The [pilot report](../../notes/evidence-gated-merge-pilot-2026-07-18.md) records
  source review, rejected assertions, tool calls, reads, cost, agent wall time, merge
  time, commands, and production decision.
- Verification: 62 Python tests, both Go project test suites, Ruff, both Go lint
  targets, 20 overlay validations, 15 platform validations, and 769 architecture
  document validations pass.

## Status

Done on 2026-07-18.

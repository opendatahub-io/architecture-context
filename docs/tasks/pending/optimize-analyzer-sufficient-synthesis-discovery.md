# Task: Optimize Analyzer-Sufficient Synthesis Discovery

## Goal

Make the analyzer-sufficient synthesis route consume pre-seeded analyzer
evidence instead of redundantly rediscovering and rereading the component
repository, while preserving evidence provenance, explicit unknowns, and the
existing partial and legacy route boundaries.

## Context

The first real allowlisted migration completed successfully, but the
`rhoai-mcp` run spent about 600 seconds in 44 agent turns with broad discovery,
16 reads, 14 edits, and 20 denied exploratory calls. The analyzer had already
provided sufficient structured evidence. The generic
`.claude/skills/repo-to-architecture-summary` instructions need a route-aware
execution contract so synthesis does not pay the full legacy exploration cost.

## Scope

- Inspect the synthesis prompt construction, route metadata, agent tool guard,
  and `repo-to-architecture-summary` skill instructions.
- Define and implement an explicit route-aware contract for `synthesis`,
  `partial`, and `legacy`:
  - `synthesis`: use only pre-seeded analyzer facts, declared index/overlay/
    query inputs, and supplied provenance; do not perform broad repository
    discovery or read component source files.
  - `partial`: permit only declared, category-specific source reads, with the
    gap and every read recorded in provenance/telemetry.
  - `legacy`: preserve the current full evidence-gated exploration behavior.
- Remove contradictory generic instructions that cause synthesis to run
  repository-wide discovery, spawn unnecessary exploration, or issue denied
  shell calls.
- Preserve the architecture template’s source-reference contract. Synthesis
  claims must cite supplied analyzer/query/overlay evidence; they must not
  invent source line references when no source read occurred.
- Add focused tests or fixtures proving route-specific prompt/tool behavior and
  that legacy behavior remains unchanged.
- Add a bounded dry-run or fixture evidence record showing route, read/tool
  counts, denied calls, and output validation. Use temporary ignored output
  only; do not modify committed `architecture/` output.

## Explicit exclusions

- Do not change analyzer extraction semantics or analyzer-owned facts.
- Do not weaken merge ownership, reviewed overlays, explicit unknowns, or
  evidence-gated structured changes.
- Do not retire or redesign the legacy route.
- Do not run a paid or full-corpus benchmark.
- Do not commit raw logs, API dumps, OTel payloads, or other potentially
  sensitive temporary artifacts.
- Do not commit; the driver will review and create the checkpoint commit.

## Acceptance criteria

- The route contract is explicit, machine-visible, and covered by focused
  tests for synthesis, partial, and legacy behavior.
- A synthesis prompt/run no longer instructs the agent to broadly enumerate or
  read the component repository when analyzer evidence is sufficient.
- Partial mode retains bounded category-specific reads and records the gap,
  file paths, line ranges where applicable, and evidence provenance.
- Legacy mode retains its existing discovery and evidence-gated behavior.
- Architecture output and insight artifacts remain schema-valid; analyzer-owned
  facts and reviewed overlays are unchanged.
- A fixture or dry-run evidence record demonstrates reduced exploratory calls
  or denied calls for synthesis without claiming a benchmark speedup.
- Focused tests, validators, and `git diff --check` pass.
- The task records exact commands, artifacts, route outcomes, telemetry,
  limitations, and any pre-existing failures in its implementation record.

## Required implementation evidence

- Files changed and why each is route-scoped.
- Focused test and validator commands with results.
- Before/after or fixture telemetry for tool calls, reads, denied calls, and
  elapsed time where available.
- Confirmation that no committed `architecture/` output or raw temporary data
  was added.


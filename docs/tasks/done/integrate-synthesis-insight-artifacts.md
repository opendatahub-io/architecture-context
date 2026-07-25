# Task: Integrate Synthesis Insight Artifacts

## Goal

Connect the existing bounded `InsightArtifact` contract to the actual
component synthesis execution path so agent-derived patterns, trade-offs,
risks, and cross-component implications are emitted as separately validated,
non-authoritative artifacts.

## Scope

- Update `.claude/skills/repo-to-architecture-summary/SKILL.md` with an explicit
  `--insights-output` handoff: write a versioned JSON `InsightArtifact`, cite
  exact evidence, keep unknown/not-extracted states explicit, and allow a valid
  empty artifact when no supported insight is evidenced.
- Update `lib/phases/architecture.py` to pass the artifact path for synthesis
  and partial routes, validate it with `lib.insights`, archive it beside the
  run report, and expose validation/path metadata without merging it into
  analyzer-owned Markdown.
- Preserve analyzer-only and legacy behavior, source-read restrictions,
  evidence-gated merge behavior, and existing output compatibility.
- Add focused tests for prompt wiring, valid/empty artifact handling, invalid
  artifact failure, archival/report metadata, and non-promotion into Markdown.

## Negative controls

- Do not run paid/full-corpus evaluations or launch production agents.
- Do not modify generated architecture output, analyzer facts, overlays,
  manifests, query behavior, or the `InsightArtifact` schema contract.
- Do not merge insights into analyzer-owned tables or authoritative Markdown.
- Do not fabricate insight claims or provenance.

## Acceptance criteria

- [x] Synthesis/partial jobs receive an explicit insight-artifact output path.
- [x] Valid and empty artifacts are validated and archived; invalid/missing
  artifacts fail the bounded synthesis result with an explicit reason.
- [x] Run reports expose artifact path/validation metadata while Markdown stays
  governed by the existing merge boundary.
- [x] Focused tests, lint, task note, session log, PLAN, and accepted scoped
  commit are recorded.

## Status

Implementation complete; accepted after focused review and validation.

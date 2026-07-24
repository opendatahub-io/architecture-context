# Task: Integrate the Local arch-analyzer Pipeline

## Goal

Replace the runtime dependency on the cloned upstream analyzer and make the local
analyzer's canonical Markdown the primary input to the component-summary agent.

## Acceptance Criteria

- [x] Build `src/arch-analyzer` into `bin/arch-analyzer` from the Python pipeline.
- [x] Remove the dynamic upstream clone/build fallback.
- [x] Pass explicit JSON output and distribution arguments to extraction.
- [x] Retry automatic overlay selection when a repository has no matching product
      overlay.
- [x] Preserve the existing `extract-schema` contract with structured CRD schema
      extraction.
- [x] Render `ANALYZER_ARCHITECTURE.md` for agents after static analysis.
- [x] Include explicit extractor coverage in the Markdown baseline.
- [x] Make the summary skill preserve analyzer facts and prohibit broad exploration
      and sub-agents when the baseline exists.
- [x] Add Python contract tests and run an end-to-end async fixture smoke test.

## Status

Done on 2026-07-17.

## Results

The async production functions successfully build the in-repo binary, extract JSON,
render a validator-clean agent Markdown baseline, and return zero schemas cleanly for
a CRD without an OpenAPI schema. A direct Kueue schema smoke test writes 11 versioned
JSON schemas. A Model Registry smoke test confirms that a missing `rhoai` overlay
falls back to automatic overlay selection without failing the component.

The skill now uses the Markdown baseline as its primary input. Repository-wide
discovery and Task sub-agents remain only as a fallback for manual runs without
static analysis. The remaining agent work is constrained synthesis, targeted gap
resolution, and conditional topics such as FIPS, AIPCC, and build hermeticity.

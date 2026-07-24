# Task: Triage Remaining Ineligible Components

## Goal

Research the 6 least-investigated ineligible components to find low-hanging
fruit — components that can be made analyzer-only with source-audited
entries, small analyzer fixes, or adjudications. Approve any that become
eligible. Document the rest with precise blockers for future work.

## Context

52/90 components are approved for analyzer-only routing. 4 are permanent
residuals. Of the remaining 12 ineligible, 6 have been deeply investigated
(MLServer, caikit, caikit-tgis-backend, lm-evaluation-harness, rhoai-mcp,
llm-d-kv-cache) and have well-understood structural blockers. The other 6
have not been deeply investigated and may have tractable paths.

## Target Components

### Group A: No inbound surfaces, blocked by credential references (3)

These components have zero inbound runtime surfaces but are blocked on
`authentication` because the analyzer found credential env-var references
(e.g. `API_KEY`, `SECRET_ACCESS_KEY`) that are not accounted for by auth
facts. These credentials are likely **outbound** API keys for calling
external services, not inbound authentication.

This is analogous to the codeflare-sdk fix (commit that gated Python auth
signal scan limitation on `inboundRuntimeSurfaces() == 0`), but for the
credential-reference inventory check instead of the Python auth signal scan.

| Component | Credential refs | Other gaps | Notes |
|-----------|:---------------:|------------|-------|
| `fms-hf-tuning` | 1 | None — `internal_dependencies` already complete-empty (fact_count=0, status=complete, no limitations) | `scripts/pull_and_format_datasets.py:16` has `S3_SECRET_ACCESS_KEY`. Likely a data-fetch script, not runtime auth. |
| `llama-stack-provider-trustyai-garak` | 3 | None — both `integration_points` (1 fact) and `internal_dependencies` (1 fact) populated | `API_KEY`, `OPENAICOMPATIBLE_A*` — outbound LLM provider API keys |
| `pipelines-components` | 8 | `internal_dependencies` partial (33 active platform alias references) | Credential refs are `AWS_SECRET_ACCESS_KEY`, `OGX_CLIENT_API_KEY` etc. in pipeline component scripts. But `internal_dependencies` is also blocking. |

**Potential fix pattern:** If all credential references in these components
are outbound-only (no inbound surfaces to protect), the credential-reference
limitation could be gated on `inboundRuntimeSurfaces() > 0`, similar to the
auth signal scan fix. OR individual credential references in non-runtime
scripts could be source-audited.

### Group B: Other gaps (3)

| Component | Auth blocker | Other gaps | Notes |
|-----------|:------------:|------------|-------|
| `vllm-cpu` | 60 inbound surfaces, 1 auth fact | `integration_points` (shell script limitation), `internal_dependencies` (shell script limitation) | Real FastAPI server with many endpoints. Auth fact exists (Bearer token middleware). Shell scripts are `.buildkite/` CI scripts. |
| `llm-d-async` | 2 inbound surfaces (from `docs/guides/` patch YAML) | `integration_points` (unaccounted K8s API external connection, shell script), `internal_dependencies` (shell script) | The 2 "inbound surfaces" may be from documentation/example manifests, not the actual component. |
| `llm-d-routing-sidecar` | 3 inbound surfaces | `internal_dependencies` (1 platform alias + kustomize) | Go proxy with real inbound surfaces. |

## Research Approach

For each component:

1. **Read** `ANALYZER_ARCHITECTURE.md` from the checkout directory
   (at `/data/checkouts/red-hat-data-services.next/<component>/`)
2. **Read** `component-architecture.json` category_coverage section
3. **Examine** the specific files cited in evidence/limitations
4. **Determine** whether the gap is:
   - **Source-auditable**: The flagged evidence is non-runtime (scripts/,
     docs/, examples/, CI) — add source-audited entry
   - **Analyzer-fixable**: Small fix to `categorycoverage.go` (e.g., gate
     credential-reference limitation on inbound surfaces > 0)
   - **Adjudicatable**: The flagged evidence is invalid/irrelevant
   - **Real gap**: Genuine missing extraction capability

## Fix Authority

This task has authority to:

1. **Add source-audited empty category entries** to
   `lib/analyzer_correction_adjudications.json` for categories that are
   legitimately empty after source audit
2. **Fix `categorycoverage.go`** if a small, principled change (like the
   codeflare-sdk auth signal scan fix) can resolve a class of false
   limitations. Must include unit tests.
3. **Add approvals** to `lib/analyzer_only_approvals.json` for components
   that pass eligibility after fixes
4. **NOT** add new auth fact types or major new extraction contracts

## Negative Controls

- Must NOT source-audit `authentication` as empty if inbound runtime
  surfaces exist and are not accounted for by auth facts
- Must NOT add source-audited entries for credential references that are
  genuinely part of the runtime authentication flow
- Any `categorycoverage.go` change must pass the full Go test suite and
  a 90-component replay with zero regressions
- Shell scripts in `.buildkite/`, `docs/`, `examples/` directories should
  be evaluated for the `isSupportOnlyShellScript()` classification —
  if they're already excluded, the limitation is coming from somewhere else

## Acceptance Criteria

1. Each of the 6 components has a documented disposition (approved,
   source-audited, or documented blocker with specific gap description)
2. Any `categorycoverage.go` changes have unit tests
3. 90-component replay: 0 failures, 0 false nominations
4. `uv run main.py check-eligibility --platform=rhoai.next` confirms
   updated approval count and zero regressions
5. Validation note written to `docs/notes/`
6. Residual register (`docs/notes/analyzer-residual-agent-gaps.md`) updated
   with dispositions

## Likely Files

| File | Role |
|------|------|
| `src/arch-analyzer/internal/extractor/categorycoverage.go` | Credential-reference limitation logic; `isSupportOnlyShellScript()` |
| `src/arch-analyzer/internal/extractor/categorycoverage_test.go` | Unit tests for any coverage changes |
| `lib/analyzer_correction_adjudications.json` | Source-audited empty category entries |
| `lib/analyzer_only_approvals.json` | Approval additions |
| `lib/architecture_routing.py` | Read-only reference for eligibility logic |
| `docs/notes/analyzer-residual-agent-gaps.md` | Update with dispositions |

## Status

Done — 2026-07-21. 3 approved (fms-hf-tuning, llama-stack-provider-trustyai-garak,
pipelines-components). 3 documented with real blockers (vllm-cpu, llm-d-async,
llm-d-routing-sidecar). See [validation note](../notes/ineligible-triage-validation-2026-07-21.md).

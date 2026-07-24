# Task: Triage Final Ineligible Components

## Goal

Research the last 4 non-permanent ineligible components to determine which
(if any) can be made analyzer-only. These all have multi-category gaps or
structural blockers. Approve any that become eligible. Document the rest
as final residuals with precise blockers.

## Context

62/90 components are approved for analyzer-only routing. 3 are permanent
residuals (ogx, notebooks, notebooks-downstream). rhods-operator is a
permanent residual that happens to be eligible but is not approved by
design. These 4 are the last non-permanent ineligible components.

## Target Components

### llm-d-kv-cache — auth + internal_dependencies

Checkout: `/data/checkouts/red-hat-data-services.next/llm-d-kv-cache/`

**Authentication (6 inbound surfaces, 0 facts):**
- 6 inbound gRPC surfaces from proto files (IndexerService, TokenizerService)
- gRPC service has "unresolved interceptors or credentials" limitation
- These are Go gRPC services — check if they use platform-delegated auth
  or have their own interceptors

**Internal dependencies (0 facts, 4 limitations):**
- All limitations are kustomize resolution (configMapGenerator, missing
  optional patches/resources) and unsupported shell/C++ source
- The unsupported sources are `hooks/pre-commit.sh` (git hook, not runtime)
  and C++ CUDA storage backends (`csrc/`) — neither are runtime-relevant
- 98-file platform alias scan found 0 matches
- May be source-auditable if shell/C++ files are classifiable as non-runtime

**Tractability:** Medium. Auth gap is real (Go gRPC with interceptors).
Internal deps gap may be resolvable via shell/C++ classification fixes.

### lm-evaluation-harness — auth + internal_dependencies

Checkout: `/data/checkouts/red-hat-data-services.next/lm-evaluation-harness/`

**Authentication (0 facts, 1 limitation):**
- No inbound surfaces (pure evaluation harness, no server)
- Blocker is "unsupported runtime source languages require authentication
  analysis" — shell scripts in `lm_eval/tasks/` directories
- Has 3 credential references (HF_TOKEN, ANTHROPIC_API_KEY, WATSONX_API_KEY)
  but these passed the credential-ref check (no inbound surfaces)
- 5 completed checks already — very close to complete

**Internal dependencies (0 facts, 1 limitation):**
- Same shell script blocker as auth
- 491-file alias scan found 0 matches — legitimately empty
- Shell scripts are task-specific runners (gen_yaml.sh, run.sh, fewshot.sh)
  inside `lm_eval/tasks/` — these are benchmark task configs, not runtime

**Tractability:** High. Both gaps are caused by the same shell scripts in
`lm_eval/tasks/`. If `isSupportOnlyShellScript()` can classify these
(they're benchmark task scripts, not runtime), both categories clear.

### rhoai-mcp — auth only

Checkout: `/data/checkouts/red-hat-data-services.next/rhoai-mcp/`

**Authentication (3 inbound surfaces, 0 facts):**
- Surfaces from `deploy/kustomize/base/service.yaml` and
  `deploy/kustomize/base/deployment.yaml` — these are Kubernetes manifests,
  not source code. Check what they define (ports, probes?).
- This is a Python MCP (Model Context Protocol) server — check if it has
  its own auth or is platform-delegated

**Other categories have facts** (integration: 4, internal_deps: 5) but also
have limitations (24 platform aliases, kustomize). However, these are NOT
the eligibility blocker — only auth blocks.

**Tractability:** Medium. The 3 inbound surfaces are from manifests — need
to determine if they're real inbound surfaces or manifest configuration
that shouldn't count.

### vllm-cpu — integration_points + internal_dependencies

Checkout: `/data/checkouts/red-hat-data-services.next/vllm-cpu/`

**Authentication (48 inbound surfaces, 1 fact):**
- Real FastAPI server with many HTTP endpoints across multiple routers
- 1 auth fact exists (Bearer token middleware) but doesn't cover all 48
- NOT the eligibility blocker (integration_points and internal_dependencies
  are)

**Integration points (0 facts, 1 limitation):**
- "unsupported runtime source languages" — shell scripts: `build_rust.sh`,
  `build_vllm_ppc64le.sh`, `build_vllm_s390x.sh`
- These are build scripts, not runtime — should be classifiable as
  support-only

**Internal dependencies (0 facts, 1 limitation):**
- Same shell script blocker
- 2701-file alias scan found 0 matches — legitimately empty

**Tractability:** High for integration_points + internal_dependencies
(build scripts should be classifiable). Auth would remain a gap but is
not the current eligibility blocker.

## Fix Authority

This task has authority to:

1. **Extend `isSupportOnlyShellScript()`** in `categorycoverage.go` if
   shell scripts in `lm_eval/tasks/`, build scripts (`build_*.sh`), or
   git hooks (`hooks/`) can be principled-ly excluded. Must include tests.
2. **Classify C++ files** — check if `.cpp`/`.hpp`/`.c`/`.h` files in
   non-runtime paths (like `csrc/` CUDA backends) can be excluded from
   the unsupported-language surface count
3. **Add source-audited entries** for legitimately empty categories
4. **Add platform-delegated auth entries** using the established mechanism
5. **Add approvals** for components that pass eligibility after fixes

## Negative Controls

- Must NOT source-audit authentication as empty if real unaccounted inbound
  surfaces exist
- Must NOT weaken inbound surface counting for legitimate endpoints
- Go test suite + 90-component replay must pass with zero regressions

## Acceptance Criteria

1. Each component has a documented disposition
2. Any Go changes have unit tests
3. 90-component replay clean, check-eligibility confirms counts
4. Validation note written to `docs/notes/`
5. Residual register updated with final dispositions

## Likely Files

| File | Role |
|------|------|
| `src/arch-analyzer/internal/extractor/categorycoverage.go` | `isSupportOnlyShellScript()`, `unsupportedRuntimeSourceSurfaces()` |
| `src/arch-analyzer/internal/extractor/categorycoverage_test.go` | Unit tests |
| `lib/analyzer_correction_adjudications.json` | Source-audited / platform-delegated entries |
| `lib/analyzer_only_approvals.json` | Approvals |
| `docs/notes/analyzer-residual-agent-gaps.md` | Final residual register |

## Status

Pending

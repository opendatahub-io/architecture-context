# Final Ineligible Component Triage Validation

Date: 2026-07-23

## Summary

Triaged the last 4 non-permanent ineligible components. 1 approved
(lm-evaluation-harness), 3 documented as final residuals.

Post-triage: 64 eligible, 63 approved, 1 eligible-not-approved (rhods-operator
permanent residual), 3 permanent ineligible (ogx, notebooks,
notebooks-downstream), 3 final residual ineligible (vllm-cpu, rhoai-mcp,
llm-d-kv-cache).

## Go Analyzer Changes

### `isSupportOnlyShellScript()` extended

Added classification for:
- Shell scripts in `tasks/` and `tools/` directories (with `runtimeShellScriptRole`
  guard to preserve entrypoint/deploy/hook detection)
- Build script prefixes: `build_*.sh`, `build-*.sh`
- Git hook basenames: `pre-commit`, `commit-msg`, `pre-push`,
  `prepare-commit-msg`, `pre-rebase`, `post-checkout`, `post-merge`

### New `isSupportOnlyNativeSource()` function

Classifies C/C++ files (`.c`, `.cc`, `.cpp`, `.h`, `.hpp`) as non-runtime when
located in support directories: `.devcontainer`, `completions`, `contrib`,
`documentation`, `hack`, `mkdocs`, `packaging`, `scripts`, `site-src`, `tasks`,
`tools`, `ci`, `ci-*`, `*-ci-*`, `*e2e*`.

### `unsupportedRuntimeSourceSurfaces()` extended

Native source files in support directories are excluded from the unsupported
language surface count using `isSupportOnlyNativeSource()`.

### `ignoredCoverageDir()` extended

Added `csrc` (CUDA source directories) to the ignored directory list.

## Component Dispositions

### lm-evaluation-harness — APPROVED (63rd)

**Prior state:** Ineligible — `authentication` and `internal_dependencies`
bounded correction gaps caused by 5 shell scripts in `lm_eval/tasks/` and 1
C++ file in `scripts/clean_training_data/`.

**Resolution:** Shell scripts in `tasks/` now classified as support-only via
extended `isSupportOnlyShellScript()`. C++ file in `scripts/` excluded via new
`isSupportOnlyNativeSource()`. All 3 high-value categories now complete:
- authentication: 5 completed checks, 0 inbound surfaces, 3 credential refs
  (HF_TOKEN, ANTHROPIC_API_KEY, WATSONX_API_KEY) — non-blocking for zero-inbound
- integration_points: complete (evaluation harness, no outbound platform clients)
- internal_dependencies: complete (491-file alias scan, 0 matches)

### vllm-cpu — FINAL RESIDUAL

**Prior state:** Ineligible — `integration_points` and `internal_dependencies`
bounded correction gaps.

**Partial resolution:** Build scripts (`build_rust.sh`, `build_vllm_ppc64le.sh`,
`build_vllm_s390x.sh`), `csrc/` CUDA backends, and `tools/` directory scripts
now classified as support-only.

**Remaining blockers (3 genuinely runtime unsupported sources):**
- `docker/entrypoints/vllm-nonroot-entrypoint.sh` — container entrypoint
  (runtime shell, sets up process environment)
- `vllm/distributed/kv_transfer/kv_connector/v1/hf3fs/utils/hf3fs_utils.cpp` —
  HF3FS C++ utility inside the vllm package (runtime distributed KV transfer)
- `vllm/utils/numa_wrapper.sh` — NUMA process wrapper (runtime process
  management)

These are legitimate runtime infrastructure code in unsupported languages. The
analyzer cannot determine their authentication, dependency, or integration
behavior. Not a classification bug — a real language coverage limitation.

### rhoai-mcp — FINAL RESIDUAL

**Prior state:** Ineligible — `authentication` bounded correction gap (3 inbound
surfaces, 0 auth facts).

**Analysis:** The 3 inbound surfaces are:
1. Service port from `deploy/kustomize/base/service.yaml`
2. Liveness probe from `deploy/kustomize/base/deployment.yaml`
3. Readiness probe from `deploy/kustomize/base/deployment.yaml`

The `inboundRuntimeSurfaces()` function counts Kubernetes Services and deployment
probes as inbound surfaces, but `authenticationCoverage()` has no mechanism to
account for auth on these manifest-declared surfaces. The Python source has OIDC
middleware (via `mcp.server.sse`), but the analyzer's auth extraction doesn't
link Python middleware to manifest-declared Service ports.

3 existing `accepted_analyzer_absences` adjudications cover the agent-vs-analyzer
output gaps, but the underlying eligibility blocker is the manifest inbound
surface → auth matching gap, which would require new extraction contracts.

### llm-d-kv-cache — FINAL RESIDUAL

**Prior state:** Ineligible — `authentication` and `internal_dependencies`
bounded correction gaps.

**Partial resolution:** `hooks/pre-commit.sh` now classified as git hook via
`isSupportOnlyShellScript()`. `csrc/` excluded via `ignoredCoverageDir()`.

**Remaining blockers:**
- authentication: 6 gRPC surfaces from proto files (IndexerService,
  TokenizationService). IndexerService is implemented only in `examples/`.
  TokenizationService uses Unix Domain Socket (UDS) pod-local transport — no
  network exposure. But the analyzer counts proto-declared services as inbound
  surfaces regardless of transport binding.
- internal_dependencies: 3 kustomize resolution limitations (configMapGenerator,
  missing optional patches/resources) + `services/uds_tokenizer/update-hashes.sh`
  unsupported shell script (SHA hash update utility, arguably support-only but
  inside a `services/` directory)
- integration_points: unaccounted Kubernetes API connection + kustomize limitations

The gRPC surface count is technically correct (proto files declare services),
but the lack of transport-awareness means UDS-only services are counted
alongside network-exposed services. Not a classification bug — a missing
transport binding contract.

## Test Results

All unit tests pass:
- `TestIsSupportOnlyShellScriptBasenames` — build script prefix matching
- `TestIsSupportOnlyShellScriptTasksDir` — tasks/ directory classification
- `TestIsSupportOnlyShellScriptToolsDir` — tools/ directory classification
- `TestIsSupportOnlyShellScriptGitHooks` — git hook basename matching
- `TestIsSupportOnlyNativeSource` — C/C++ support directory exclusion
- `TestIgnoredCoverageDirCsrc` — csrc directory ignored
- `TestUnsupportedRuntimeSourceExcludesCsrcAndSupportDirs` — integration positive
- `TestUnsupportedRuntimeSourceRetainsNonSupportDirCpp` — integration negative

90-component replay: 64 eligible, 63 approved. Zero regressions.

## Verification

```
$ uv run main.py check-eligibility --platform=rhoai.next
Checked 70 sufficient components (skipped 20 without analyzer data):
  64 eligible, 63 approved, 1 newly eligible (not yet approved)
  Newly eligible: rhods-operator
```

rhods-operator is the permanent residual that is eligible but not approved by
design. All other eligible components are approved.

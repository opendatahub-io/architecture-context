# Ineligible Component Triage Validation

Date: 2026-07-21

## Summary

Triaged 6 under-investigated ineligible components. Two analyzer fixes
(credential-reference limitation suppression and `.buildkite` CI directory
exclusion) made 3 components eligible and approved (fms-hf-tuning,
llama-stack-provider-trustyai-garak, pipelines-components). The remaining 3
(vllm-cpu, llm-d-async, llm-d-routing-sidecar) have real architectural gaps
that cannot be resolved with source-audited entries or small analyzer fixes.

Approved count: 52 → 55. Ineligible: 12 → 9 (plus 3 permanent residuals).

## Analyzer Fixes

### Fix 1: Suppress credential-reference limitation when no inbound surfaces

**File:** `src/arch-analyzer/internal/extractor/categorycoverage.go`, lines 78-81

`authenticationCoverage()` previously added a "credential references not
accounted for" limitation even when the component had zero inbound runtime
surfaces. This limitation fires only when `inbound == 0` (the `inbound > 0`
early return at line 64 guarantees it), meaning the credential references are
always outbound client credentials in this code path.

**Fix:** Removed the `coverage.Limitations = append(...)` line for credential
references. Kept the completed check (`credential-reference-inventory`) and
evidence recording — outbound credential references still appear in evidence
for transparency, but no longer create a blocking limitation.

**Principle:** Same as the codeflare-sdk Python auth signal scan fix — when
there are no inbound surfaces, there's nothing to protect, so outbound-only
signals should not block eligibility.

**Components unblocked:**
- fms-hf-tuning: 1 credential ref (S3_SECRET_ACCESS_KEY in data-fetch script)
- llama-stack-provider-trustyai-garak: 3 credential refs (API_KEY, OPENAICOMPATIBLE_API_KEY, AWS_SECRET_ACCESS_KEY — all outbound LLM/S3 client keys)
- pipelines-components: 8 credential refs (all outbound — S3, HuggingFace, LLM API keys, OCI pull secrets, Kubernetes bearer tokens)

### Fix 2: Add `.buildkite` and `benchmarks` to `ignoredCoverageDir()`

**File:** `src/arch-analyzer/internal/extractor/categorycoverage.go`, line 1173

Added `.buildkite` (Buildkite CI pipeline directory, analogous to `.github`
and `.tekton`) and `benchmarks` (benchmark scripts, analogous to `tests` and
`examples`) to the ignored directory list. These directories are skipped during
all coverage walks: unsupported source scanning, platform alias scanning, and
Python auth signal scanning.

**Components affected:**
- vllm-cpu: 10 `.buildkite/` + 1 `benchmarks/` shell scripts no longer counted
  as unsupported runtime sources. However, C/C++ CUDA kernel files (`csrc/`)
  and root-level build scripts still create unsupported-source limitations.
  Auth gap (60 inbound surfaces, 1 fact) remains the primary blocker.

### Unit tests

| Test | Assertion |
|------|-----------|
| `TestAuthenticationCoverageCompleteWhenOnlyCredentialReferencesWithNoInbound` | Updated: status=complete, no credential limitation, credential evidence preserved |
| `TestAuthenticationCoveragePartialForCredentialReferenceWithInbound` | New: status=partial with inbound limitation (credential check never reached) |
| `TestIgnoredCoverageDirBuildkite` | New: `.buildkite` → true |
| `TestIgnoredCoverageDirBenchmarks` | New: `benchmarks` → true |

All Go tests pass. `go vet` clean.

## Per-Component Dispositions

### Approved (3 components)

#### fms-hf-tuning (53rd component)

- **Prior blocker:** authentication — 1 credential ref (S3_SECRET_ACCESS_KEY)
- **Resolution:** Credential-reference fix. The single credential is in
  `scripts/pull_and_format_datasets.py:16`, used for outbound S3 dataset
  downloads via boto3. No inbound surfaces exist.
- **Post-fix status:** authentication=complete, integration_points=complete,
  internal_dependencies=complete (fact_count=0, status=complete, no limitations)

#### llama-stack-provider-trustyai-garak (54th component)

- **Prior blocker:** authentication — 3 credential refs
- **Resolution:** Credential-reference fix. All 3 credentials are outbound:
  API_KEY (upstream model endpoint), OPENAICOMPATIBLE_API_KEY (OpenAI-compatible
  generator client), AWS_SECRET_ACCESS_KEY (S3 storage). No inbound surfaces.
- **Post-fix status:** authentication=complete, integration_points=complete
  (1 fact), internal_dependencies=complete (1 fact)

#### pipelines-components (55th component)

- **Prior blocker:** authentication (8 credential refs) + internal_dependencies
  (33 platform alias references)
- **Resolution:** Credential-reference fix cleared authentication. The
  `internal_dependencies` category has 2 facts in the ANALYZER_ARCHITECTURE.md
  table (Kubeflow Pipelines SDK, Kubernetes API), so it is NOT empty in the
  markdown baseline. The 33 alias references are a coverage gap in the JSON
  status, but since the category has table rows, the eligibility check does
  not consider it a correction gap.
- **Post-fix status:** authentication=complete, integration_points=complete
  (1 fact), internal_dependencies=partial (but not empty → not a correction gap)

### Ineligible — documented blockers (3 components)

#### vllm-cpu

- **Blockers:** authentication (60 inbound HTTP surfaces, 1 ASGI middleware
  auth fact), integration_points (C/C++ unsupported sources), internal_dependencies
  (C/C++ unsupported sources)
- **.buildkite fix effect:** Removed 10 CI shell scripts from unsupported source
  lists. But `csrc/` directory has C/C++ CUDA kernel headers (.h, .hpp) and
  root-level build scripts (build_vllm_ppc64le.sh, build_vllm_s390x.sh) that
  remain as unsupported runtime sources.
- **Assessment:** Multiple structural gaps. The auth gap (60 surfaces vs 1 fact)
  is the primary blocker — the analyzer cannot prove ASGI middleware coverage
  across all FastAPI routes. The C/C++ sources are real compiled code linked
  into the runtime. Not tractable without major new extraction contracts.

#### llm-d-async

- **Blockers:** authentication (2 inbound surfaces from `docs/guides/`
  example YAML — misattributed as component surfaces), integration_points
  (unaccounted Kubernetes API + shell scripts in `deploy/`),
  internal_dependencies (shell scripts in `deploy/`)
- **Assessment:** Multiple gaps. The 2 "inbound surfaces" are from example
  deployment manifests in `docs/guides/e2e-deploy/modelserver/` describing
  a vllm model server, not llm-d-async's own endpoints. The `deploy/` shell
  scripts are deployment automation. Fixing this requires either excluding
  `docs/guides/` manifests from inbound surface detection or adding `deploy/`
  to the shell script exclusion list. Neither is a small principled change.

#### llm-d-routing-sidecar

- **Blockers:** authentication (3 real inbound surfaces — HTTP proxy on :8080,
  Service, OpenShift Route), integration_points (unaccounted Kubernetes API
  dynamic client + external connection), internal_dependencies (1 platform
  alias `route.openshift.io` + unresolved kustomize configMapGenerator)
- **Assessment:** All gaps are real. The HTTP proxy has genuine inbound
  surfaces with no documented auth mechanism (auth may be delegated to
  OpenShift Route TLS/network policy, but this cannot be source-audited
  without evidence). The Kubernetes API dependency and OpenShift Route
  platform alias are real missing facts.

## Verification

### Eligibility check

```
uv run main.py check-eligibility --platform=rhoai.next
Checked 68 sufficient components: 56 eligible, 55 approved, 1 newly eligible
Newly eligible: rhods-operator
```

### Approval counts

| State | Count |
|-------|------:|
| Analyzer-sufficient | 68 |
| Approved analyzer-only | 55 |
| Permanent agent residual (eligible, not approved) | 1 |
| Permanent agent residual (ineligible) | 3 |
| Ineligible (bounded correction gaps) | 9 |

### Zero regressions

All 52 previously approved components remain eligible=True approved=True.
3 newly approved components verified. 0 false positives.

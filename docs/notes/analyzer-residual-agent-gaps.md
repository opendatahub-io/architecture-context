# Analyzer Residual Agent Gaps

This register accounts for every analyzer-sufficient component that is not approved
for analyzer-only generation. An entry is a deterministic candidate until source
audit proves that unsupported behavior must remain agent-owned. Presence here blocks
rollout approval unless the entry has an explicit approval and validation record.

## Authoritative State

The authoritative classification is the post-approval eligibility replay at
`tmp/eligibility-post-approval.json`, using the v1 agent run with the static
analyzer snapshot.

| State | Components |
|-------|-----------:|
| Analyzer-sufficient | 68 |
| Approved analyzer-only | 63 |
| Permanent agent residual (eligible, not approved) | 1 |
| Permanent agent residual (ineligible) | 3 |
| Final residual ineligible | 3 |
| Not eligible (upstream regression) | 0 |
| False nominations | 0 (pre-approval) |

63 approved includes 3 from ineligible triage (fms-hf-tuning,
llama-stack-provider-trustyai-garak, pipelines-components), 3 from
platform-delegated authentication (MLServer, caikit, caikit-tgis-backend),
2 from near-miss triage (llm-d-async, llm-d-routing-sidecar), and 1 from
final ineligible triage (lm-evaluation-harness).
workbenches-operator upstream regression resolved via source-audited
architecture_components.
Credential-reference limitation suppressed for zero-inbound components;
`.buildkite` and `benchmarks` added to ignored coverage directories;
`docs` added to `runtimeSurfaceSource()` exclusion; HTTP endpoint auth
accounting added to `inboundRuntimeSurfaces()`; `tasks/`, `tools/`, build
script prefixes, git hook basenames added to `isSupportOnlyShellScript()`;
`isSupportOnlyNativeSource()` added for C/C++ in support directories;
`csrc` added to `ignoredCoverageDir()`. See
[ineligible triage validation](ineligible-triage-validation-2026-07-21.md),
[platform-delegated auth validation](platform-delegated-authentication-validation-2026-07-23.md),
[near-miss triage validation](near-miss-ineligible-triage-validation-2026-07-23.md),
[final ineligible triage validation](final-ineligible-triage-validation-2026-07-23.md).

## Final Dispositions (23 non-approved)

### Approved in Go source extraction (v1)

| Component | Prior state | Disposition |
|-----------|-------------|-------------|
| `ai-gateway-payload-processing` | 7 mutations, 2 empty HV categories | **Approved** — controller components + CRD auth enum extractors (cross-file). 2/7 resolved; remaining are label-precision differences. |
| `argo-workflows` | 3 mutations, 2 empty HV categories | **Approved** — health endpoint auth + DSP adjudication + source-audited empty internal_dependencies. 2/3 resolved. |
| `eval-hub` | 1 mutation, 1 empty HV category | **Approved** — GVR cross-file constant resolution surfaces HardwareProfile CR. internal_dependencies populated. |
| `rhaii-cluster-validation` | 2 mutations, 3 empty HV categories | **Approved** — Cobra CLI + kubeconfig auth. Source-audited empty internal_dependencies (existing). |

### Approved in manifest residual resolution

| Component | Prior state | Disposition |
|-----------|-------------|-------------|
| `trustyai-explainability` | 7 mutations, manifest cluster | **Approved** — 2 extracted (prometheus annotation), 4 adjudicated (init container, Java unsupported), 1 source-audited (authentication/Java). All mutations resolved. |
| `llm-d-planner` | 6 mutations, manifest cluster | **Approved** — 3 extracted (core RBAC nodes, service-ca, k8s-api), 3 adjudicated (credential-only env vars). All mutations resolved. |

### Approved in Go gRPC residual resolution

| Component | Prior state | Disposition |
|-----------|-------------|-------------|
| `modelmesh-runtime-adapter` | 8 mutations, Go gRPC cluster | **Approved** — 8 adjudicated (2 caller-identity, 6 rename-duplicates of existing facts), 1 source-audited (internal_dependencies). All mutations resolved. |

### Approved in Python import→category wiring

| Component | Prior state | Disposition |
|-----------|-------------|-------------|
| `mlflow` | 5 mutations, `internal_dependencies` gap | **Approved** — Python import analysis wired into InternalDependency/IntegrationFact generation. 1 internal dep (Kubernetes API), 5 integration points (AWS S3, GCS, OpenAI + ExternalConnections). All high-value categories populated, no correction gaps. |

### Approved via auth signal scan fix

| Component | Prior state | Disposition |
|-----------|-------------|-------------|
| `codeflare-sdk` | 3 mutations, `authentication` gap (Python auth signal scan blocked) | **Approved** — `authenticationCoverage()` no longer adds blocking limitation for Python auth signal matches when `inboundRuntimeSurfaces() == 0`. The detected `"Authorization":` header in `cluster.py` is client-side outbound Kubernetes API auth, not an inbound surface. Auth signal evidence retained for transparency. |

### Approved via source-audited empty categories

| Component | Prior state | Disposition |
|-----------|-------------|-------------|
| `NeMo-Guardrails` | 4 mutations, `internal_dependencies` empty | **Approved** — Source audit confirms 339 runtime files scanned with 0 platform alias matches, 0 platform packages in import analysis. 3 unsupported shell scripts are build/benchmark tooling only. `internal_dependencies` source-audited empty. |
| `llm-d-latency-predictor` | 4 mutations, `integration_points` + `internal_dependencies` empty | **Approved** — Source audit confirms 12 runtime files scanned with 0 platform alias matches, 0 platform/SDK packages in import analysis, 0 outbound clients/connections. `build-deploy.sh` is CI/CD tooling only. Both categories source-audited empty. |

### Approved in v1 closeout

| Component | Prior state | Disposition |
|-----------|-------------|-------------|
| `llm-d-batch-gateway-operator` | Candidate, 0 corrections | **Approved** — all high-value categories populated (auth:3, integration:3, internal_deps:5), zero unresolved mutations, two prior corrections source-adjudicated. |

### Approved via platform-delegated authentication

| Component | Prior state | Disposition |
|-----------|-------------|-------------|
| `MLServer` | 8 mutations, `authentication` gap (16 inbound gRPC, 0 auth facts) | **Approved** — Platform-delegated auth via KServe kube-rbac-proxy sidecar. 16 synthetic auth facts injected via `--supplemental-auth` flag. All gRPC surfaces accounted for. See [validation note](platform-delegated-authentication-validation-2026-07-23.md). |
| `caikit` | 8 mutations, `authentication` gap (16 inbound gRPC, 0 auth facts) | **Approved** — Platform-delegated auth via ModelMesh pod-local. 16 synthetic auth facts injected. All gRPC surfaces accounted for. See [validation note](platform-delegated-authentication-validation-2026-07-23.md). |
| `caikit-tgis-backend` | `authentication` gap (4 inbound gRPC, 0 auth facts) | **Approved** — Platform-delegated auth via ModelMesh pod-local. 4 synthetic auth facts injected. All gRPC surfaces accounted for. See [validation note](platform-delegated-authentication-validation-2026-07-23.md). |

### Adjudicated to zero (invalid historical evidence)

| Component | Adjudicated | Evidence class | Disposition |
|-----------|------------:|----------------|-------------|
| `caikit-tgis-serving` | 8/8 | `demo/kserve/custom-manifests/` | **Approved** — source audit confirms container image build repository with no auth, integration, or dependency code. Empty categories are legitimate. |
| `distributed-workloads` | 4/4 | `benchmarks/`, `examples/` | **Approved** — source audit confirms image factory with no shipped service, no auth, no platform dependencies. Empty categories are legitimate. |
| `vllm-cpu` | 3/3 | `benchmarks/` | **Final residual** — benchmark corrections invalid; auth detected (Bearer token via ASGI middleware). Build scripts, csrc/, tools/ now classified as support-only. 3 genuinely runtime unsupported sources remain: container entrypoint, HF3FS C++ utility, NUMA wrapper. See [final ineligible triage validation](final-ineligible-triage-validation-2026-07-23.md). |

### Approved via final ineligible triage

| Component | Prior state | Disposition |
|-----------|-------------|-------------|
| `lm-evaluation-harness` | Ineligible — `authentication` and `internal_dependencies` bounded correction gaps (5 shell scripts in `lm_eval/tasks/`, 1 C++ file in `scripts/`) | **Approved** — Shell scripts in `tasks/` classified as support-only, C++ in `scripts/` excluded via `isSupportOnlyNativeSource()`. All 3 HV categories complete. See [final ineligible triage validation](final-ineligible-triage-validation-2026-07-23.md). |

### Remaining non-approved components (37 extraction-targetable mutations)

| Component | Unresolved | Cluster | Unsupported behavior |
|-----------|------------|---------|----------------------|
| ~~`MLServer`~~ | ~~8~~ | ~~Python dependency~~ | **Approved** — Platform-delegated auth (kube-rbac-proxy sidecar). 16 gRPC surfaces accounted for via supplemental auth facts. See [validation note](platform-delegated-authentication-validation-2026-07-23.md). |
| ~~`caikit`~~ | ~~8~~ | ~~Python dependency~~ | **Approved** — Platform-delegated auth (ModelMesh pod-local). 16 gRPC surfaces accounted for via supplemental auth facts. See [validation note](platform-delegated-authentication-validation-2026-07-23.md). |
| ~~`mlflow`~~ | ~~5~~ | ~~Python runtime~~ | **Approved** — Python import→fact wiring resolved `internal_dependencies` gap. See [validation note](python-import-category-wiring-validation-2026-07-21.md). |
| ~~`kubeflow-sdk`~~ | ~~5~~ | ~~Python dependency~~ | **Approved** — Shell script fix removed unsupported-language coverage gaps. All HV categories populated in ANALYZER_ARCHITECTURE.md (auth=1, integration=1, internal_deps=1). `integration_points` also has complete-empty contract. See [batch review validation](batch-eligible-review-validation-2026-07-21.md). |
| ~~`NeMo-Guardrails`~~ | ~~4~~ | ~~Python runtime~~ | **Approved** — `internal_dependencies` source-audited empty (339 files, 0 platform aliases). See [validation note](source-audited-empty-categories-validation-2026-07-21.md). |
| ~~`llm-d-latency-predictor`~~ | ~~4~~ | ~~Python runtime~~ | **Approved** — `integration_points` and `internal_dependencies` source-audited empty (12 files, 0 platform aliases, 0 SDK clients). See [validation note](source-audited-empty-categories-validation-2026-07-21.md). |
| ~~`codeflare-sdk`~~ | ~~3~~ | ~~Python dependency~~ | **Approved** — `authenticationCoverage()` fixed to skip blocking limitation when `inboundRuntimeSurfaces() == 0`. Python auth signal match (`cluster.py:87` client-side `Authorization` header) retained in evidence but non-blocking. See [validation note](auth-signal-scan-no-inbound-validation-2026-07-21.md). |
| `rhoai-mcp` | 3 | Manifest | **Final residual** — 3 manifest inbound surfaces (Service port + 2 health probes) without auth accounting. `inboundRuntimeSurfaces()` counts manifest surfaces but `authenticationCoverage()` cannot link Python OIDC middleware to manifest-declared ports. See [final ineligible triage validation](final-ineligible-triage-validation-2026-07-23.md). |
| ~~`llm-d-routing-sidecar`~~ | ~~2~~ | ~~Manifest~~ | **Approved** — Source-audited empty internal_dependencies (route.openshift.io is infrastructure API). See [near-miss triage validation](near-miss-ineligible-triage-validation-2026-07-23.md). |
| ~~`llm-d-async`~~ | ~~1~~ | ~~Go runtime~~ | **Approved** — docs/ exclusion + HTTP auth accounting + platform-delegated health probes. See [near-miss triage validation](near-miss-ineligible-triage-validation-2026-07-23.md). |
| `llm-d-kv-cache` | 1 | Go runtime | **Final residual** — 6 gRPC surfaces from proto files (UDS pod-local transport, not network-exposed). Auth gap: analyzer lacks transport binding awareness. Internal deps: kustomize resolution + `services/uds_tokenizer/update-hashes.sh`. See [final ineligible triage validation](final-ineligible-triage-validation-2026-07-23.md). |
| ~~`kube-auth-proxy`~~ | ~~1~~ | ~~Go runtime~~ | **Approved** — Shell script classification fix resolved `internal_dependencies` (complete-empty). `authentication` source-audited empty (auth proxy with 0 registered endpoints). See [research note](kube-auth-proxy-approval-research-2026-07-21.md), [validation note](kube-auth-proxy-approval-validation-2026-07-21.md). |

Post-adjudication row identities from `reports/eligibility-v1.json`. Historical
agent merge evidence under
`tmp/architecture-corpus-runs/rhoai.next-20260720T103625Z-3372001/logs/agents/`.

Classification:
[Analyzer remaining candidate prioritization](analyzer-remaining-candidate-prioritization-2026-07-19.md).

## Mutation Reconciliation

| Disposition | Components | Mutations |
|-------------|:----------:|----------:|
| Approved analyzer-only (v1 + source audit + Go + manifest + gRPC + import wiring + source-audited empty + auth signal fix + shell script fix + batch review + credential-ref fix + platform-delegated auth + near-miss triage + final triage) | 63 | 0 |
| Permanent agent residual | 4 | 20 |
| Adjudicated invalid evidence — resolved | 1 | 0 (3 adjudicated, auth now detected) |
| Final residual — manifest inbound/auth gap | 1 | 3 (rhoai-mcp) |
| Final residual — gRPC transport + kustomize gap | 1 | 1 (llm-d-kv-cache) |
| **Total** | **64** | **4 residual + 20 permanent + 48 adjudicated** |

All 64 analyzer-sufficient components have exactly one disposition. All 127
pre-adjudication mutations reconciled: 27 adjudicated as invalid evidence
(22 approved via source audit, 3 deferred pending Python extraction,
2 Go source adjudicated for argo-workflows DSP),
13 manifest adjudicated (5 extraction-resolved + 8 agent-owned),
8 Go gRPC adjudicated (2 caller-identity + 6 rename-duplicates),
20 permanent (structurally unextractable), 24 remaining with named
unsupported behavior or pending extraction.

## Completed Tasks

- [Extract Python dependency-import relationships](../tasks/done/extract-python-dependency-import-relationships.md) — Done. Python AST import analyzer. MLServer +2 gRPC, caikit +3, feast +4. Import usage data available. See [validation note](python-import-analysis-validation-2026-07-21.md).
- [Extract Eval Hub runtime boundaries](../tasks/done/extract-eval-hub-runtime-boundaries.md) — Done. 3/8 by analyzer, 5/8 adjudicated.
- [Extract Kubernetes manifest Authentication and dependencies](../tasks/done/extract-kubernetes-manifest-authentication-dependencies.md) — Done. 3/27 by analyzer, 24/27 adjudicated.
- [Extract ModelMesh runtime relationships](../tasks/done/extract-modelmesh-runtime-relationships.md) — Done. 6/10 by analyzer, 4/10 adjudicated.
- [Extract Python dynamic authentication middleware](../tasks/done/extract-python-dynamic-authentication-middleware.md) — Done. ogx 0→5 auth facts.
- [Approve adjudicated-to-zero components](../tasks/done/approve-adjudicated-zero-mutation-components.md) — Done. caikit-tgis-serving and distributed-workloads approved (source-audited empty categories). vllm-cpu deferred (real FastAPI AuthenticationMiddleware). See [validation note](adjudicated-zero-mutation-approval-2026-07-20.md).
- [Classify permanent residual components](../tasks/done/classify-permanent-residual-components.md) — Done. rhods-operator, ogx, notebooks, notebooks-downstream classified as permanent agent residuals. 20 mutations removed from extraction backlog (99 → 79).

- [Wire Python import analysis into category coverage](../tasks/done/wire-python-import-category-coverage.md) — Done. Python import→InternalDependency/IntegrationFact wiring + ExternalConnection→IntegrationFact conversion. mlflow approved (47th). 5 remaining targets ineligible due to gaps outside import scope (authentication, empty internal_dependencies). See [validation note](python-import-category-wiring-validation-2026-07-21.md).
- [Approve source-audited empty category components](../tasks/done/approve-source-audited-empty-categories.md) — Done. NeMo-Guardrails (`internal_dependencies`) and llm-d-latency-predictor (`integration_points`, `internal_dependencies`) source-audited empty and approved (48th, 49th). See [validation note](source-audited-empty-categories-validation-2026-07-21.md).
- [Resolve Python SDK authentication gaps](../tasks/done/resolve-python-sdk-authentication-gaps.md) — Done. Source audit of codeflare-sdk, MLServer, caikit. All three have authentication as sole empty HV category. MLServer/caikit cannot be source-audited (16 inbound gRPC surfaces each). See [validation note](python-sdk-authentication-validation-2026-07-21.md).
- [Skip auth signal scan limitation when no inbound surfaces](../tasks/done/skip-auth-signal-scan-when-no-inbound-surfaces.md) — Done. Fixed `authenticationCoverage()` to not add blocking limitation for Python auth signal matches when `inboundRuntimeSurfaces() == 0`. codeflare-sdk approved (50th). See [validation note](auth-signal-scan-no-inbound-validation-2026-07-21.md).

- [Resolve platform-delegated authentication](../tasks/done/resolve-platform-delegated-authentication.md) — Done. Added `--supplemental-auth` flag to Go analyzer, `platform_delegated_authentication` section to adjudication JSON. MLServer (16 gRPC, kube-rbac-proxy sidecar), caikit (16 gRPC, ModelMesh pod-local), caikit-tgis-backend (4 gRPC, ModelMesh pod-local) approved (55th-57th). See [validation note](platform-delegated-authentication-validation-2026-07-23.md).

## Pending Tasks

- [Extract Python runtime source surfaces](../tasks/done/extract-python-runtime-source-surfaces.md) — **Done.** Auth posture + SDK client contracts implemented. mlflow/llm-d-latency-predictor get absence-of-auth, NeMo-Guardrails gets Azure OpenAI SDK connection, vllm-cpu gets Bearer token auth (regex fix). Target components remain ineligible due to `internal_dependencies`/`integration_points` gaps. See [validation note](python-runtime-source-surfaces-validation-2026-07-21.md).
- [Extract Go runtime source surfaces](../tasks/done/extract-go-runtime-source-surfaces.md) — **Done.** 15 automated contracts + 1 adjudication. 4 components approved (ai-gateway-payload-processing, argo-workflows, eval-hub, rhaii-cluster-validation). 3 remain ineligible (kube-auth-proxy, llm-d-async, llm-d-kv-cache) due to empty high-value categories. See [validation note](go-source-extraction-v1-validation-2026-07-21.md).
- [Resolve manifest/deployment residuals](../tasks/done/resolve-manifest-deployment-residuals.md) — **Done.** 3 extraction contracts (prometheus annotation, service-ca annotation, core RBAC nodes), 13 adjudications, 1 source-audited empty category, bug fix for manifest internal deps overwrite. trustyai-explainability and llm-d-planner approved. See [validation note](manifest-deployment-residuals-validation-2026-07-21.md).
- [Resolve Go gRPC residuals](../tasks/done/resolve-go-grpc-residuals.md) — **Done.** 8 adjudications (2 caller-identity, 6 rename-duplicates), 1 source-audited empty category. modelmesh-runtime-adapter approved. See [validation note](go-grpc-residuals-validation-2026-07-21.md).
- [Extract Python dependency-import relationships](../tasks/done/extract-python-dependency-import-relationships.md) — **Done.** Python AST import analyzer + Go integration. MLServer +2 gRPC registrations, caikit +3, feast +4. Import analysis data (used/test-only/unused classification) available for future category coverage integration. Target components remain ineligible due to `authentication`/`internal_dependencies` category gaps. See [validation note](python-import-analysis-validation-2026-07-21.md).

## Completeness-Only Cases (Audited)

The [completeness-only candidate audit](completeness-only-candidate-audit-2026-07-19.md)
examined all three components and approved zero for analyzer-only routing.

| Component | Category | Audit outcome | Task |
|-----------|----------|---------------|------|
| `guardrails-regex-detector` | Integration Points | Resolved — `integration-points/v1` contract implemented and component approved analyzer-only | [Integration Points discovery contract validation](integration-points-discovery-contract-validation-2026-07-19.md) |
| `model-registry` | Internal Dependencies | Resolved — generic KServe GVK mapping and watch-to-dependency fallback now extract 2 KServe InferenceService facts | [Model Registry KServe controller dependency validation](model-registry-kserve-controller-dependency-validation-2026-07-19.md) |
| `ogx` | Authentication | Resolved — 5 auth facts extracted (middleware, 2 providers, 2 ABAC surfaces) | [Python dynamic authentication middleware validation](python-dynamic-authentication-middleware-validation-2026-07-20.md) |
| `ogx` | Internal Dependencies | Partial — source audit confirms emptiness but unsupported shell/Swift surfaces prevent formal completeness | Documented in audit; broader supported-language gap |

## Permanent Agent Residuals

Four components are formally classified as permanent agent residuals. They
will never be analyzer-only due to structural limitations, not missing
extraction contracts. Their 20 mutations are excluded from the
extraction-targetable backlog.

| Component | Mutations | Classification | Agent-owned reason | Prior audit |
|-----------|----------:|----------------|--------------------|----|
| `rhods-operator` | 0 | Deliberate prose | Hierarchical lifecycle, fan-out provisioning, and cross-component data-flow narrative are not represented by deterministic structured facts. Agent-owned for architectural prose, not extraction gaps. | [rhods-operator analyzer-only candidate audit](rhods-operator-analyzer-only-candidate-audit-2026-07-19.md) |
| `ogx` | 0 | Unsupported language | Internal Dependencies blocked by unsupported shell (12 build/CI scripts) and iOS Swift (5 files). Auth resolved (5 facts). Source audit: zero platform references across 735 files. Not a reasonable extraction target. | [completeness-only candidate audit](completeness-only-candidate-audit-2026-07-19.md) |
| `notebooks` | 19 | Non-runtime evidence model | Image-level bundled-library inventory (requirements.txt) represents user-available tools, not runtime service integration. No shipped application entrypoint invokes these libraries. | Documented in v1 residual register. |
| `notebooks-downstream` | 1 | Non-runtime evidence model | Same as `notebooks`; downstream image with pinned library versions. | Documented in v1 residual register. |

Classification rationale by type:

- **Deliberate prose** (`rhods-operator`): The agent produces cross-component
  lifecycle narrative that has no deterministic structured representation. The
  analyzer correctly extracts all structured facts; the gap is architectural
  prose, not data.
- **Unsupported language** (`ogx`): Shell and Swift surfaces are outside the
  analyzer's supported language set. A 735-file source audit found zero
  platform references, confirming no hidden dependencies.
- **Non-runtime evidence model** (`notebooks`, `notebooks-downstream`): The
  20 mutations represent bundled Python library availability in user
  environments (requirements.txt). This evidence model is fundamentally
  different from runtime service integration and cannot be captured by
  source-level deterministic extraction.

## Next Steps

63 of 68 sufficient components approved. Final ineligible triage approved
lm-evaluation-harness (63rd) and documented 3 final residuals. All non-permanent
ineligible components have been triaged.
See [final ineligible triage validation](final-ineligible-triage-validation-2026-07-23.md).

### Final residual ineligible components

3 components remain ineligible due to structural analyzer limitations, not
missing classification rules:
- `vllm-cpu`: 3 genuinely runtime unsupported sources (container entrypoint,
  NUMA wrapper, HF3FS C++) — language coverage limitation
- `rhoai-mcp`: 3 manifest inbound surfaces (Service + probes) without auth
  accounting — manifest→auth extraction gap
- `llm-d-kv-cache`: 6 gRPC surfaces (UDS pod-local transport) + kustomize
  resolution — transport binding + kustomize extraction gap

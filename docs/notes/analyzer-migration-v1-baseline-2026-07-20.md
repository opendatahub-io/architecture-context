# Analyzer Migration V1 Baseline

This note is the permanent reproducibility record for the completed analyzer
ownership migration v1. It identifies every artifact needed to reproduce the v1
output and routing decision, and includes a bounded consumer smoke test.

## Immutable Candidate Identity

| Property | Value |
|----------|-------|
| Repository commit | `0920cf3b8255cfd45584554de82b9812c1d01c08` |
| Final production run | `tmp/architecture-corpus-runs/rhoai.next-20260720T193556Z-104162` |
| Static replay authority | `tmp/architecture-corpus-runs/rhoai.next-20260720T173035Z-static` |
| Agent baseline fixture | `architecture/rhoai.next.bak/` (92 baseline docs, 190 files) |
| Completion milestone | [Analyzer ownership migration v1](../milestones/analyzer-ownership-migration-v1.md) |
| Completion date | 2026-07-20 |

## Source Revisions

The final production run recorded 90 component repository SHAs in `run.json`
under the `repositories` key. Each entry includes `commit_sha`, `branch`,
`remote_url`, and `checkout_path`. All repositories were on `main` branch at run
time. Representative revisions:

| Component | Commit SHA |
|-----------|------------|
| kserve | `ba0f7b5972cd89b8925357910a9eec7a24b28784` |
| rhods-operator | `e453f0a67fcb67982fa9522de90278e76990c194` |
| model-registry | `62733189ea906eeb88e955052c9b5da10405115a` |
| odh-dashboard | `f1cdd9f22ebd3b320de9cf45e9ba3fdb6a93e335` |
| vllm | `1c49d148c0869ebb4db966025ab84b494ba7cd22` |
| trainer-operator | `28fbb2b9a4fc4dcbd9a4f52b0920e1935ab0c24f` |
| data-science-pipelines-operator | `ab30578b3e674c26ff759edd1ddcc0e8734dfeee` |
| mlflow | `4e264333ca4985653863d05032779cd4a746c544` |

Full revision manifest: `run.json` → `repositories` (90 entries).

## Routing Policy

| Route | Components | Description |
|-------|:----------:|-------------|
| analyzer-only | 37 | Deterministic structured output, no agent invocation |
| evidence-gated (sufficient) | 27 | Agent synthesizes prose; structured facts analyzer-owned |
| evidence-gated (partial) | 18 | Agent fills gap categories under bounded budget |
| legacy (insufficient) | 8 | Full agent discovery with legacy fallback |

Implementation: `lib/architecture_routing.py` with constants
`SUFFICIENT_CATEGORY_LIMIT=4`, `SUFFICIENT_FILE_LIMIT=4`,
`PARTIAL_CATEGORY_LIMIT=6`, `HIGH_VALUE_AGENT_CATEGORIES` =
{architecture_components, authentication, integration_points,
internal_dependencies}.

## Approved Analyzer-Only Components (37)

agents-operator, ai-gateway-operator, batch-gateway, codeflare-operator,
data-science-pipelines, data-science-pipelines-operator, feast,
fms-guardrails-orchestrator, gateway-api-inference-extension,
guardrails-regex-detector, kserve, kserve-autogluon-server, kube-rbac-proxy,
kubeflow, kuberay, kueue, llm-d-batch-gateway-operator, llm-d-inference-scheduler,
llm-d-router, mcp-lifecycle-module-operator, mcp-lifecycle-operator, mlflow-operator,
model-registry, model-registry-operator, modelmesh-serving, models-as-a-service,
odh-cli, odh-dashboard, odh-model-controller, ogx-k8s-operator, spark-operator,
trainer, trainer-operator, training-operator, trustyai-service-operator,
workbenches-operator, workload-variant-autoscaler.

Source: `lib/analyzer_only_approvals.json` (schema_version: 1).

## Adjudications

`lib/analyzer_correction_adjudications.json` contains 70 adjudication entries
(schema_version: 1) documenting source-backed decisions where historical agent
evidence was invalid. 25 entries were adjudicated as invalid evidence across 3
components (caikit-tgis-serving: 8, distributed-workloads: 4, vllm-cpu: 3) plus
entries across kuberay, workbenches-operator, llm-d components, and
trustyai-service-operator.

## Residual Policy

| Disposition | Components | Unresolved mutations |
|-------------|:----------:|---------------------:|
| Approved analyzer-only (v1) | 37 | 0 |
| Deliberate prose residual | 1 | 0 |
| Adjudicated invalid evidence | 3 | 0 (25 adjudicated) |
| Empty categories — pending extraction | 1 | 0 |
| Empty categories — unsupported language | 1 | 0 |
| Pending Python runtime extraction | 3 | 13 |
| Go runtime source residual | 6 | 15 |
| Manifest/deployment residual | 4 | 18 |
| Python dependency declaration residual | 4 | 24 |
| Go gRPC residual | 1 | 8 |
| Notebook image inventory residual | 2 | 20 |
| **Total** | **64 sufficient** | **99 unresolved + 25 adjudicated** |

All 64 analyzer-sufficient components have exactly one disposition. 26 non-approved
components are agent-routed with source-backed residual reasons. One remaining
reusable extraction tranche (Python runtime source surfaces) has a focused pending
task.

Source: [Analyzer residual agent gaps](analyzer-residual-agent-gaps.md).

## Telemetry

| Measure | Value |
|---------|------:|
| Components processed | 90 |
| Analyzer-only (no agent) | 37 |
| Agent invocations | 53 |
| Model | Claude Opus 4.6 |
| Workers | 10 |
| Static analysis wall time | 17.84s |
| Component generation wall time | 1527.78s |
| Collection wall time | 0.7s |
| Total wall time | 1546.70s |
| Prior reference wall time | 3600.0s |
| Wall-time reduction | 57.04% |
| Total cost | $69.61 |
| Output tokens | 650,020 |
| Analyzer identities retained | 8614/8618 (99.95%) |
| Unexplained conflicts | 0 |
| False nominations | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Reported generation failures | 0 |

Phase timing from `run.json`:
- Static analysis: 2026-07-20T19:35:58Z → 2026-07-20T19:36:16Z
- Component generation: 2026-07-20T19:36:16Z → 2026-07-20T20:01:44Z
- Collection: 2026-07-20T20:01:44Z → 2026-07-20T20:01:45Z
- Comparison completed: 2026-07-20T20:01:47Z

## Artifact Manifest

SHA-256 hashes for drift detection. Re-hash and compare to verify that documents
and configuration are unchanged from the v1 candidate.

### Configuration and policy

| Artifact | SHA-256 |
|----------|---------|
| `lib/analyzer_only_approvals.json` | `551200ba56e52d8b6e33bb018728f5a25a23cec3d36ae22fdb09b927569e4ca2` |
| `lib/analyzer_correction_adjudications.json` | `53d5c5344dad792e7c77702592be7ba096d1b5af23534731d65b9fd5d03543c7` |
| `lib/architecture_routing.py` | `5bee4e10d2662607f5c2c4a4681864cfdb6e3b7e05bf9cedde708f328a362781` |
| `platforms.yaml` | `85001db8cc9987b569b512156f9a12371ff01be4598ec974155292b98b9550cd` |

### Production run artifacts

| Artifact | SHA-256 |
|----------|---------|
| `tmp/.../rhoai.next-20260720T193556Z-104162/run.json` | `fccdfed9abf8ee8811b3a960e24a84259de4a9b158078d1a9ddf87a2f7e5c87e` |
| `tmp/.../rhoai.next-20260720T193556Z-104162/reports/comparison.json` | `084faa5559e8f7fc8f3cb305e9ee1600cbf79d16a5ac4ccefa7971b4e2b25247` |
| `tmp/.../rhoai.next-20260720T193556Z-104162/reports/comparison.md` | `2e1ff3405addd0b6fee09af7811e1284f078256a9a8f60bc1aeadaf026c7518f` |

### Representative component documents

| Artifact | SHA-256 |
|----------|---------|
| `architecture/rhoai.next/PLATFORM.md` | `e50ee08d1642b7204f0c71389f3aca94174388c4f470e7b1cab8fcf492295687` |
| `architecture/rhoai.next/kserve.md` | `5087ee676e2f3b40596c4dde3849df8e8cea069b82a6febf562fa0a1f3fee0fa` |
| `architecture/rhoai.next/model-registry.md` | `af277193b6f9c80445978418b5dc576fcc372fe44cdcdb78258eb80f45905926` |
| `architecture/rhoai.next/rhods-operator.md` | `084c6a22dd525962a8a8534942c0cce845c80723672cd6c7e043f9a5cf7f80a2` |
| `architecture/rhoai.next/vllm.md` | `f849cf824c095ce5f5d9cc1ecbf274c515eff3fcbeda0428d10ff15e44e7ccad` |
| `architecture/rhoai.next/odh-dashboard.md` | `5506257a02acaf1ddd846ea63bf84cead04606c0cbb12303f020ba2c50d8341f` |

All 92 component `.md` files and 94 `.json` files in `architecture/rhoai.next/` are
tracked in git at the v1 commit. The full set is pinned by commit SHA; the
representative sample above provides a quick spot-check without hashing the entire
directory.

## Consumer Smoke Test

12 questions exercising inventory, component-fact, integration/data-flow, and
security categories against the v1 output. Each question has an expected answer and
source citation. No subjective prose comparisons.

### Inventory

**Q1. How many components does the RHOAI.next platform analyze?**

Expected answer: 92 components analyzed, per PLATFORM.md metadata.

Source: `architecture/rhoai.next/PLATFORM.md`, line 11 — "Components Analyzed: 92".

**Q2. How many components are approved for analyzer-only generation (no agent)?**

Expected answer: 37 components.

Source: `lib/analyzer_only_approvals.json` — 37 entries in the `components` array.

**Q3. What routing decision does the system make for `mlflow`?**

Expected answer: `mlflow` is routed to `evidence-gated` (not analyzer-only). It has
5 unresolved mutations in the Python runtime residual category.

Source: `lib/analyzer_only_approvals.json` does not contain `mlflow`.
`docs/notes/analyzer-residual-agent-gaps.md`, line 62 — "mlflow | 5 | Python
runtime | FastAPI routes without auth middleware at mlflow/gateway/app.py".

### Component Facts

**Q4. What is the deployment type of `kserve`?**

Expected answer: Operator (multi-controller) + Python SDK + Sidecar utilities.

Source: `architecture/rhoai.next/kserve.md`, line 9.

**Q5. What CRD does `trainer-operator` define?**

Expected answer: `Trainer` (components.platform.opendatahub.io/v1alpha1), cluster-scoped,
singleton CR (`default-trainer`) controlling deployment of Kubeflow Trainer v2.

Source: `architecture/rhoai.next/trainer-operator.md`, lines 35-37 (CRDs table).

**Q6. What languages is `odh-dashboard` written in?**

Expected answer: TypeScript and Go.

Source: `architecture/rhoai.next/odh-dashboard.md`, line 8 — "Languages: TypeScript, Go".

**Q7. Does `model-registry` define its own CRDs?**

Expected answer: No. The document explicitly states that model-registry does not
define CRDs; it watches KServe InferenceService CRDs from other components.

Source: `architecture/rhoai.next/model-registry.md`, line after the CRDs table —
"No CRDs are defined by this component."

### Integration and Data Flow

**Q8. What internal platform dependencies does `data-science-pipelines-operator` have on other RHOAI components?**

Expected answer: It depends on rhods-operator (deployment management), MLflow
Operator (CRD watch for auto-detection), KServe (RBAC for InferenceService),
CodeFlare/MCAD (AppWrapper RBAC), Ray (RayCluster RBAC), Seldon (SeldonDeployment
RBAC), OpenShift Service CA (TLS), and odh-trusted-ca-bundle (CA trust chain).

Source: `architecture/rhoai.next/data-science-pipelines-operator.md`, lines 79-89
(Internal Platform Dependencies table).

**Q9. Which components does overlay 0011 (KServe LLMInferenceService and llm-d integration architecture) affect?**

Expected answer: kserve, odh-model-controller, llm-d-inference-scheduler,
llm-d-router, llm-d-kv-cache.

Source: `overlays/0011-kserve-llm-d-architecture.md`, frontmatter lines 6-11.

**Q10. If the v1 `kserve.md` document and overlay 0011 both discuss LLMInferenceService, which takes precedence for consumers?**

Expected answer: Overlay 0011 takes precedence for information within its scope.
Overlays are active corrections that patch architecture documents between
regeneration cycles. Consumers match by `status: active` and the `affects` list.
The overlay provides updated integration architecture for KServe's llm-d integration
that may supersede or extend the generated `kserve.md` content.

Source: `overlays/README.md` defines overlay precedence semantics. Overlay 0011
has `status: active` and `affects: [kserve, ...]`.

### Security and Undocumented Facts

**Q11. What authentication mechanisms does `model-registry` use for its REST API?**

Expected answer: The `/api/model_registry/*` endpoints use Istio AuthorizationPolicy
enforced at the Istio sidecar proxy. The policy allows requests from the
istio-ingressgateway ServiceAccount and internal requests with JWT, while blocking
kubeflow-userid header spoofing. Controller metrics on port 8443 use RBAC via
controller-runtime FilterProvider. The UI BFF supports Bearer token or internal SA
authentication.

Source: `architecture/rhoai.next/model-registry.md`, lines 302-306 (Authentication
& Authorization table).

**Q12. Does the v1 output document mlflow's per-route authentication enforcement for individual FastAPI gateway endpoints (e.g., `/api/2.0/gateway/routes/`)?**

Expected answer: No. The v1 output documents mlflow's general security middleware
(host header validation, CORS blocking, K8s ServiceAccount bearer tokens, HTTP
Basic Auth fallback) but does not document per-route authentication enforcement for
individual FastAPI gateway endpoints. This is a known residual gap — mlflow has 5
unresolved mutations in the Python runtime category, specifically "FastAPI routes
without auth middleware at `mlflow/gateway/app.py`".

Source: `architecture/rhoai.next/mlflow.md`, lines 173-179 (Authentication table
shows general mechanisms only). `docs/notes/analyzer-residual-agent-gaps.md`, line
62 confirms the gap.

### Smoke Test Summary

| Category | Questions | Pass criteria |
|----------|:---------:|---------------|
| Inventory | Q1-Q3 | Exact counts match; routing decision correct |
| Component facts | Q4-Q7 | Factual answers match document content |
| Integration/data-flow | Q8-Q10 | Dependencies and overlay precedence correct |
| Security/undocumented | Q11-Q12 | Auth mechanisms match; gap honestly acknowledged |

No catastrophic consumer regressions identified. All expected answers are verifiable
from the v1 output. The one known limitation (mlflow per-route auth) is correctly
classified as a residual gap with a pending extraction task, not an unexplained
regression.

## Comparison Report Summary

The final production run comparison report
(`tmp/.../rhoai.next-20260720T193556Z-104162/reports/comparison.md`) records:

- Baseline: 92 documents; candidate: 90 documents; matched: 90
- Missing candidates: llama-stack, llama-stack-k8s-operator (renamed/superseded)
- Analyzer identities retained unchanged: 8614/8618 (99.95%)
- Accepted analyzer-to-final conflicts: 15 (all accepted)
- Accepted analyzer row corrections: 4
- Unexplained conflicts: 0
- All gates: PASS

## Next Steps

This baseline is the candidate for the post-migration consumer evaluation:

1. [Build post-migration consumer benchmark](../tasks/pending/build-post-migration-consumer-benchmark.md)
2. [Run analyzer v1 consumer A/B evaluation](../tasks/pending/run-analyzer-v1-consumer-ab-evaluation.md)
3. [Triage analyzer v2 quality backlog](../tasks/pending/triage-analyzer-v2-quality-backlog.md)

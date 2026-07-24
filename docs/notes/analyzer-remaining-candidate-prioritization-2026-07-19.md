# Analyzer Remaining Candidate Prioritization, 2026-07-19

## Summary

This report classifies and ranks all 29 false deterministic candidates from the
post-`odh-cli` replay. Each component is accounted for exactly once with its
correction state, blocking categories, evidence quality, repository shape, likely
reusable extraction contract, negative controls, historical cost, risk, and
recommended disposition.

## Authoritative Source

Replay: `tmp/architecture-corpus-runs/rhoai-next-cli-kubernetes-static-20260719T180727Z`

| State | Count |
|----------|------:|
| Analyzer-sufficient | 64 |
| Approved analyzer-only | 34 |
| False deterministic candidates | 29 |
| Prose residual (rhods-operator) | 1 |
| False nominations | 0 |
| Correction-bearing candidates | 26 |
| Completeness-only candidates | 3 |
| Total unresolved structured mutations | 168 |

---

## Evidence Quality Audit

The task requires source-auditing corrections based only on go.mod, generated
proto, examples, docs, or tests before accepting them as runtime behavior. The
following evidence classes appear across the 29 candidates:

| Evidence class | Risk | Components affected |
|----------------|------|---------------------|
| `go.mod` direct dependency without runtime call graph | High | llm-d-async, modelmesh-runtime-adapter |
| Generated `.proto` without server registration or RPC call | High | modelmesh-runtime-adapter, caikit |
| `examples/` or `demo/` directory manifests or code | Very high | caikit-tgis-serving, llm-d-kv-cache, distributed-workloads, kube-auth-proxy |
| `benchmarks/` source code | Very high | vllm-cpu, distributed-workloads |
| `tests/e2e/` manifests | Very high | codeflare-sdk |
| `docs/guides/` manifests | High | llm-d-async |
| `pyproject.toml` / `requirements.txt` dependency declaration | High | kubeflow-sdk, codeflare-sdk, MLServer, NeMo-Guardrails, caikit, notebooks, notebooks-downstream, lm-evaluation-harness |
| `ci/` test infrastructure | High | notebooks, notebooks-downstream |
| Production `deploy/` manifests | Low | trustyai-explainability, rhoai-mcp, llm-d-planner, llm-d-routing-sidecar, llm-d-batch-gateway-operator |
| Runtime Go/Python source in shipped entrypoints | Low | eval-hub, argo-workflows, kube-auth-proxy, rhaii-cluster-validation, mlflow, llm-d-latency-predictor, ai-gateway-payload-processing |

---

## Cluster Analysis

### Cluster A: Completeness-Only (0 unresolved mutations)

These three components have zero unresolved structured mutations. They remain
false candidates only because one or more high-value categories are empty and not
yet proven complete.

#### guardrails-regex-detector

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/0 corrections; eligible=false |
| Blocking categories | Integration Points |
| Contract-complete empty | Internal Dependencies |
| Unresolved corrections | 0 |
| Repository shape | Rust binary, regex-based text detector, no external API calls |
| Historical cost | 150.0s, $0.6013, 6 reads, 2 source files, 5,972 output tokens |
| Evidence path | `analyzer/rhoai.next/guardrails-regex-detector.json` |
| Likely contract | Completeness audit: prove Integration Points is legitimately empty for a standalone regex processor with no outbound connections |
| Negative controls | Must not infer integration from Rust crate dependencies without runtime call evidence |
| Risk | Low. Standalone text processor with no network clients |
| Disposition | **Completeness audit**. Smallest scope of any candidate |

#### model-registry

| Field | Value |
|-------|-------|
| Replay state | False candidate; 2/2 resolved corrections; eligible=false |
| Blocking categories | Internal Dependencies |
| Unresolved corrections | 0 |
| Repository shape | Go gRPC/REST server, MLMD backend, multiple storage adapters |
| Historical cost | 202.9s, $1.0476, 8 reads, 4 source files, 9,314 output tokens |
| Evidence path | `analyzer/rhoai.next/model-registry.json` |
| Likely contract | Completeness audit: prove Internal Dependencies is legitimately empty or extract remaining platform dependencies from runtime source |
| Negative controls | Must not infer dependencies from go.mod alone without construction and call evidence |
| Risk | Low. Corrections already resolved; only completeness remains |
| Disposition | **Completeness audit**. Near-ready; may complete with existing extractors |

#### ogx

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/0 corrections; eligible=false |
| Blocking categories | Authentication, Internal Dependencies |
| Unresolved corrections | 0 |
| Repository shape | Python application, inference gateway, model orchestration |
| Historical cost | 168.2s, $0.7168, 8 reads, 4 source files, 7,660 output tokens |
| Evidence path | `analyzer/rhoai.next/ogx.json` |
| Likely contract | Completeness audit: prove Authentication and Internal Dependencies are legitimately empty or extract missing surfaces from shipped entrypoints |
| Negative controls | Must not infer auth from framework imports without middleware registration |
| Risk | Low-medium. Two empty categories to audit |
| Disposition | **Completeness audit** |

**Cluster A totals**: 3 components, 0 unresolved mutations, $2.37 historical cost,
486.1s historical time.

---

### Cluster B: Go HTTP Server Authentication and Components (runtime source evidence)

These components have Go HTTP servers with authentication middleware, route
registration, and Kubernetes client construction that can be deterministically
extracted using existing or near-existing contracts. Evidence quality is high
because corrections cite shipped runtime source locations.

#### eval-hub

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/8 resolved; eligible=false |
| Blocking categories | Architecture Components, Authentication, Internal Dependencies |
| Unresolved corrections | 8 |
| Correction detail | 3 Architecture Components (HTTP server, metrics server, K8s helper), 2 Internal Dependencies (HardwareProfile CR, kube-rbac-proxy), 3 Authentication (/api/v1/evaluations/*, /api/v1/health, /metrics) |
| Evidence quality | **Strong**: all from `internal/` Go source (server.go, metrics_server.go, k8s_helper.go) |
| Repository shape | Go, single shipped binary, net/http.ServeMux, separate metrics server, dynamic K8s client |
| Historical cost | 203.3s, $0.9234, 7 reads, 4 source files, 8,658 output tokens |
| Evidence paths | `analyzer/rhoai.next/eval-hub.json`, `logs/agents/eval-hub.merge.json` |
| Likely contract | Extend Go mux analysis: registered routes, middleware chains, identity headers, dynamic K8s client operations |
| Negative controls | Reject X-User logging as proof of kube-rbac-proxy without manifest or source correlation; reject local-mode identity bypass as universal enforcement |
| Risk | Medium. Conditional identity enforcement requires mode-aware analysis |
| Disposition | **Extractor tranche**. Existing task: [extract-eval-hub-runtime-boundaries.md](../tasks/pending/extract-eval-hub-runtime-boundaries.md) |

#### argo-workflows

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/5 resolved; eligible=false |
| Blocking categories | Authentication, Internal Dependencies |
| Unresolved corrections | 5 |
| Correction detail | 5 Authentication (/api/*, /oauth2/callback, /oauth2/redirect, /artifacts/*, /healthz) |
| Evidence quality | **Mixed**: go.mod for OIDC/OAuth2 deps, but /healthz from runtime source (`cmd/workflow-controller/main.go:181-184`) |
| Source audit warning | OIDC/OAuth2 corrections cite `go.mod` lines, not runtime handler chains. go.mod line 23 (coreos/go-oidc/v3) and line 68 (golang.org/x/oauth2) prove the library is available, not that specific routes enforce SSO. The /api/* and /artifacts/* corrections must be validated through actual middleware registration, not dependency presence |
| Repository shape | Go, multiple binaries (argo-server, workflow-controller), large codebase |
| Historical cost | 233.7s, $1.1690, 7 reads, 4 source files, 11,396 output tokens |
| Evidence paths | `analyzer/rhoai.next/argo-workflows.json`, `logs/agents/argo-workflows.merge.json` |
| Likely contract | Extend Go HTTP auth mux analysis to cover OIDC/OAuth2 middleware registration, SSO provider configuration, and route-level auth policy |
| Negative controls | Reject go.mod dependency as proof of route-level auth enforcement; require middleware chain correlation |
| Risk | Medium-high. Large codebase; auth middleware may use dynamic dispatch or plugin patterns |
| Disposition | **Extractor tranche**. Groups with eval-hub under Go HTTP auth pattern |

#### kube-auth-proxy

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/2 resolved; eligible=false |
| Blocking categories | Authentication, Internal Dependencies |
| Unresolved corrections | 2 |
| Correction detail | 1 Authentication (OAuth2 proxy config from examples/openshift), 1 Authentication (TokenReview validation from `pkg/authentication/k8s/tokenreview.go:78-114`) |
| Evidence quality | **Mixed**: TokenReview is strong runtime source; OAuth2 correction cites `examples/openshift/service-account/` |
| Source audit warning | The OAuth2 correction at `examples/openshift/service-account/config.yaml:8-33` and `examples/openshift/service-account/deployment.yaml:32-116` is from the `examples/` directory. This is not production deployment evidence. The TokenReview correction is from shipped `pkg/` source and is valid |
| Repository shape | Go, authentication proxy, multiple auth backends |
| Historical cost | 199.0s, $0.8646, 8 reads, 4 source files, 9,204 output tokens |
| Evidence paths | `analyzer/rhoai.next/kube-auth-proxy.json`, `logs/agents/kube-auth-proxy.merge.json` |
| Likely contract | Extend Go auth extraction: TokenReview client construction and concrete auth backend registration |
| Negative controls | Reject example directory manifests as production deployment evidence |
| Risk | Low-medium. One correction is example-only; the other is strong runtime source |
| Disposition | **Extractor tranche + source adjudication** for the examples/ correction |

#### rhaii-cluster-validation

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/5 resolved; eligible=false |
| Blocking categories | Architecture Components, Authentication, Internal Dependencies |
| Unresolved corrections | 5 |
| Correction detail | 1 Architecture Component (CLI controller), 3 Internal Dependencies (RHOAI CRDs, RHOAI operators, NVIDIA GPU Operator), 1 Authentication (kubeconfig/SA token) |
| Evidence quality | **Strong**: all from `pkg/controller/controller.go` shipped source |
| Repository shape | Go, CLI tool, Kubernetes client, CRD/operator/GPU validation |
| Historical cost | 181.0s, $1.2173, 7 reads, 3 source files, 7,910 output tokens |
| Evidence paths | `analyzer/rhoai.next/rhaii-cluster-validation.json`, `logs/agents/rhaii-cluster-validation.merge.json` |
| Likely contract | Extend CLI Kubernetes client and CRD inspection patterns from odh-cli tranche; add platform-component health-check and GPU resource discovery |
| Negative controls | Reject CRD list as static dependency unless runtime code queries apiextensions API |
| Risk | Low. Clean Go CLI with well-structured controller pattern, similar to odh-cli |
| Disposition | **Extractor tranche**. High affinity with the completed odh-cli contracts |

#### ai-gateway-payload-processing

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/5 resolved; eligible=false |
| Blocking categories | Architecture Components, Authentication |
| Unresolved corrections | 5 |
| Correction detail | 3 Architecture Components (ExternalProvider, ExternalModel, legacy migration controllers), 2 Internal Dependencies (Gateway API, Istio) |
| Evidence quality | **Strong**: all from `cmd/controllers.go` shipped source with exact line references |
| Repository shape | Go, controller-runtime operator, Gateway API + Istio CRDs |
| Historical cost | 187.4s, $0.9432, 8 reads, 4 source files, 8,588 output tokens |
| Evidence paths | `analyzer/rhoai.next/ai-gateway-payload-processing.json`, `logs/agents/ai-gateway-payload-processing.merge.json` |
| Likely contract | Extend controller registration extraction: reconciler setup with typed CRD watches and created resource patterns |
| Negative controls | Reject function comments as runtime evidence; require actual reconciler setup builder calls |
| Risk | Low. Clean controller-runtime pattern with explicit registration |
| Disposition | **Extractor tranche**. Groups with Go controller component extraction |

**Cluster B totals**: 5 components, 25 unresolved mutations, $5.12 historical cost,
1,004.4s historical time.

---

### Cluster C: Kubernetes Deployment Manifest Evidence

These components have corrections based primarily on production deployment manifests
(`deploy/`, `manifests/`). Manifest-derived evidence is mechanical and relatively
low risk when sourced from selected deployment configurations rather than
examples or demos.

#### trustyai-explainability

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/9 resolved; eligible=false |
| Blocking categories | Authentication, Integration Points, Internal Dependencies |
| Unresolved corrections | 9 |
| Correction detail | 4 Internal Dependencies (ConfigMap, PVC, model-serving-config, ose-cli image), 2 Authentication (health/ready probes), 3 Integration Points (KServe payload processor, Prometheus scraping, K8s API via oc apply) |
| Evidence quality | **Strong**: all from `explainability-service/manifests/base/trustyai-deployment.yaml` production manifests |
| Repository shape | Java/Quarkus service, Kubernetes Deployment with init container, PVC storage |
| Historical cost | 239.8s, $0.8513, 6 reads, 2 source files, 11,696 output tokens |
| Evidence paths | `analyzer/rhoai.next/trustyai-explainability.json`, `logs/agents/trustyai-explainability.merge.json` |
| Likely contract | Manifest-based extraction: ConfigMap env injection, PVC mounts, init container image references, Prometheus scraping annotations, probe endpoint authentication |
| Negative controls | Reject init container image as Internal Dependency if only used for tooling; validate ConfigMap is consumed by main container |
| Risk | Low. Production manifests with clear Kubernetes patterns |
| Disposition | **Extractor tranche**. High reuse for manifest-based dependency and auth extraction |

#### rhoai-mcp

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/2 resolved; eligible=false |
| Blocking categories | Authentication |
| Unresolved corrections | 2 |
| Correction detail | 1 Authentication (/health probe, no auth), 1 Authentication (ServiceAccount token for K8s API) |
| Evidence quality | **Strong**: from `deploy/kustomize/base/deployment.yaml` and `deploy/kustomize/base/clusterrolebinding.yaml` production manifests |
| Repository shape | Go/Python, MCP server, Kubernetes API client |
| Historical cost | 237.0s, $0.8408, 8 reads, 4 source files, 11,042 output tokens |
| Evidence paths | `analyzer/rhoai.next/rhoai-mcp.json`, `logs/agents/rhoai-mcp.merge.json` |
| Likely contract | Manifest probe authentication (httpGet without auth headers) and ServiceAccount RBAC binding |
| Negative controls | Must verify probe path is actually registered in shipped source |
| Risk | Low. Only 2 corrections, both from production Kustomize base |
| Disposition | **Extractor tranche**. Small scope, high certainty |

#### llm-d-routing-sidecar

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/2 resolved; eligible=false |
| Blocking categories | Authentication, Internal Dependencies |
| Unresolved corrections | 2 |
| Correction detail | 1 Internal Dependency (operator-controller-manager ServiceAccount), 1 Authentication (no TLS, no auth sidecar on 8080/TCP) |
| Evidence quality | **Strong**: from `deploy/common/patch-statefulset.yaml` and `deploy/openshift/patch-route.yaml` production manifests |
| Repository shape | Go, StatefulSet sidecar, HTTP proxy |
| Historical cost | 193.5s, $0.7429, 8 reads, 4 source files, 9,217 output tokens |
| Evidence paths | `analyzer/rhoai.next/llm-d-routing-sidecar.json`, `logs/agents/llm-d-routing-sidecar.merge.json` |
| Likely contract | Manifest ServiceAccount binding and TLS/auth sidecar absence detection |
| Negative controls | Must not treat templated `${project_name}-service` as concrete identity |
| Risk | Low. Only 2 corrections from production deploy patches |
| Disposition | **Extractor tranche**. Groups with manifest auth pattern |

#### llm-d-batch-gateway-operator

| Field | Value |
|-------|-------|
| Replay state | False candidate; 2/4 resolved, 2 unresolved; eligible=false |
| Blocking categories | Internal Dependencies |
| Unresolved corrections | 2 |
| Correction detail | 1 Internal Dependency (opendatahub-operator env vars from `cmd/main.go:33-62`), 1 Authentication (metrics endpoint auth from `cmd/main.go:106-109`) |
| Evidence quality | **Strong**: from shipped `cmd/main.go` source with exact line references |
| Repository shape | Go, controller-runtime operator, manages batch gateway sub-components |
| Historical cost | 242.4s, $1.0450, 8 reads, 4 source files, 11,157 output tokens |
| Evidence paths | `analyzer/rhoai.next/llm-d-batch-gateway-operator.json`, `logs/agents/llm-d-batch-gateway-operator.merge.json` |
| Likely contract | Operator env-var dependency injection and controller-runtime metrics server auth |
| Negative controls | Source comment "cannot read params.env" must not be interpreted as a dependency declaration |
| Risk | Low. Two focused corrections from shipped source |
| Disposition | **Extractor tranche**. Groups with Go controller auth/dependency pattern |

#### llm-d-planner

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/12 resolved; eligible=false |
| Blocking categories | Integration Points, Internal Dependencies |
| Unresolved corrections | 12 |
| Correction detail | 3 Internal Dependencies (OpenShift Router, Service CA, K8s API), 2 Authentication (no-auth API, DB admin password), 7 Integration Points (Postgres, Ollama, K8s API, OpenAI, HuggingFace, Vertex AI, Model Catalog) |
| Evidence quality | **Strong**: all from `deploy/kubernetes/backend.yaml` and `deploy/kubernetes/gpu-reader-rbac.yaml` production manifests with exact line references |
| Repository shape | Python FastAPI backend + frontend, multiple external LLM integrations, PostgreSQL |
| Historical cost | 242.2s, $1.0245, 8 reads, 4 source files, 11,938 output tokens |
| Evidence paths | `analyzer/rhoai.next/llm-d-planner.json`, `logs/agents/llm-d-planner.merge.json` |
| Likely contract | Manifest env-var service binding (DATABASE_URL, OLLAMA_HOST, OPENAI_API_KEY, etc.), Secret-sourced credentials, ServiceAccount RBAC, OpenShift Route/Service CA dependencies |
| Negative controls | Must not promote configurable external services (Vertex AI, OpenAI) as guaranteed platform dependencies; they are optional backends |
| Risk | Medium. 12 corrections is large but all from production manifests with clear env-var patterns |
| Disposition | **Extractor tranche**. Highest correction count in this cluster |

**Cluster C totals**: 5 components, 27 unresolved mutations, $4.50 historical cost,
954.9s historical time.

---

### Cluster D: Go gRPC Server/Client Runtime Relationships

#### modelmesh-runtime-adapter

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/10 resolved; eligible=false |
| Blocking categories | Integration Points, Internal Dependencies |
| Unresolved corrections | 10 |
| Correction detail | 2 Internal Dependencies (ModelMesh, modelmesh-serving), 8 Integration Points (ModelMesh gRPC inbound/outbound, Triton/TorchServe/MLServer gRPC clients, GCS/Azure/IBM COS storage) |
| Evidence quality | **Weak**: Internal Dependencies cite proto file and go.mod module path. Integration Points for backend gRPC clients cite proto files. Storage clients cite go.mod direct dependencies only |
| Source audit warning | 2/2 Internal Dependency corrections rely on proto definition (`internal/proto/mmesh/model-mesh.proto:28-62`) and go.mod module path (`go.mod:1`) without construction or call evidence. 5/8 Integration Point corrections rely on proto file definitions without runtime server registration or outbound RPC call proof. 3/8 storage corrections cite `go.mod` direct dependencies without client construction or operation evidence |
| Repository shape | Go, multiple adapter binaries (triton, torchserve, mlserver, ovms), gRPC server/client, storage providers |
| Historical cost | 226.9s, $1.0727, 8 reads, 4 source files, 11,234 output tokens |
| Evidence paths | `analyzer/rhoai.next/modelmesh-runtime-adapter.json`, `logs/agents/modelmesh-runtime-adapter.merge.json` |
| Likely contract | Runtime gRPC server registration scan, outbound gRPC dial-and-call verification, storage provider factory registration with concrete client construction |
| Negative controls | Reject proto definitions without `grpc.NewServer` + `Register*Server` correlation; reject go.mod without `New*Client` construction; reject copied third-party proto as integration evidence |
| Risk | High. Most corrections need new gRPC analysis capability. Proto-only and go.mod-only evidence is the weakest evidence class |
| Disposition | **Extractor tranche**. Existing task: [extract-modelmesh-runtime-relationships.md](../tasks/pending/extract-modelmesh-runtime-relationships.md) |

**Cluster D totals**: 1 component, 10 unresolved mutations, $1.07 historical cost,
226.9s historical time.

---

### Cluster E: Python Runtime Source Evidence

These components have corrections based on shipped Python source code with actual
client construction and API calls, distinguishable from pure dependency
declarations.

#### mlflow

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/4 resolved; eligible=false |
| Blocking categories | Authentication, Internal Dependencies |
| Unresolved corrections | 4 |
| Correction detail | 4 Authentication (/v1/chat/completions, /v1/completions, /v1/embeddings, /health — all unauthenticated FastAPI endpoints in gateway) |
| Evidence quality | **Strong**: all from `mlflow/gateway/app.py` shipped source with exact line references showing no auth middleware |
| Repository shape | Python, FastAPI, tracking server + AI gateway, multiple LLM backends |
| Historical cost | 211.1s, $0.9679, 8 reads, 4 source files, 10,359 output tokens |
| Evidence paths | `analyzer/rhoai.next/mlflow.json`, `logs/agents/mlflow.merge.json` |
| Likely contract | Python FastAPI route registration with auth middleware chain analysis |
| Negative controls | Must not conflate rate limiter (slowapi) with authentication |
| Risk | Low-medium. Clear FastAPI route definitions with visible middleware absence |
| Disposition | **Extractor tranche**. Groups with Python HTTP auth surface extraction |

#### lm-evaluation-harness

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/4 resolved; eligible=false |
| Blocking categories | Authentication, Internal Dependencies |
| Unresolved corrections | 4 |
| Correction detail | 4 Authentication (Anthropic API key, WatsonX IAM, OpenAI API key, HuggingFace token) |
| Evidence quality | **Strong**: all from shipped Python source (`lm_eval/models/anthropic_llms.py`, `ibm_watsonx_ai.py`, `openai_completions.py`, `__main__.py`) showing credential construction and API calls |
| Repository shape | Python, CLI evaluation framework, multiple LLM provider backends |
| Historical cost | 222.3s, $1.0793, 7 reads, 4 source files, 10,813 output tokens |
| Evidence paths | `analyzer/rhoai.next/lm-evaluation-harness.json`, `logs/agents/lm-evaluation-harness.merge.json` |
| Likely contract | Python outbound API client credential extraction: env-var credential sourcing, SDK client construction, explicit header/token injection |
| Negative controls | Must not treat optional HF_TOKEN as required authentication surface |
| Risk | Medium. These are outbound client auth surfaces, not served endpoints. Distinguish optional vs required credentials |
| Disposition | **Extractor tranche**. Reusable Python outbound client credential pattern |

#### llm-d-latency-predictor

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/3 resolved; eligible=false |
| Blocking categories | Integration Points, Internal Dependencies |
| Unresolved corrections | 3 |
| Correction detail | 1 Internal Dependency (training-server model download), 1 Authentication (unauthenticated HTTP endpoints), 1 Integration Point (training-server HTTP client polling) |
| Evidence quality | **Strong**: from shipped `src/llm_d_latency_predictor/prediction_server.py` Python source and `deploy/dual-server-deployment.yaml` |
| Repository shape | Python, FastAPI, dual prediction/training servers, HTTP client for model sync |
| Historical cost | 194.8s, $1.8426, 9 reads, 4 source files, 8,831 output tokens |
| Evidence paths | `analyzer/rhoai.next/llm-d-latency-predictor.json`, `logs/agents/llm-d-latency-predictor.merge.json` |
| Likely contract | Python FastAPI route auth analysis + outbound HTTP client construction |
| Negative controls | Must verify training-server is a shipped runtime component, not a separate deployment |
| Risk | Low. Clean dual-server pattern with explicit HTTP client construction |
| Disposition | **Extractor tranche**. Groups with Python HTTP server + client pattern |

#### NeMo-Guardrails

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/4 resolved; eligible=false |
| Blocking categories | Integration Points, Internal Dependencies |
| Unresolved corrections | 4 |
| Correction detail | 4 Integration Points (Azure OpenAI client, OpenAI-compatible LLM, third-party guardrail services via ActionDispatcher, OTLP telemetry) |
| Evidence quality | **Medium**: Azure OpenAI from shipped source (`nemoguardrails/embeddings/providers/azureopenai.py:49-56`); ActionDispatcher from `actions_server/actions_server.py:36-37`; OTLP from analyzer baseline dependency list |
| Source audit warning | The OTLP correction references `actions_server.py:19-33` but cites "analyzer baseline lists" as evidence rather than runtime instantiation. The "13 API key secrets in the analyzer baseline" for third-party services is analyzer output, not source evidence |
| Repository shape | Python, FastAPI actions server, dynamic action loading, multiple LLM backends |
| Historical cost | 156.6s, $0.9981, 8 reads, 4 source files, 6,987 output tokens |
| Evidence paths | `analyzer/rhoai.next/NeMo-Guardrails.json`, `logs/agents/NeMo-Guardrails.merge.json` |
| Likely contract | Python SDK client construction pattern (Azure OpenAI instantiation); Python OTLP exporter dependency-and-init correlation |
| Negative controls | Reject analyzer baseline output as source evidence; require concrete exporter initialization |
| Risk | Medium. Dynamic action loading makes static analysis unreliable for third-party service inventory |
| Disposition | **Extractor tranche + source adjudication** for analyzer-baseline-derived corrections |

**Cluster E totals**: 4 components, 15 unresolved mutations, $4.89 historical cost,
784.8s historical time.

---

### Cluster F: Python Dependency Declaration Evidence (high false-positive risk)

These components have corrections derived primarily from `pyproject.toml` or
`requirements.txt` dependency declarations. Dependency presence does not prove
runtime use by any shipped entrypoint. Each correction must be validated through
import and construction analysis before it can be used as extractor ground truth.

#### kubeflow-sdk

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/14 resolved; eligible=false |
| Blocking categories | Authentication, Integration Points, Internal Dependencies |
| Unresolved corrections | 14 |
| Correction detail | 5 Internal Dependencies (training operator, Katib, Spark, Model Registry, K8s API), 4 Authentication (K8s kubeconfig, S3 credentials, Model Registry REST, HF token), 5 Integration Points (K8s API, training, Spark, Katib, Model Registry, S3 storage) |
| Evidence quality | **Weak**: all 14 corrections cite `pyproject.toml` line numbers for dependency declarations. No runtime call graph or SDK operation evidence |
| Source audit warning | Every correction is a pyproject.toml dependency declaration. `pyproject.toml:31` (kubeflow-trainer-api), `pyproject.toml:32` (kubeflow-katib-api), `pyproject.toml:52` (kubeflow-spark-api), `pyproject.toml:55` (model-registry), `pyproject.toml:29` (kubernetes). Optional extras (`rhai`, `hub`, `spark`) must not be treated as required runtime dependencies |
| Repository shape | Python, SDK library (not a server), CRD CRUD operations, multiple optional integrations |
| Historical cost | 208.1s, $1.0700, 10 reads, 4 source files, 9,785 output tokens |
| Evidence paths | `analyzer/rhoai.next/kubeflow-sdk.json`, `logs/agents/kubeflow-sdk.merge.json` |
| Likely contract | Python import-and-construction analysis: trace pyproject.toml deps through actual SDK methods that construct typed clients and execute API operations |
| Negative controls | Reject optional extras as required dependencies; reject pyproject.toml presence without import; reject SDK interface declarations without CRD CRUD execution |
| Risk | Very high. 14 corrections all from pyproject.toml. Extracting runtime use requires Python call graph analysis which is complex and not yet supported |
| Disposition | **Justified agent residual or future Python extractor tranche**. Highest false-positive risk. Cannot safely extract without runtime import analysis |

#### codeflare-sdk

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/7 resolved; eligible=false |
| Blocking categories | Authentication, Integration Points, Internal Dependencies |
| Unresolved corrections | 7 |
| Correction detail | 2 Internal Dependencies (CodeFlare Operator, KubeRay), 2 Authentication (MinIO S3 9000/TCP, MinIO console 9090/TCP), 3 Integration Points (K8s API, OpenShift API, Ray cluster) |
| Evidence quality | **Weak**: Internal Dependencies from `pyproject.toml:2-4` and `pyproject.toml:26-27`. Authentication from `tests/e2e/minio_deployment.yaml:69-79` (test fixtures). Integration Points from `pyproject.toml` dependency declarations |
| Source audit warning | 2/2 Authentication corrections cite `tests/e2e/minio_deployment.yaml` — this is test infrastructure, not production runtime. 2/3 Integration Point corrections cite pyproject.toml only. 2/2 Internal Dependency corrections cite pyproject.toml only |
| Repository shape | Python, SDK library, Ray/Kubernetes client, test fixtures with MinIO |
| Historical cost | 234.0s, $0.8588, 6 reads, 2 source files, 11,433 output tokens |
| Evidence paths | `analyzer/rhoai.next/codeflare-sdk.json`, `logs/agents/codeflare-sdk.merge.json` |
| Likely contract | Same as kubeflow-sdk: Python import-and-construction analysis |
| Negative controls | Reject test/e2e fixtures as runtime evidence; reject pyproject.toml deps without import chains |
| Risk | Very high. 2/7 corrections from test directory, remaining from pyproject.toml |
| Disposition | **Source adjudication** (test-derived corrections are invalid) **+ future Python extractor tranche** |

#### MLServer

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/6 resolved; eligible=false |
| Blocking categories | Authentication, Integration Points, Internal Dependencies |
| Unresolved corrections | 6 |
| Correction detail | 1 Internal Dependency (KServe, from proto files), 1 Authentication (no auth in proto/pyproject.toml), 4 Integration Points (KServe runtime, OTLP telemetry, Kafka, Triton client) |
| Evidence quality | **Weak-medium**: proto file evidence is valid for protocol definition but not runtime behavior; pyproject.toml deps prove availability, not use |
| Source audit warning | Internal Dependency `kserve` cites `proto/dataplane.proto:11-48` — proto definition, not runtime serving. Integration Points cite pyproject.toml dependency lines. The absence-of-auth correction is a negative assertion from proto + pyproject.toml, which may be valid but needs verification against actual server startup |
| Repository shape | Python, inference server, gRPC + REST, KFServing V2 protocol implementation |
| Historical cost | 329.1s, $1.3602, 8 reads, 4 source files, 17,690 output tokens |
| Evidence paths | `analyzer/rhoai.next/MLServer.json`, `logs/agents/MLServer.merge.json` |
| Likely contract | Python gRPC service registration + pyproject.toml dependency-with-import correlation |
| Negative controls | Reject proto definition as runtime relationship without server registration; reject pyproject.toml dep without import-and-call chain |
| Risk | High. Proto + dependency evidence requires Python call graph analysis |
| Disposition | **Future Python extractor tranche** |

#### caikit

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/7 resolved; eligible=false |
| Blocking categories | Authentication, Integration Points, Internal Dependencies |
| Unresolved corrections | 7 |
| Correction detail | 1 Internal Dependency (ModelMesh sidecar), 1 Authentication (no auth in proto/pyproject.toml), 5 Integration Points (ModelRuntime gRPC, ModelMesh gRPC, Process gRPC, OTLP trace, Prometheus metrics) |
| Evidence quality | **Weak-medium**: Internal Dependency and Integration Points cite proto files. OTLP and Prometheus cite pyproject.toml optional dependency groups |
| Source audit warning | All Integration Point gRPC corrections cite proto definitions (`model-runtime.proto`, `model-mesh.proto`, `process.proto`) without runtime registration. OTLP cites `pyproject.toml:65-67` optional group. Prometheus cites `pyproject.toml:47-48` optional group |
| Repository shape | Python, ML inference runtime, gRPC services, ModelMesh sidecar |
| Historical cost | 205.2s, $1.0568, 8 reads, 4 source files, 9,638 output tokens |
| Evidence paths | `analyzer/rhoai.next/caikit.json`, `logs/agents/caikit.merge.json` |
| Likely contract | Python gRPC service implementation registration + optional dependency import analysis |
| Negative controls | Reject proto as relationship without gRPC server registration; reject optional pyproject.toml groups without conditional import |
| Risk | High. Similar to MLServer; proto-only gRPC evidence |
| Disposition | **Future Python extractor tranche**. Groups with MLServer |

**Cluster F totals**: 4 components, 34 unresolved mutations, $3.95 historical cost,
976.4s historical time.

---

### Cluster G: Example/Demo/Benchmark-Derived Evidence (very high false-positive risk)

These components have corrections derived primarily or substantially from
example, demo, benchmark, test, or documentation directories. This evidence
class has the highest false-positive risk and should not be accepted without
shipped-runtime correlation.

#### caikit-tgis-serving

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/6 resolved; eligible=false |
| Blocking categories | Authentication, Integration Points, Internal Dependencies |
| Unresolved corrections | 6 |
| Correction detail | 2 Internal Dependencies (KServe, Knative), 1 Authentication (MinIO S3), 3 Integration Points (KServe, MinIO, Prometheus) |
| Evidence quality | **Very weak**: all 6 corrections cite files in `demo/kserve/custom-manifests/` |
| Source audit warning | Every correction references `demo/kserve/custom-manifests/`. This is demonstration infrastructure, not shipped production deployment. The `demo/` directory typically contains user-facing examples, not selected Kubernetes manifests |
| Repository shape | Container images + demo manifests for Caikit TGIS inference serving |
| Historical cost | 220.4s, $0.8617, 8 reads, 4 source files, 10,980 output tokens |
| Evidence paths | `analyzer/rhoai.next/caikit-tgis-serving.json`, `logs/agents/caikit-tgis-serving.merge.json` |
| Likely contract | Requires production manifest discovery or Dockerfile/entrypoint analysis instead of demo/ content |
| Negative controls | Reject all demo/ directory content as production evidence |
| Risk | Very high. 6/6 corrections from demo directory |
| Disposition | **Source adjudication** (demo evidence is invalid) **+ completeness audit** to determine true gaps |

#### distributed-workloads

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/3 resolved; eligible=false |
| Blocking categories | Authentication, Internal Dependencies |
| Unresolved corrections | 3 |
| Correction detail | 1 Internal Dependency (Kubeflow Training Operator from benchmarks), 2 Authentication (MinIO S3 and console from examples) |
| Evidence quality | **Very weak**: Internal Dependency cites `benchmarks/kftv2-mpi-ddp-sft/train_sft_ddp.py:12-13`. Authentication corrections cite `examples/hpo-raytune/resources/setup-minio.yaml` and `examples/stable-diffusion-dreambooth/yaml/distributed/minio.yaml` |
| Source audit warning | All 3 corrections come from `benchmarks/` or `examples/` directories. These are not shipped runtime entrypoints |
| Repository shape | Collection of benchmarks and examples for distributed workloads, no shipped service |
| Historical cost | 219.3s, $1.0615, 8 reads, 4 source files, 9,643 output tokens |
| Evidence paths | `analyzer/rhoai.next/distributed-workloads.json`, `logs/agents/distributed-workloads.merge.json` |
| Likely contract | No shipped runtime to extract from. Needs completeness audit to determine if empty categories are legitimately empty for a benchmark/example collection |
| Negative controls | Reject all benchmarks/ and examples/ content as production evidence |
| Risk | Very high. 3/3 corrections from non-production directories |
| Disposition | **Source adjudication** (all corrections invalid) **+ completeness audit** |

#### llm-d-kv-cache

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/4 resolved; eligible=false |
| Blocking categories | Authentication, Internal Dependencies |
| Unresolved corrections | 4 |
| Correction detail | 1 Internal Dependency (vLLM ZMQ from examples), 3 Authentication (HTTP endpoints from examples) |
| Evidence quality | **Very weak**: all 4 corrections cite `examples/kv_events/online/main.go` |
| Source audit warning | Every correction references `examples/kv_events/online/main.go`. The `examples/` directory contains demonstration code, not shipped production binaries |
| Repository shape | Go libraries and examples for KV cache event processing |
| Historical cost | 227.6s, $1.0122, 8 reads, 4 source files, 10,775 output tokens |
| Evidence paths | `analyzer/rhoai.next/llm-d-kv-cache.json`, `logs/agents/llm-d-kv-cache.merge.json` |
| Likely contract | Needs shipped binary identification (if any exist) or completeness audit |
| Negative controls | Reject all examples/ directory Go source as production runtime |
| Risk | Very high. 4/4 corrections from examples directory |
| Disposition | **Source adjudication** (example evidence is invalid) **+ completeness audit** |

#### llm-d-async

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/4 resolved; eligible=false |
| Blocking categories | Authentication, Internal Dependencies |
| Unresolved corrections | 4 |
| Correction detail | 2 Internal Dependencies (gateway-api-inference-extension from go.mod, Redis from go.mod), 2 Authentication (health/models probe endpoints from docs) |
| Evidence quality | **Weak**: Internal Dependencies cite `go.mod` lines only. Authentication cites `docs/guides/e2e-deploy/modelserver/patch-vllm.yaml:15` |
| Source audit warning | Internal Dependencies at go.mod:29 (gateway-api-inference-extension) and go.mod:23 (go-redis) are dependency declarations without runtime construction evidence. Authentication corrections cite `docs/guides/` — documentation, not production deployment |
| Repository shape | Go, async inference gateway, Redis-backed queue |
| Historical cost | 351.3s, $1.0814, 6 reads, 2 source files, 17,155 output tokens |
| Evidence paths | `analyzer/rhoai.next/llm-d-async.json`, `logs/agents/llm-d-async.merge.json` |
| Likely contract | Go runtime client construction: Redis dial-and-command, GAIE type import-and-use. Shipped binary entrypoint analysis |
| Negative controls | Reject go.mod without construction; reject docs/ manifests as production deployment |
| Risk | High. go.mod + docs evidence. Need runtime call graph |
| Disposition | **Source adjudication** (docs evidence invalid) **+ extractor tranche** for Go client construction |

#### vllm-cpu

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/4 resolved; eligible=false |
| Blocking categories | Authentication, Integration Points, Internal Dependencies |
| Unresolved corrections | 4 |
| Correction detail | 1 Authentication (Bearer token from benchmarks), 3 Integration Points (HuggingFace, prefill vLLM, decode vLLM from benchmarks) |
| Evidence quality | **Very weak**: Authentication cites `benchmarks/backend_request_func.py` lines. Integration Points 2/3 cite `benchmarks/disagg_benchmarks/disagg_prefill_proxy_server.py`. HuggingFace cites pyproject.toml + benchmarks |
| Source audit warning | All 4 corrections derive evidence from `benchmarks/` directory. Benchmark client code tests the server but is not the server itself. The VLLM_API_KEY in the analyzer Secrets table is server-side evidence, but the bearer token correction cites client-side benchmark code. Disaggregated prefill/decode is a benchmark topology, not a production deployment pattern |
| Repository shape | Python, vLLM CPU inference engine fork, extensive benchmarks |
| Historical cost | 196.7s, $1.1226, 8 reads, 4 source files, 9,035 output tokens |
| Evidence paths | `analyzer/rhoai.next/vllm-cpu.json`, `logs/agents/vllm-cpu.merge.json` |
| Likely contract | Needs shipped server entrypoint analysis instead of benchmark client code |
| Negative controls | Reject benchmark client code as server authentication surface; reject benchmark topology as production integration |
| Risk | Very high. 4/4 corrections from benchmarks directory |
| Disposition | **Source adjudication** (benchmark evidence is invalid) **+ completeness audit** |

**Cluster G totals**: 5 components, 21 unresolved mutations, $5.04 historical cost,
1,215.3s historical time.

---

### Cluster H: Container Image Dependency Inventories (notebooks)

These two components are notebook image build repositories. Their corrections
derive from `requirements.txt` files listing bundled Python libraries and from
CI test infrastructure. The correction count is very high (36 combined) but the
evidence represents image-level library availability, not runtime service
integration from shipped entrypoints.

#### notebooks

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/19 resolved; eligible=false |
| Blocking categories | Authentication, Integration Points, Internal Dependencies |
| Unresolved corrections | 19 |
| Correction detail | 8 Internal Dependencies (controller, DSP, CodeFlare, Training, TrustyAI, MLflow, Elyra, Ray), 1 Authentication (JupyterLab UI), 10 Integration Points (controller, DSP, CodeFlare, Training, TrustyAI, MLflow, S3, K8s, Prometheus, OTLP) |
| Evidence quality | **Very weak**: Internal Dependencies cite `jupyter/datascience/ubi9-python-3.12/requirements.cpu.txt` entries and `ci/cached-builds/make_test.py`. Authentication cites requirements.txt. Integration Points cite requirements.txt |
| Source audit warning | All corrections derive from requirements.txt library listings or CI test infrastructure (`ci/cached-builds/make_test.py`). A library in a requirements file is available for notebook users but is not a runtime integration of the notebook image itself. The notebook image has no shipped entrypoint that calls these libraries — they are user-available tools |
| Repository shape | Container image builds (Dockerfiles + requirements.txt), no shipped application code |
| Historical cost | 298.0s, $1.8169, 9 reads, 4 source files, 14,640 output tokens |
| Evidence paths | `analyzer/rhoai.next/notebooks.json`, `logs/agents/notebooks.merge.json` |
| Likely contract | Would require a fundamentally different evidence model: bundled-library inventory rather than runtime integration. This is a semantic question about what constitutes a "dependency" for an image that provides a user environment |
| Negative controls | Reject requirements.txt entries as runtime integration; reject CI test infrastructure as production deployment |
| Risk | Very high. 19/19 corrections from requirements.txt or CI. No shipped application entrypoint |
| Disposition | **Justified agent residual**. The notebook image dependency model (bundled libraries for user consumption) is fundamentally different from runtime service integration and cannot be captured by deterministic source extraction |

#### notebooks-downstream

| Field | Value |
|-------|-------|
| Replay state | False candidate; 0/17 resolved; eligible=false |
| Blocking categories | Authentication, Integration Points, Internal Dependencies |
| Unresolved corrections | 17 |
| Correction detail | 3 Internal Dependencies (controller, codeflare-sdk, rhods-operator), 3 Authentication (notebook pod, S3, K8s), 11 Integration Points (S3, K8s, MySQL, PostgreSQL, MongoDB, ODBC, Kafka, Ray, GCP, Prometheus/OTLP, TensorBoard) |
| Evidence quality | **Very weak**: same pattern as notebooks — requirements.txt listings and CI test infrastructure |
| Source audit warning | Same as notebooks. All corrections from `runtimes/datascience/ubi9-python-3.11/requirements.txt` or `ci/cached-builds/make_test.py` |
| Repository shape | Downstream container image builds, requirements.txt pinning, no shipped application code |
| Historical cost | 199.2s, $1.2945, 8 reads, 4 source files, 10,139 output tokens |
| Evidence paths | `analyzer/rhoai.next/notebooks-downstream.json`, `logs/agents/notebooks-downstream.merge.json` |
| Likely contract | Same as notebooks — requires different evidence model |
| Negative controls | Same as notebooks |
| Risk | Very high. 17/17 corrections from requirements.txt or CI |
| Disposition | **Justified agent residual**. Same reasoning as notebooks |

**Cluster H totals**: 2 components, 36 unresolved mutations, $3.11 historical cost,
497.2s historical time.

---

## Ranked Work Queue

Priority is determined by: expected avoided agent time/cost, corpus reuse
(components sharing the extractor pattern), implementation complexity, and
false-positive risk. A high correction count with weak evidence is ranked lower
than a small count with strong evidence.

| Rank | Cluster | Components | Corrections | Historical cost | Reuse | Complexity | Risk | Disposition |
|-----:|---------|:----------:|------------:|----------------:|-------|------------|------|-------------|
| 1 | A: Completeness-only | 3 | 0 | $2.37 | Medium | Low | Low | Completeness audit |
| 2 | B: Go HTTP auth + components | 5 | 25 | $5.12 | High | Medium | Low-medium | Extractor tranche |
| 3 | C: K8s manifest evidence | 5 | 27 | $4.50 | High | Medium | Low-medium | Extractor tranche |
| 4 | D: Go gRPC relationships | 1 | 10 | $1.07 | Low | High | High | Extractor tranche |
| 5 | E: Python runtime source | 4 | 15 | $4.89 | Medium | Medium-high | Medium | Extractor tranche + adjudication |
| 6 | G: Example/demo/benchmark evidence | 5 | 21 | $5.04 | Medium | Low (adjudication) | Very high | Source adjudication + completeness |
| 7 | F: Python dependency declarations | 4 | 34 | $3.95 | Medium | Very high | Very high | Future Python extractor or residual |
| 8 | H: Notebook image inventories | 2 | 36 | $3.11 | Low | N/A | Very high | Agent residual |

### Next Three Bounded Tranches

1. **Completeness-only audit** (guardrails-regex-detector, model-registry, ogx)
   - Scope: Prove category emptiness or identify missing extractions for 3 components
   - Expected savings: $2.37, 486s agent time avoided
   - Complexity: Low — no new extractors needed
   - No existing task file; create one

2. **Eval-hub runtime boundaries** (eval-hub)
   - Scope: Resolve 8 corrections through Go HTTP server and K8s client analysis
   - Expected savings: $0.92, 203s agent time avoided
   - Complexity: Medium — extends existing Go mux contracts
   - Existing task: [extract-eval-hub-runtime-boundaries.md](../tasks/pending/extract-eval-hub-runtime-boundaries.md)

3. **Kubernetes manifest authentication and dependency extraction** (rhoai-mcp,
   llm-d-routing-sidecar, llm-d-batch-gateway-operator, trustyai-explainability,
   llm-d-planner)
   - Scope: Resolve 27 corrections from production manifests
   - Expected savings: $4.50, 955s agent time avoided
   - Complexity: Medium — manifest extraction patterns are mechanical
   - No existing task file; create one
   - Alternative: decompose into smaller tranches per manifest pattern

The existing [ModelMesh task](../tasks/pending/extract-modelmesh-runtime-relationships.md)
remains valid but ranks 4th due to high implementation complexity and the
weakness of its proto/go.mod-only evidence.

### Source Adjudication Required

Before any extractor work, the following corrections should be formally
adjudicated as invalid historical evidence:

| Component | Corrections | Evidence class | Recommendation |
|-----------|------------:|----------------|----------------|
| caikit-tgis-serving | 6 | `demo/kserve/custom-manifests/` | Adjudicate as invalid demo evidence |
| distributed-workloads | 3 | `benchmarks/` and `examples/` | Adjudicate as invalid example/benchmark evidence |
| llm-d-kv-cache | 4 | `examples/kv_events/online/main.go` | Adjudicate as invalid example evidence |
| vllm-cpu | 4 | `benchmarks/` | Adjudicate as invalid benchmark evidence |
| codeflare-sdk | 2 of 7 | `tests/e2e/minio_deployment.yaml` | Adjudicate MinIO auth as invalid test evidence |
| llm-d-async | 2 of 4 | `docs/guides/` | Adjudicate probe auth as invalid documentation evidence |
| kube-auth-proxy | 1 of 2 | `examples/openshift/` | Adjudicate OAuth2 config as invalid example evidence |

These 22 corrections are from directories that are explicitly not production
runtime evidence. Adjudicating them does not change analyzer behavior or routing
but reduces the apparent correction count and clarifies the true implementation
scope.

### Justified Agent Residuals

| Component | Corrections | Reason |
|-----------|------------:|--------|
| notebooks | 19 | Image-level bundled-library inventory is not runtime service integration; no shipped application entrypoint |
| notebooks-downstream | 17 | Same as notebooks; downstream image with pinned library versions |

These two components account for 36/168 (21.4%) of all unresolved mutations.
Their evidence model (library availability in a user environment) is
fundamentally different from runtime integration and cannot be captured by
source-level deterministic extraction.

---

## Reconciliation

### Mutation Accounting

| Disposition | Components | Mutations |
|-------------|:----------:|----------:|
| Completeness audit (Cluster A) | 3 | 0 |
| Extractor tranche — Go HTTP (Cluster B) | 5 | 25 |
| Extractor tranche — K8s manifest (Cluster C) | 5 | 27 |
| Extractor tranche — Go gRPC (Cluster D) | 1 | 10 |
| Extractor tranche + adjudication — Python source (Cluster E) | 4 | 15 |
| Source adjudication + completeness (Cluster G) | 5 | 21 |
| Future Python extractor or residual (Cluster F) | 4 | 34 |
| Justified agent residual (Cluster H) | 2 | 36 |
| **Total** | **29** | **168** |

All 29 false candidates are accounted for exactly once. All 168 unresolved
mutations are reconciled.

### Correction Breakdown by Category

| Blocking category | Components blocked | Mutations in category |
|-------------------|-------------------:|----------------------:|
| Authentication | 22 | ~52 |
| Integration Points | 14 | ~62 |
| Internal Dependencies | 23 | ~54 |
| Architecture Components | 3 | ~8 |

Note: some corrections contribute to multiple conceptual categories but each
mutation is counted once in its reported category.

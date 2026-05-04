# RHOAI Component Architecture Extraction Report

Structured data extraction across 17 categories (A-Q) for all 17 RHOAI components.

---

## A) Component Inventory

| Component | Language | Version | Type | Build System |
|-----------|----------|---------|------|-------------|
| ai4rag | Python | v0.5.5 | Library | No Konflux Dockerfile |
| ai-gateway-payload-processing | Go 1.25 | - | ExtProc plugin host | Konflux + Hermeto |
| argo-workflows | Go | - | Controller + Executor | Konflux + rpms.lock.yaml |
| batch-gateway | Go 1.25 | - | Multi-service (apiserver+processor+gc) | Konflux + Helm |
| caikit | Python | - | SDK/Runtime framework | No Dockerfiles in repo |
| caikit-nlp | Python | - | Library (NLP modules) | No standalone Dockerfile |
| caikit-tgis-serving | Python | - | Container image (ServingRuntime) | Konflux (hermetic: false) |
| codeflare-operator | Go 1.23 | - | Operator (controller-runtime) | Konflux + rpms.lock.yaml |
| codeflare-sdk | Python | - | Client SDK | No Konflux build |
| data-science-pipelines | Go | - | Multi-component (7 sub-components) | Konflux + rpms.lock.yaml |
| data-science-pipelines-operator | Go 1.25 | - | Operator (controller-runtime) | Konflux |
| eval-hub | Go | v0.4.0 | REST API + sidecars | Konflux |
| feast | Go + Python + React | v0.63.0 | Operator + Feature server + UI | Konflux |
| fms-guardrails-orchestrator | Rust (axum+tokio) | v0.18.3 | Service | Konflux + Cargo.lock |
| fms-hf-tuning | Python | - | Container image (fine-tuning) | Konflux (UBI9+CUDA 12.1) |
| gateway-api-inference-extension | Go | - | ExtProc service | No Konflux Dockerfiles on branch |
| guardrails-detectors | Python | - | Microservices (3 detectors) | Konflux (partial - LLM Judge missing) |

---

## B) Custom Resource Definitions (CRDs)

| Component | CRDs | API Group |
|-----------|------|-----------|
| ai4rag | None | - |
| ai-gateway-payload-processing | ExternalModel, ExternalProvider | inference.opendatahub.io/v1alpha1 |
| argo-workflows | Workflow, CronWorkflow, WorkflowTemplate, ClusterWorkflowTemplate, WorkflowTaskSet, WorkflowTaskResult, WorkflowArtifactGCTask, WorkflowEventBinding | argoproj.io (8 CRDs) |
| batch-gateway | None | - |
| caikit | None | - |
| caikit-nlp | None | - |
| caikit-tgis-serving | None (uses KServe ServingRuntime) | - |
| codeflare-operator | AppWrapper | workload.codeflare.dev/v1beta2 |
| codeflare-sdk | None (consumes RayCluster, AppWrapper, LocalQueue) | - |
| data-science-pipelines | Pipeline, PipelineVersion, ScheduledWorkflow, Viewer | pipelines.kubeflow.org/v2beta1 |
| data-science-pipelines-operator | DataSciencePipelinesApplication | datasciencepipelinesapplications.opendatahub.io |
| eval-hub | None | - |
| feast | FeatureStore | feast.dev/v1, feast.dev/v1alpha1 |
| fms-guardrails-orchestrator | None | - |
| fms-hf-tuning | None | - |
| gateway-api-inference-extension | InferencePool (v1), InferenceObjective, InferenceModelRewrite (v1alpha2) | inference.networking.x-k8s.io |
| guardrails-detectors | None (deployed via KServe InferenceServices) | - |

---

## C) Internal Platform Dependencies

| Component | Depends On |
|-----------|-----------|
| ai4rag | Llama Stack, OpenAI API, ChromaDB |
| ai-gateway-payload-processing | Envoy proxy (ext-proc host), NeMo Guardrails, model provider backends |
| argo-workflows | Kubernetes API (client-go informers), artifact storage (S3/GCS/Azure/Git/HDFS/HTTP/OSS/Raw) |
| batch-gateway | PostgreSQL, Redis/Valkey, inference gateways, S3-compatible storage |
| caikit | Model Mesh (optional), runtime modules |
| caikit-nlp | caikit runtime, TGIS server, HuggingFace Hub |
| caikit-tgis-serving | KServe, TGIS (localhost:8033), Istio |
| codeflare-operator | KubeRay (RayCluster), Kueue (LocalQueue/ClusterQueue), OAuth proxy |
| codeflare-sdk | Kubernetes API, RayCluster, AppWrapper, LocalQueue, OpenShift OAuth |
| data-science-pipelines | Argo Workflows, MariaDB/MySQL, S3 (Minio), Kubernetes API |
| data-science-pipelines-operator | data-science-pipelines components, OpenShift service-ca, kube-rbac-proxy |
| eval-hub | PostgreSQL/SQLite, Kubernetes API (TokenReview, SAR) |
| feast | Online store backends (20+), offline store backends (9+), Kubernetes API, Kubeflow Notebooks |
| fms-guardrails-orchestrator | TGIS, Caikit NLP, chunker services, detector services, OpenAI backends |
| fms-hf-tuning | CUDA 12.1, HuggingFace transformers, FSDP, experiment trackers (Aim/MLflow/ClearML) |
| gateway-api-inference-extension | Envoy proxy, KServe InferencePool, model server metrics endpoints |
| guardrails-detectors | KServe, vLLM (LLM Judge), HuggingFace models |

---

## D) Network Services (Ports)

| Component | Port | Protocol | Purpose |
|-----------|------|----------|---------|
| ai4rag | None | - | Library only |
| ai-gateway-payload-processing | 9004/TCP | gRPC | ExtProc service |
| ai-gateway-payload-processing | 9005/TCP | HTTP | Health check |
| argo-workflows | 9090/TCP | HTTP | Prometheus metrics |
| argo-workflows | 6060/TCP | HTTP | Health check (healthz) |
| batch-gateway | Configurable | HTTP | OpenAI Batch API REST |
| caikit | 8080/TCP | HTTP | REST inference |
| caikit | 8085/TCP | gRPC | gRPC inference |
| caikit | 8086/TCP | HTTP | Prometheus metrics |
| caikit-nlp | (via caikit runtime) | HTTP/gRPC | Auto-generated endpoints |
| caikit-tgis-serving | 8080/TCP | HTTP | REST inference |
| caikit-tgis-serving | 8085/TCP | gRPC | gRPC inference |
| caikit-tgis-serving | 8086/TCP | HTTP | Metrics |
| caikit-tgis-serving | 8033/TCP | gRPC | TGIS backend (localhost) |
| codeflare-operator | 9443/TCP | HTTPS | Webhooks (mutating/validating) |
| codeflare-operator | 8080/TCP | HTTP | Metrics |
| codeflare-sdk | None | - | Client SDK |
| data-science-pipelines | 8888/TCP | HTTP | API server REST |
| data-science-pipelines | 8887/TCP | gRPC | API server gRPC (9 services) |
| data-science-pipelines | 8443/TCP | HTTPS | Webhook (cache) |
| data-science-pipelines-operator | 8080/TCP | HTTP | Operator metrics |
| eval-hub | 8080/TCP | HTTP | REST API |
| eval-hub | 8443/TCP | HTTPS | MCP server |
| feast | 6566/TCP | HTTP | Feature server REST |
| feast | Configurable | gRPC | Feature server gRPC |
| feast | 8000/TCP | HTTP | Metrics |
| fms-guardrails-orchestrator | 8033/TCP | HTTP | Guardrails server |
| fms-guardrails-orchestrator | 8034/TCP | HTTP | Health server |
| fms-hf-tuning | 29500/TCP | TCP | FSDP distributed training (plaintext) |
| gateway-api-inference-extension | 9002/TCP | gRPC | EPP ExtProc |
| gateway-api-inference-extension | 9003/TCP | HTTP | EPP health |
| gateway-api-inference-extension | 9004/TCP | gRPC | BBR ExtProc |
| gateway-api-inference-extension | 9005/TCP | HTTP | BBR health |
| gateway-api-inference-extension | 9090/TCP | HTTP | Metrics |
| guardrails-detectors | 8080/TCP | HTTP | Detector REST API |
| guardrails-detectors | 8085/TCP | HTTP | Metrics |

---

## E) HTTP Endpoints

| Component | Endpoint Pattern | Description |
|-----------|-----------------|-------------|
| ai4rag | None | Library only |
| ai-gateway-payload-processing | None (ext-proc gRPC only) | Health on 9005 |
| argo-workflows | /healthz (6060) | Health check only; no argo-server shipped |
| batch-gateway | /v1/batches (POST/GET), /v1/batches/{id} (GET), /v1/batches/{id}/cancel (POST) | OpenAI Batch API compatible |
| caikit | /api/v1/* (dynamic, task-based) | Auto-generated from registered modules |
| caikit-nlp | (via caikit runtime) | Auto-generated NLP task endpoints |
| caikit-tgis-serving | /api/v1/* (via caikit) | Same as caikit runtime endpoints |
| codeflare-operator | /healthz, /readyz, /metrics | Operator health and metrics |
| codeflare-sdk | None | Client SDK |
| data-science-pipelines | /apis/v2beta1/pipelines, /apis/v2beta1/runs, /apis/v2beta1/experiments, /apis/v2beta1/recurringruns | Kubeflow Pipelines REST API |
| data-science-pipelines-operator | /metrics | Operator metrics |
| eval-hub | /api/v1/evaluations (CRUD), /api/v1/recipes, /api/v1/config, /healthz, /readyz | Evaluation job management |
| feast | /get-online-features, /push, /materialize, /health | Feature serving REST API |
| fms-guardrails-orchestrator | /api/v1/text/task/*, /health | Guardrails orchestration |
| fms-hf-tuning | None | Training container, no HTTP API |
| gateway-api-inference-extension | /healthz (9003, 9005) | Health only; traffic via ext-proc gRPC |
| guardrails-detectors | /api/v1/text/contents (POST), /health | Detector REST API |

---

## F) gRPC Services

| Component | Service(s) | Port | Details |
|-----------|-----------|------|---------|
| ai4rag | None | - | - |
| ai-gateway-payload-processing | envoy.service.ext_proc.v3.ExternalProcessor | 9004 | BBR ExtProc |
| argo-workflows | None exposed (internal workflow coordination) | - | Uses Kubernetes API directly |
| batch-gateway | None | - | REST only |
| caikit | Dynamic task-based services (e.g., NlpService, TextGenerationService) | 8085 | Auto-generated from registered modules |
| caikit | mmesh.ModelRuntime | 8085 | Model Mesh integration |
| caikit-nlp | (via caikit runtime) | 8085 | Inherits caikit gRPC services |
| caikit-tgis-serving | caikit gRPC services | 8085 | Inherits caikit runtime |
| caikit-tgis-serving | TGIS generation service | 8033 | Backend (localhost only) |
| codeflare-operator | None | - | Webhooks via HTTPS, not gRPC |
| codeflare-sdk | None | - | Client SDK |
| data-science-pipelines | PipelineService, RunService, ExperimentService, RecurringRunService, PipelineVersionService, ArtifactService, ExecutionService, EventService, ContextService | 8887 | 9 gRPC services |
| data-science-pipelines-operator | None | - | Operator manages templates |
| eval-hub | None | - | REST + MCP only |
| feast | FeastServing (configurable) | Configurable | Optional gRPC feature serving |
| fms-guardrails-orchestrator | Client to: TGIS, Caikit NLP, chunker services | - | gRPC client (not server) |
| fms-hf-tuning | None | - | FSDP uses TCP 29500 (not gRPC) |
| gateway-api-inference-extension | envoy.service.ext_proc.v3.ExternalProcessor (EPP + BBR) | 9002, 9004 | Two ext-proc instances |
| guardrails-detectors | None | - | REST only |

---

## G) RBAC

| Component | RBAC Scope | Key Resources |
|-----------|-----------|---------------|
| ai4rag | None | Library, no K8s interaction |
| ai-gateway-payload-processing | ClusterRole | ExternalModel, ExternalProvider, Secrets |
| argo-workflows | ClusterRole + Role | Workflows, CronWorkflows, WorkflowTemplates, Pods, PVCs, ConfigMaps |
| batch-gateway | ServiceAccount | Minimal; relies on external auth headers |
| caikit | None | Runtime framework, no direct K8s API |
| caikit-nlp | None | Library only |
| caikit-tgis-serving | ServiceAccount (KServe-managed) | Managed by KServe ServingRuntime |
| codeflare-operator | ClusterRole (manager-role) | AppWrappers, RayClusters, Pods, ConfigMaps, Secrets, NetworkPolicies, OAuth proxy resources, LocalQueues, ClusterQueues, ResourceFlavors, Workloads |
| codeflare-sdk | User's kubeconfig RBAC | RayClusters, AppWrappers, LocalQueues (client-side) |
| data-science-pipelines | ClusterRole + Role | Workflows, Pods, ConfigMaps, Secrets, Events, PVCs, custom pipeline CRDs |
| data-science-pipelines-operator | ClusterRole (extensive) | DSPAs, Deployments, Services, Routes, ConfigMaps, Secrets, RoleBindings, NetworkPolicies, ServiceMonitors, many more |
| eval-hub | ClusterRole | TokenReview, SubjectAccessReview (Kubernetes-native auth) |
| feast | ClusterRole + Role | FeatureStores, Deployments, Services, ConfigMaps, ServiceAccounts, ServiceMonitors, plus auto-access RBAC bridging |
| fms-guardrails-orchestrator | ServiceAccount | Minimal; service-level only |
| fms-hf-tuning | None (pod-level SA) | Training pod uses default SA |
| gateway-api-inference-extension | ClusterRole | InferencePool, InferenceModel, Pods, EndpointSlices, Leases |
| guardrails-detectors | ServiceAccount (KServe-managed) | Managed by KServe InferenceService |

---

## H) Secrets

| Component | Secret Types | Details |
|-----------|-------------|---------|
| ai4rag | None | - |
| ai-gateway-payload-processing | API key secrets | Referenced by ExternalProvider CR for model provider auth |
| argo-workflows | Artifact storage credentials | S3/GCS/Azure credentials for artifact storage backends |
| batch-gateway | DB credentials, Redis password, S3 credentials | PostgreSQL, Redis/Valkey, object storage authentication |
| caikit | TLS certs (optional) | Configurable TLS/mTLS certificates |
| caikit-nlp | None directly | Inherits caikit runtime secrets |
| caikit-tgis-serving | TLS certs (Istio-managed) | Istio sidecar handles mTLS |
| codeflare-operator | OAuth cookie secret, TLS CA certs | Per-RayCluster CA cert (RSA 2048, 1-year); SHA1-based cookie secret |
| codeflare-sdk | kubeconfig, TLS certs | User credentials, optional TLS certs for RayCluster |
| data-science-pipelines | DB credentials, S3 credentials, TLS certs | MariaDB password, Minio credentials, service-ca TLS |
| data-science-pipelines-operator | Managed secrets (templated) | Creates secrets for managed components via Manifestival templates |
| eval-hub | DB credentials, TLS certs | PostgreSQL connection, server TLS |
| feast | Online/offline store credentials | Database credentials for 20+ online store backends |
| fms-guardrails-orchestrator | TLS certs | Configurable TLS for server and client connections |
| fms-hf-tuning | HuggingFace tokens, tracker credentials | HF_TOKEN for model downloads, experiment tracker auth |
| gateway-api-inference-extension | Self-signed TLS certs | Auto-generated 4096-bit RSA, 10-year validity |
| guardrails-detectors | None directly | KServe manages secrets |

---

## I) Auth Mechanisms

| Component | Auth Type | Details |
|-----------|----------|---------|
| ai4rag | None | Library; no auth surface |
| ai-gateway-payload-processing | API key injection | Plugin injects API keys from Secrets into upstream requests |
| argo-workflows | Kubernetes ServiceAccount | client-go impersonation; no argo-server UI/API auth |
| batch-gateway | HTTP header-based tenant isolation | X-MaaS-Username header; no built-in auth |
| caikit | None built-in | Delegates to deployment environment (Istio, KServe) |
| caikit-nlp | None | Library; inherits caikit runtime auth |
| caikit-tgis-serving | Istio mTLS | PERMISSIVE mode on metrics port 8086 |
| codeflare-operator | OAuth proxy sidecar injection | OpenShift OAuth proxy for RayCluster dashboards |
| codeflare-sdk | kubeconfig / OpenShift OAuth | Uses user's K8s credentials; token refresh via OAuth |
| data-science-pipelines | Kubernetes SA tokens | API server validates K8s tokens |
| data-science-pipelines-operator | kube-rbac-proxy sidecar | Authenticates Route access via kube-rbac-proxy |
| eval-hub | Kubernetes-native (TokenReview + SubjectAccessReview) | Full K8s auth delegation; validates SA tokens |
| feast | OIDC + Kubernetes RBAC | Auto-access RBAC bridging Feast permissions to K8s RBAC |
| fms-guardrails-orchestrator | None built-in | Service-level only; no auth layer |
| fms-hf-tuning | None | Training container; no API auth |
| gateway-api-inference-extension | None built-in | Envoy handles upstream auth |
| guardrails-detectors | None built-in | KServe handles auth |

---

## J) TLS Configuration

| Component | TLS Support | Details |
|-----------|------------|---------|
| ai4rag | None | Library only |
| ai-gateway-payload-processing | Partial | NeMo guardrail calls use plaintext HTTP (security concern) |
| argo-workflows | None documented | No TLS configuration in controller/executor |
| batch-gateway | cert-manager integration | Helm chart supports cert-manager for TLS; Gateway API HTTPRoute |
| caikit | Configurable TLS/mTLS | Server and client TLS via config; separate health probe binary needed for TLS |
| caikit-nlp | Inherits caikit | Uses caikit runtime TLS settings |
| caikit-tgis-serving | Istio mTLS | Istio sidecar injection; PERMISSIVE on metrics 8086 |
| codeflare-operator | Per-RayCluster CA | Generates RSA 2048-bit CA certs (1-year validity); manages per-cluster mTLS |
| codeflare-sdk | Configurable (verify_tls) | verify_tls=False is a security risk; cryptography==40.0.2 for cert generation |
| data-science-pipelines | OpenShift service-ca | Pod-to-pod TLS via service-ca annotation |
| data-science-pipelines-operator | OpenShift service-ca | Injects service-ca TLS for managed components |
| eval-hub | Server TLS | TLS on MCP server (8443) |
| feast | Configurable | ServiceMonitor has insecureSkipVerify: true (security concern) |
| fms-guardrails-orchestrator | Configurable but flawed | NoVerifier bypasses cert verification when insecure=true (security concern) |
| fms-hf-tuning | None | FSDP port 29500 is plaintext (security concern) |
| gateway-api-inference-extension | Self-signed certs | 4096-bit RSA, 10-year validity; InsecureSkipVerify=true default for metrics scraping |
| guardrails-detectors | KServe-managed | Inherits KServe TLS |

---

## K) Container Security / FIPS Compliance

| Component | FIPS Status | Details |
|-----------|------------|---------|
| ai4rag | Delegated | FIPS delegated to runtime environment; hashlib SHA256 for dedup only (non-security) |
| ai-gateway-payload-processing | Compliant | GOEXPERIMENT=strictfipsruntime, CGO_ENABLED=1 |
| argo-workflows | Risk | argoexec builds both FIPS and non-FIPS binaries; defaults to non-FIPS |
| batch-gateway | Gap | CGO_ENABLED=0 in Konflux Dockerfiles (breaks Go FIPS) |
| caikit | Delegated | Python; delegates to UBI9 OpenSSL |
| caikit-nlp | Delegated | Python library; inherits runtime FIPS |
| caikit-tgis-serving | Delegated | UBI9 OpenSSL; non-hermetic builds (hermetic: false) |
| codeflare-operator | Mostly compliant | GOEXPERIMENT=strictfipsruntime; minor concern: SHA1 for cookie secret |
| codeflare-sdk | Delegated | Python; uses cryptography==40.0.2 (FIPS-capable) |
| data-science-pipelines | Risk | Launcher ships both FIPS and non-FIPS binaries |
| data-science-pipelines-operator | Compliant | Go with FIPS build tags |
| eval-hub | Compliant | GOEXPERIMENT=strictfipsruntime; detects FIPS via /proc/sys/crypto/fips_enabled |
| feast | Mixed | Operator: strictfipsruntime; feature server: UBI9 OpenSSL |
| fms-guardrails-orchestrator | CRITICAL GAP | Uses rustls with ring backend -- NOT FIPS-validated; Rust has no certified FIPS crypto |
| fms-hf-tuning | Delegated | UBI9 + CUDA base; Python delegates to OpenSSL |
| gateway-api-inference-extension | Unknown | No Konflux Dockerfiles on branch to verify FIPS flags |
| guardrails-detectors | Delegated | Python on UBI9; LLM Judge has no Konflux Dockerfile yet |

---

## L) Monitoring

| Component | Metrics | Tracing | Alerting |
|-----------|---------|---------|----------|
| ai4rag | None | None | None |
| ai-gateway-payload-processing | Prometheus (via Envoy) | None documented | None |
| argo-workflows | Prometheus on 9090/TCP | None documented | None |
| batch-gateway | Prometheus via ServiceMonitor | OpenTelemetry distributed tracing | PrometheusRule in Helm chart |
| caikit | Prometheus on 8086/TCP | None documented | None |
| caikit-nlp | Via caikit runtime (8086) | None | None |
| caikit-tgis-serving | Prometheus on 8086/TCP | None documented | None |
| codeflare-operator | Prometheus on 8080/TCP | None documented | None |
| codeflare-sdk | None | None | None |
| data-science-pipelines | Prometheus (API server) | None documented | None |
| data-science-pipelines-operator | Prometheus on 8080/TCP, ServiceMonitors | None documented | None |
| eval-hub | Prometheus | OpenTelemetry | None |
| feast | Prometheus on 8000/TCP, ServiceMonitor | None documented | None; insecureSkipVerify: true in ServiceMonitor |
| fms-guardrails-orchestrator | Prometheus | OpenTelemetry distributed tracing | None |
| fms-hf-tuning | Experiment trackers (Aim, MLflow, ClearML) | None | None |
| gateway-api-inference-extension | Prometheus on 9090/TCP | OpenTelemetry | None |
| guardrails-detectors | Prometheus on 8085/TCP (common library instrumentation) | None documented | None |

---

## M) Sub-Components

| Component | Sub-Components |
|-----------|---------------|
| ai4rag | None (single library) |
| ai-gateway-payload-processing | Plugin host + plugins: model-provider-resolver, api-translation, apikey-injection, nemo-request-guard, nemo-response-guard |
| argo-workflows | workflow-controller, argoexec (executor) |
| batch-gateway | apiserver, processor, gc (garbage collector) |
| caikit | caikit-core (runtime framework), caikit-runtime (server), caikit-health-probe (external health binary) |
| caikit-nlp | Single library with local HuggingFace backend + remote TGIS backend |
| caikit-tgis-serving | caikit runtime + TGIS backend (co-located in single pod) |
| codeflare-operator | Operator controller + embedded AppWrapper controller |
| codeflare-sdk | Single Python SDK |
| data-science-pipelines | API server, driver, launcher, persistence agent, scheduled workflow controller, cache server, viewer controller (7 sub-components) |
| data-science-pipelines-operator | Operator + Manifestival template engine (config/internal/ templates) |
| eval-hub | eval-hub (main API), eval-runtime-sidecar, eval-runtime-init, evalhub-mcp (MCP server) |
| feast | feast-operator (Go), feature-server (Python), feast-ui (React) |
| fms-guardrails-orchestrator | Single Rust service with dual-protocol client strategy |
| fms-hf-tuning | Single training container + trainer controller framework |
| gateway-api-inference-extension | EPP (Endpoint Picker), BBR (Body-Based Routing), plugin framework (filter/score/pick) |
| guardrails-detectors | Built-in detector, HuggingFace detector, LLM Judge detector + common library |

---

## N) Deployment Manifests

| Component | Deployment Method | Manifest Location |
|-----------|------------------|-------------------|
| ai4rag | None (pip install) | No K8s manifests |
| ai-gateway-payload-processing | Helm chart | Helm chart in repo |
| argo-workflows | Kustomize (ODH/RHOAI overlays) | config/ with base + overlays |
| batch-gateway | Helm chart | Helm chart with cert-manager, Gateway API HTTPRoute, ServiceMonitor, PrometheusRule |
| caikit | None (library) | No K8s manifests |
| caikit-nlp | None (library) | No K8s manifests |
| caikit-tgis-serving | KServe ServingRuntime YAML | ServingRuntime CR definition |
| codeflare-operator | Kustomize (ODH/RHOAI overlays) | config/ with base + overlays |
| codeflare-sdk | None (pip install) | No K8s manifests |
| data-science-pipelines | Kustomize | config/ manifests |
| data-science-pipelines-operator | Kustomize (ODH/RHOAI overlays) + Manifestival templates | config/ + config/internal/ Go templates |
| eval-hub | Kustomize | config/ manifests |
| feast | Kustomize (ODH/RHOAI overlays) | config/ with base + overlays |
| fms-guardrails-orchestrator | Kustomize | config/ manifests |
| fms-hf-tuning | Dockerfile only | No K8s deployment manifests (used via KFP/training operator) |
| gateway-api-inference-extension | Helm chart + Kustomize | Helm chart + config/ manifests |
| guardrails-detectors | KServe InferenceService | Deployed as KServe InferenceServices |

---

## O) HA Configuration

| Component | HA Support | Details |
|-----------|-----------|---------|
| ai4rag | N/A | Library |
| ai-gateway-payload-processing | Envoy-managed | Multiple ext-proc replicas behind Envoy load balancing |
| argo-workflows | Leader election | workflow-controller supports leader election for HA |
| batch-gateway | Multi-replica + semaphore | Two-level semaphore concurrency model (global + per-model); multiple replicas per service |
| caikit | KServe-managed | HPA via KServe InferenceService |
| caikit-nlp | N/A | Library |
| caikit-tgis-serving | KServe-managed | KServe handles replica scaling |
| codeflare-operator | Leader election | controller-runtime leader election |
| codeflare-sdk | N/A | Client SDK |
| data-science-pipelines | API server replicas | API server supports multiple replicas; driver/launcher are per-pipeline |
| data-science-pipelines-operator | Leader election | controller-runtime leader election |
| eval-hub | Single replica (documented) | No HA documented; SQLite in dev mode is single-instance |
| feast | Operator: leader election; feature server: HPA | Operator uses controller-runtime leader election |
| fms-guardrails-orchestrator | Multiple replicas | Stateless service supports horizontal scaling |
| fms-hf-tuning | FSDP distributed | Multi-node training via FSDP; not traditional HA |
| gateway-api-inference-extension | Multiple EPP replicas | Envoy load balances across ext-proc replicas; leader election for informer cache |
| guardrails-detectors | KServe-managed | KServe handles scaling |

---

## P) Ingress / Egress

| Component | Ingress | Egress |
|-----------|---------|--------|
| ai4rag | None | Llama Stack API, OpenAI API, ChromaDB |
| ai-gateway-payload-processing | gRPC from Envoy (9004) | Model providers, NeMo Guardrails (plaintext HTTP) |
| argo-workflows | Kubernetes API (informers) | Artifact storage (S3, GCS, Azure, Git, HDFS, HTTP, OSS, Raw) |
| batch-gateway | HTTP REST (OpenAI Batch API) | PostgreSQL, Redis/Valkey, inference gateways, S3 |
| caikit | HTTP (8080), gRPC (8085) | Model storage, dependent services |
| caikit-nlp | Via caikit runtime | TGIS server (gRPC), HuggingFace Hub |
| caikit-tgis-serving | HTTP (8080), gRPC (8085) via KServe | TGIS on localhost:8033 only |
| codeflare-operator | Webhooks (9443), metrics (8080) | Kubernetes API, RayCluster pods |
| codeflare-sdk | None | Kubernetes API, RayCluster endpoints |
| data-science-pipelines | HTTP (8888), gRPC (8887), webhook (8443) | MariaDB/MySQL, S3/Minio, Argo Workflows API |
| data-science-pipelines-operator | Metrics (8080) | Kubernetes API, managed component pods |
| eval-hub | HTTP (8080), HTTPS/MCP (8443) | PostgreSQL, Kubernetes API (TokenReview/SAR) |
| feast | HTTP (6566), gRPC (configurable) | Online store backends (20+), offline store backends (9+) |
| fms-guardrails-orchestrator | HTTP (8033) | TGIS (gRPC), Caikit NLP (gRPC), chunkers (gRPC), detectors (HTTP), OpenAI backends (HTTP) |
| fms-hf-tuning | None | HuggingFace Hub, experiment trackers, FSDP peers (29500) |
| gateway-api-inference-extension | gRPC from Envoy (9002, 9004) | Model server metrics endpoints (InsecureSkipVerify=true) |
| guardrails-detectors | HTTP (8080) | vLLM (LLM Judge), HuggingFace model downloads |

---

## Q) Architectural Analysis -- Key Findings

### Cross-Cutting Security Concerns

| Issue | Affected Components | Severity |
|-------|-------------------|----------|
| FIPS compliance gap (CGO_ENABLED=0) | batch-gateway | High |
| FIPS compliance gap (rustls/ring) | fms-guardrails-orchestrator | Critical |
| FIPS dual-binary risk (defaults to non-FIPS) | argo-workflows, data-science-pipelines (launcher) | High |
| InsecureSkipVerify=true defaults | gateway-api-inference-extension, feast (ServiceMonitor) | Medium |
| NoVerifier TLS bypass | fms-guardrails-orchestrator | High |
| verify_tls=False option | codeflare-sdk | Medium |
| Plaintext HTTP to NeMo Guardrails | ai-gateway-payload-processing | Medium |
| Plaintext FSDP training port | fms-hf-tuning (29500/TCP) | Medium |
| SHA1 cookie secret | codeflare-operator | Low |
| Non-hermetic Konflux builds | caikit-tgis-serving | Medium |
| Missing Konflux Dockerfiles | guardrails-detectors (LLM Judge), gateway-api-inference-extension | Medium |

### Architectural Patterns

| Pattern | Components Using It |
|---------|-------------------|
| Envoy ext-proc (External Processing) | ai-gateway-payload-processing, gateway-api-inference-extension |
| KServe ServingRuntime/InferenceService | caikit-tgis-serving, guardrails-detectors |
| Kubernetes Operator (controller-runtime) | codeflare-operator, data-science-pipelines-operator, feast |
| Helm chart deployment | ai-gateway-payload-processing, batch-gateway, gateway-api-inference-extension |
| Kustomize with ODH/RHOAI overlays | argo-workflows, codeflare-operator, data-science-pipelines-operator, feast |
| kube-rbac-proxy sidecar | data-science-pipelines-operator, feast |
| OAuth proxy sidecar | codeflare-operator (injected into RayClusters) |
| OpenShift service-ca TLS | data-science-pipelines-operator |
| Istio mTLS | caikit-tgis-serving |
| OpenTelemetry tracing | batch-gateway, eval-hub, fms-guardrails-orchestrator, gateway-api-inference-extension |
| NetworkPolicy enforcement | codeflare-operator, data-science-pipelines-operator |
| Manifestival templating | data-science-pipelines-operator |
| KEP-753 native sidecar containers | eval-hub |
| MCP (Model Context Protocol) server | eval-hub |
| Plugin framework | ai-gateway-payload-processing (BBR plugins), gateway-api-inference-extension (filter/score/pick) |
| Dual-protocol (HTTP + gRPC) | caikit, caikit-tgis-serving, data-science-pipelines, feast |
| Python library (no K8s resources) | ai4rag, caikit, caikit-nlp, codeflare-sdk |

### Build Hermeticity

| Lock File Type | Components |
|---------------|-----------|
| rpms.lock.yaml | argo-workflows, codeflare-operator, data-science-pipelines |
| go.sum | All Go components |
| poetry.lock | caikit-tgis-serving, codeflare-sdk |
| Cargo.lock | fms-guardrails-orchestrator |
| No lock files | fms-hf-tuning (main branch), ai4rag |
| hermetic: false | caikit-tgis-serving |


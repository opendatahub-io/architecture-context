# Analyzer Synthesis Context: llm-d-kv-cache

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (observed)**: 7 grpc_services facts extracted [source: api/indexerpb/indexer.proto:26, api/tokenizerpb/tokenizer.proto:190, api/tokenizerpb/tokenizer.proto:193, api/tokenizerpb/tokenizer.proto:196, api/tokenizerpb/tokenizer.proto:200, api/tokenizerpb/tokenizer.proto:204, examples/kv_cache_index_service/server/main.go:101]
- **http_endpoints (observed)**: 3 http_endpoints facts extracted [source: examples/kv_events/online/main.go:244, examples/kv_events/online/main.go:248, examples/kv_events/online/main.go:274]
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **controller**: PodReconciler —watches-reference→ /v1/Pod; /v1/Pod [source: examples/kv_events/pod_reconciler/pod_reconciler.go:180, examples/kv_events/pod_reconciler/pod_reconciler.go:91]

## Gap Evidence Index

### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:58 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/kv_cache_index/main.go`:74 (kv_cache_index)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/kv_cache_index_service/client/main.go`:32 (client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/kv_cache_index_service/server/main.go`:36 (server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/kv_events/offline/main.go`:35 (offline)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/kv_events/online/main.go`:66 (online)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/kv_events/pod_reconciler/main.go`:37 (pod_reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/valkey_example/main.go`:39 (valkey_example)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `kv_connectors/llmd_fs_backend/Dockerfile.dev`:79 (kv_connectors/llmd_fs_backend/Dockerfile.dev:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `kv_connectors/pvc_evictor/Dockerfile`:19 (kv_connectors/pvc_evictor/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `services/uds_tokenizer/Dockerfile`:73 (services/uds_tokenizer/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `services/uds_tokenizer/Dockerfile.konflux`:81 (services/uds_tokenizer/Dockerfile.konflux:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `examples/kv_events/pod_reconciler/main.go`:69 (Kubernetes API, controller-runtime manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/kvcache/kvblock/redis.go`:110 (Redis/Valkey, go-redis client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/telemetry/tracing.go`:178 (OTLP/gRPC trace exporter, OpenTelemetry Collector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### grpc_services

- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `api/indexerpb/indexer.proto`:26 (indexer.v1.IndexerService/GetPodScores)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `api/tokenizerpb/tokenizer.proto`:196 (tokenization.TokenizationService/InitializeTokenizer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `examples/kv_cache_index_service/server/main.go`:101 (IndexerService, examples/kv_cache_index_service/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `examples/kv_events/online/main.go`:244 (/metrics, Unknown, examples/kv_events/online)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where are runtime routes registered on this server?
  **Expected signal:** router construction or route registration
  **Candidate:** `examples/kv_events/online/main.go`:316 (HTTP, metrics)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `pkg/kvcache/kvblock/redis.go`:110 (Exchange client, Redis/Valkey)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `pkg/telemetry/tracing.go`:178 (OpenTelemetry Collector, gRPC client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `examples/kv_events/pod_reconciler/pod_reconciler.go`:91 (/v1/Pod, get operations by PodReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `examples/kv_events/pod_reconciler/pod_reconciler.go`:91 (/v1/Pod, get operations by PodReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `examples/kv_events/pod_reconciler/pod_reconciler.go`:180 (/v1/Pod, PodReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deploy/common/statefulset.yaml`:1 (${PROJECT_NAME}-0, operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### http_endpoints

- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=examples/kv_events/online [source: examples/kv_events/online/main.go:244]
- Unknown /score_chat_completions on port ; transport=HTTP/1.1 encryption= auth= owner=examples/kv_events/online [source: examples/kv_events/online/main.go:274]
- Unknown /score_completions on port ; transport=HTTP/1.1 encryption= auth= owner=examples/kv_events/online [source: examples/kv_events/online/main.go:248]
### integrations

- OpenTelemetry Collector interaction=gRPC client role=runtime-integration protocol=OTLP/gRPC purpose=Runtime trace export [source: pkg/telemetry/tracing.go:178]
- Redis/Valkey interaction=Exchange client role=runtime-integration protocol=TCP purpose=Runtime queue and key-value data store [source: pkg/kvcache/kvblock/redis.go:110]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: StatefulSet workload ${PROJECT_NAME}-0 uses service account operator-controller-manager and 1 container(s) [source: deploy/common/statefulset.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP Unknown /metrics is owned by examples/kv_events/online [source: examples/kv_events/online/main.go:244]
- **observed**: HTTP Unknown /score_chat_completions is owned by examples/kv_events/online [source: examples/kv_events/online/main.go:274]
- **observed**: HTTP Unknown /score_completions is owned by examples/kv_events/online [source: examples/kv_events/online/main.go:248]
### security

- **dependency-signal**: auth-middleware targets pyjwt: JWT/OAuth authentication library dependency [source: services/uds_tokenizer/requirements-test.txt:492]
- **dependency-signal**: tls-config targets cryptography: TLS/cryptography library dependency [source: services/uds_tokenizer/requirements-test.txt:85]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

# Analyzer Synthesis Context: batch-gateway

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 16 http_endpoints facts extracted [source: cmd/batch-gc/main.go:148, cmd/batch-gc/main.go:149, cmd/batch-processor/main.go:193, cmd/batch-processor/main.go:194, cmd/batch-processor/main.go:199, cmd/batch-processor/main.go:200, cmd/batch-processor/main.go:201, cmd/batch-processor/main.go:202, cmd/batch-processor/main.go:203, cmd/batch-processor/main.go:207, internal/apiserver/common/rest.go:74, internal/apiserver/server/server.go:113, internal/apiserver/server/server.go:114, internal/apiserver/server/server.go:115, internal/apiserver/server/server.go:116, internal/apiserver/server/server.go:117]
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `internal/apiserver/server/server.go`:99 (API server routes, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/apiserver/main.go`:34 (apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/batch-gc/main.go`:48 (batch-gc)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/batch-processor/main.go`:44 (batch-processor)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile.apiserver`:30 (docker/Dockerfile.apiserver:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile.apiserver.konflux`:32 (docker/Dockerfile.apiserver.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile.gc`:21 (docker/Dockerfile.gc:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile.gc.konflux`:32 (docker/Dockerfile.gc.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile.processor`:30 (docker/Dockerfile.processor:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile.processor.konflux`:32 (docker/Dockerfile.processor.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `internal/database/postgresql/db_postgresql.go`:116 (PostgreSQL, pgx connection pool)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `internal/files_store/s3/client.go`:119 (AWS SDK S3 client, S3-compatible storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `internal/util/otel/otel.go`:124 (OTLP/gRPC trace exporter, OpenTelemetry Collector)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `internal/util/redis/redis_client.go`:144 (Redis/Valkey, go-redis client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/clients/http/http_client.go`:134 (HTTP client, llm-d inference gateway)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/clients/inference/async_inference_client_resolver.go`:120 (Redis/Valkey, go-redis client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/batch-gc/main.go`:149 (/health, Unknown, cmd/batch-gc)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where are runtime routes registered on this server?
  **Expected signal:** router construction or route registration
  **Candidate:** `cmd/batch-gc/main.go`:181 (HTTP, metrics)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/batch-processor/main.go`:199 (/debug/pprof/, Unknown, cmd/batch-processor)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `internal/apiserver/common/rest.go`:74 (/, Unknown, internal/apiserver/common)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `internal/apiserver/server/server.go`:113 (/debug/pprof/, Unknown, internal/apiserver/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/database/postgresql/db_postgresql.go`:116 (Database client, PostgreSQL)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/files_store/s3/client.go`:119 (File storage client, S3-compatible storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/util/otel/otel.go`:124 (OpenTelemetry Collector, gRPC client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `internal/util/redis/redis_client.go`:144 (Exchange client, Redis/Valkey)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `pkg/clients/http/http_client.go`:134 (HTTP client, llm-d inference gateway)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/clients/http/http_client.go`:134 (HTTP client, llm-d inference gateway)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/clients/inference/async_shared_client.go`:12 (Go library, llm-d-async)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `benchmarks/manifests/vllm/patch-vllm.yaml`:1 (vllm-qwen3-8b-decode, vllm-qwen3-8b-sa)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- API server routes methods=POST, GET, DELETE mechanism=None enforcement=N/A policy=Closed route inventory has no authentication or authorization enforcement; every local middleware wrapper was inspected [source: internal/apiserver/server/server.go:99]
- Observability endpoints (/health, /ready, /metrics) methods=GET, HEAD mechanism=None enforcement=N/A policy=Closed route inventory has no authentication or authorization enforcement; no middleware is applied [source: internal/apiserver/server/server.go:109]
### http_endpoints

- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/apiserver/common [source: internal/apiserver/common/rest.go:74]
- Unknown /debug/pprof/ on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/batch-processor [source: cmd/batch-processor/main.go:199]
- Unknown /debug/pprof/ on port ; transport=HTTP/1.1 encryption= auth= owner=internal/apiserver/server [source: internal/apiserver/server/server.go:113]
- Unknown /debug/pprof/cmdline on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/batch-processor [source: cmd/batch-processor/main.go:200]
- Unknown /debug/pprof/cmdline on port ; transport=HTTP/1.1 encryption= auth= owner=internal/apiserver/server [source: internal/apiserver/server/server.go:114]
- Unknown /debug/pprof/profile on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/batch-processor [source: cmd/batch-processor/main.go:201]
- Unknown /debug/pprof/profile on port ; transport=HTTP/1.1 encryption= auth= owner=internal/apiserver/server [source: internal/apiserver/server/server.go:115]
- Unknown /debug/pprof/symbol on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/batch-processor [source: cmd/batch-processor/main.go:202]
- Unknown /debug/pprof/symbol on port ; transport=HTTP/1.1 encryption= auth= owner=internal/apiserver/server [source: internal/apiserver/server/server.go:116]
- Unknown /debug/pprof/trace on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/batch-processor [source: cmd/batch-processor/main.go:203]
- Unknown /debug/pprof/trace on port ; transport=HTTP/1.1 encryption= auth= owner=internal/apiserver/server [source: internal/apiserver/server/server.go:117]
- Unknown /health on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/batch-gc [source: cmd/batch-gc/main.go:149]
- Unknown /health on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/batch-processor [source: cmd/batch-processor/main.go:194]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/batch-gc [source: cmd/batch-gc/main.go:148]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/batch-processor [source: cmd/batch-processor/main.go:193]
- Unknown /ready on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/batch-processor [source: cmd/batch-processor/main.go:207]
### integrations

- OpenTelemetry Collector interaction=gRPC client role=runtime-integration protocol=OTLP/gRPC purpose=Runtime trace export [source: internal/util/otel/otel.go:124]
- PostgreSQL interaction=Database client role=runtime-integration protocol=TCP purpose=Runtime relational data store [source: internal/database/postgresql/db_postgresql.go:116]
- Redis/Valkey interaction=Exchange client role=runtime-integration protocol=TCP purpose=Runtime queue and key-value data store [source: internal/util/redis/redis_client.go:144]
- S3-compatible storage interaction=File storage client role=runtime-integration protocol=HTTP/HTTPS purpose=Runtime object storage [source: internal/files_store/s3/client.go:119]
- llm-d inference gateway interaction=HTTP client role=runtime-integration protocol=HTTP/HTTPS purpose=Runtime inference requests [source: pkg/clients/http/http_client.go:134]
### internal_dependencies

- llm-d inference gateway interaction=HTTP client role=runtime-integration purpose=Runtime inference requests to configured llm-d gateway endpoints [source: pkg/clients/http/http_client.go:134]
- llm-d-async interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/llm-d/llm-d-async/api [source: pkg/clients/inference/async_shared_client.go:12]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload vllm-qwen3-8b-decode uses service account vllm-qwen3-8b-sa and 1 container(s) [source: benchmarks/manifests/vllm/patch-vllm.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP Unknown / is owned by internal/apiserver/common [source: internal/apiserver/common/rest.go:74]
- **observed**: HTTP Unknown /debug/pprof/ is owned by cmd/batch-processor [source: cmd/batch-processor/main.go:199]
- **observed**: HTTP Unknown /debug/pprof/ is owned by internal/apiserver/server [source: internal/apiserver/server/server.go:113]
- **observed**: HTTP Unknown /debug/pprof/cmdline is owned by cmd/batch-processor [source: cmd/batch-processor/main.go:200]
- **observed**: HTTP Unknown /debug/pprof/cmdline is owned by internal/apiserver/server [source: internal/apiserver/server/server.go:114]
- **observed**: HTTP Unknown /debug/pprof/profile is owned by cmd/batch-processor [source: cmd/batch-processor/main.go:201]
- **observed**: HTTP Unknown /debug/pprof/profile is owned by internal/apiserver/server [source: internal/apiserver/server/server.go:115]
- **observed**: HTTP Unknown /debug/pprof/symbol is owned by cmd/batch-processor [source: cmd/batch-processor/main.go:202]
- **observed**: HTTP Unknown /debug/pprof/symbol is owned by internal/apiserver/server [source: internal/apiserver/server/server.go:116]
- **observed**: HTTP Unknown /debug/pprof/trace is owned by cmd/batch-processor [source: cmd/batch-processor/main.go:203]
- **observed**: HTTP Unknown /debug/pprof/trace is owned by internal/apiserver/server [source: internal/apiserver/server/server.go:117]
- **observed**: HTTP Unknown /health is owned by cmd/batch-gc [source: cmd/batch-gc/main.go:149]
- **observed**: HTTP Unknown /health is owned by cmd/batch-processor [source: cmd/batch-processor/main.go:194]
- **observed**: HTTP Unknown /metrics is owned by cmd/batch-gc [source: cmd/batch-gc/main.go:148]
- **observed**: HTTP Unknown /metrics is owned by cmd/batch-processor [source: cmd/batch-processor/main.go:193]
- **observed**: HTTP Unknown /ready is owned by cmd/batch-processor [source: cmd/batch-processor/main.go:207]
### security

- **observed**: GET, HEAD Observability endpoints (/health, /ready, /metrics) uses None at N/A; policy=Closed route inventory has no authentication or authorization enforcement; no middleware is applied [source: internal/apiserver/server/server.go:109]
- **observed**: POST, GET, DELETE API server routes uses None at N/A; policy=Closed route inventory has no authentication or authorization enforcement; every local middleware wrapper was inspected [source: internal/apiserver/server/server.go:99]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: internal/apiserver/server/server.go, internal/tls/tls.go, internal/util/redis/redis_client.go, internal/util/tls/tls.go, pkg/clients/http/http_client.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

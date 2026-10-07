# Analyzer Synthesis Context: modelexpress

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 3 crds facts extracted [source: config/manifests/crd/modelexpressservers.modelexpress.opendatahub.io.yaml:4, config/manifests/crd/upstream/modelcacheentries.modelexpress.nvidia.com.yaml:4, config/manifests/crd/upstream/modelmetadatas.modelexpress.nvidia.com.yaml:4]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 3 http_endpoints facts extracted [source: modelexpress_server/src/metrics/exposition.rs:51, operator/src/telemetry.rs:86, operator/src/telemetry.rs:87]
- **services (observed)**: 2 services facts extracted [source: config/manifests/manager/service.yaml:4]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/manifests/manager/deployment.yaml`:4 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/manifests/manager/deployment.yaml`:4 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `operator/src/telemetry.rs`:86 (/api/v1/*, /api/v2/*, Header passthrough)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `operator/src/telemetry.rs`:86 (/health, /info, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/manifests/rbac/clusterrole.yaml`:4 (modelexpress-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/manifests/rbac/clusterrolebinding.yaml`:4 (modelexpress-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ci/k8s/server/Dockerfile.server`:31 (ci/k8s/server/Dockerfile.server:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile`:61 (docker/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile.e2e`:54 (docker/Dockerfile.e2e:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile.e2e`:58 (docker/Dockerfile.e2e:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile.e2e`:62 (docker/Dockerfile.e2e:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile.konflux`:71 (docker/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile.konflux.operator`:42 (docker/Dockerfile.konflux.operator:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/rl/vime_dynamo_delta_refit/Dockerfile`:37 (examples/rl/vime_dynamo_delta_refit/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `modelexpress_server/src/metrics/exposition.rs`:51 (/metrics, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `operator/src/telemetry.rs`:86 (/healthz, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `operator/src/telemetry.rs`:87 (/readyz, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/manifests/manager/deployment.yaml`:4 (modelexpress-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/manifests/manager/service.yaml`:4 (modelexpress-operator, modelexpress-operator-metrics)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /api/v1/*, /api/v2/* methods=POST mechanism=Header passthrough enforcement=Application-level filtering policy=Configured headers are forwarded to downstream services [source: operator/src/telemetry.rs:86]
- /health, /info methods=GET mechanism=None enforcement=None policy=Unauthenticated health server [source: operator/src/telemetry.rs:86]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: config/manifests/manager/deployment.yaml:4]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes readiness probe endpoint [source: config/manifests/manager/deployment.yaml:4]
### http_endpoints

- GET /healthz on port ; transport= encryption=None auth=None owner= [source: operator/src/telemetry.rs:86]
- GET /metrics on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: modelexpress_server/src/metrics/exposition.rs:51]
- GET /readyz on port ; transport= encryption=None auth=None owner= [source: operator/src/telemetry.rs:87]
### services

- modelexpress-operator-metrics port=8080 target=http-metrics protocol=TCP encryption= auth= [source: config/manifests/manager/service.yaml:4]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload modelexpress-operator uses service account modelexpress-operator and 1 container(s) [source: config/manifests/manager/deployment.yaml:4]
- **observed**: Service modelexpress-operator-metrics targets modelexpress-operator with 1 port(s) [source: config/manifests/manager/service.yaml:4]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: GET /health, /info uses None at None; policy=Unauthenticated health server [source: operator/src/telemetry.rs:86]
- **observed**: GET :8081/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: config/manifests/manager/deployment.yaml:4]
- **observed**: GET :8081/readyz uses None at N/A; policy=Unauthenticated Kubernetes readiness probe endpoint [source: config/manifests/manager/deployment.yaml:4]
- **observed**: POST /api/v1/*, /api/v2/* uses Header passthrough at Application-level filtering; policy=Configured headers are forwarded to downstream services [source: operator/src/telemetry.rs:86]
- **observed**: RBAC role modelexpress-operator grants 13 rule(s) [source: config/manifests/rbac/clusterrole.yaml:4]
- **dependency-signal**: crypto-library targets rustls: Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification [source: Cargo.toml:57]
- **dependency-signal**: crypto-library targets tokio-rustls: Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification [source: Cargo.toml:66]
- **dependency-signal**: crypto-provider targets openssl: Cargo.lock selects this cryptographic provider; FIPS validation depends on build and runtime configuration [source: Cargo.lock:3130]
- **dependency-signal**: crypto-provider targets ring: Cargo.lock selects ring as a cryptographic provider; ring is not a FIPS-validated provider [source: Cargo.lock:4017]
- **not-extracted**: fips-posture targets FIPS validation: FIPS validation and runtime provider selection are not fully determined by static dependency/build signals [source: Cargo.toml:57]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

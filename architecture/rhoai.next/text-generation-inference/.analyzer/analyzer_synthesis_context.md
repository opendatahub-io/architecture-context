# Analyzer Synthesis Context: text-generation-inference

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (observed)**: 3 http_endpoints facts extracted [source: router/src/server.rs:448, router/src/server.rs:450, router/src/server.rs:452]
- **services (observed)**: 3 services facts extracted [source: deployment/base/service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `deployment/base/patches/pvcs/pvc.yaml`:2 (:3000/health, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `router/src/server.rs`:448 (/api/v1/*, /api/v2/*, Header passthrough)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `router/src/server.rs`:448 (/health, /info, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:334 (Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `router/src/server.rs`:448 (/generate, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `router/src/server.rs`:450 (/health, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `router/src/server.rs`:452 (/metrics, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deployment/base/patches/pvcs/pvc.yaml`:2 (inference-server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deployment/base/service.yaml`:1 (inference-server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /api/v1/*, /api/v2/* methods=POST mechanism=Header passthrough enforcement=Application-level filtering policy=Configured headers are forwarded to downstream services [source: router/src/server.rs:448]
- /health, /info methods=GET mechanism=None enforcement=None policy=Unauthenticated health server [source: router/src/server.rs:448]
- :3000/health methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: deployment/base/patches/pvcs/pvc.yaml:2]
### http_endpoints

- GET /health on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: router/src/server.rs:450]
- GET /metrics on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: router/src/server.rs:452]
- POST /generate on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: router/src/server.rs:448]
### services

- inference-server port=8033 target=grpc protocol=TCP encryption= auth= [source: deployment/base/service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload inference-server uses service account  and 1 container(s) [source: deployment/base/patches/pvcs/pvc.yaml:2]
- **observed**: Service inference-server targets inference-server with 1 port(s) [source: deployment/base/service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: GET /health, /info uses None at None; policy=Unauthenticated health server [source: router/src/server.rs:448]
- **observed**: GET :3000/health uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: deployment/base/patches/pvcs/pvc.yaml:2]
- **observed**: POST /api/v1/*, /api/v2/* uses Header passthrough at Application-level filtering; policy=Configured headers are forwarded to downstream services [source: router/src/server.rs:448]
- **dependency-signal**: crypto-build-signal targets OpenSSL: Build file references OpenSSL; presence does not establish that application TLS uses a FIPS-validated provider [source: Dockerfile]
- **dependency-signal**: crypto-provider targets aws-lc-rs: Cargo.lock selects this cryptographic provider; FIPS validation depends on build and runtime configuration [source: Cargo.lock:154]
- **dependency-signal**: crypto-provider targets openssl: Cargo.lock selects this cryptographic provider; FIPS validation depends on build and runtime configuration [source: Cargo.lock:1627]
- **dependency-signal**: crypto-provider targets ring: Cargo.lock selects ring as a cryptographic provider; ring is not a FIPS-validated provider [source: Cargo.lock:2166]
- **not-extracted**: fips-posture targets FIPS validation: FIPS validation and runtime provider selection are not fully determined by static dependency/build signals [source: Cargo.lock:2166]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

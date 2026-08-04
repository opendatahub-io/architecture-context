# Analyzer Synthesis Context: fms-guardrails-orchestrator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (observed)**: 12 http_endpoints facts extracted [source: src/server/routes.rs:105, src/server/routes.rs:64, src/server/routes.rs:65, src/server/routes.rs:73, src/server/routes.rs:77, src/server/routes.rs:82, src/server/routes.rs:86, src/server/routes.rs:90, src/server/routes.rs:91, src/server/routes.rs:92, src/server/routes.rs:96, src/server/routes.rs:99]
- **services (observed)**: 2 services facts extracted [source: src/args.rs:32, src/args.rs:34]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `src/args.rs`:47 (All endpoints, TLS / mTLS)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `src/server/routes.rs`:73 (/api/v1/*, /api/v2/*, Header passthrough)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.amd64`:88 (Dockerfile.amd64:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:66 (Dockerfile.konflux:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.ppc64le`:90 (Dockerfile.ppc64le:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.s390x`:84 (Dockerfile.s390x:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `config/config.yaml`:26 (Chunker services, Configured downstream grpc client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/server/routes.rs`:73 (/api/v1/task/classification-with-text-generation, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `src/args.rs`:32 (guardrails-server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /api/v1/*, /api/v2/* methods=POST mechanism=Header passthrough enforcement=Application-level filtering policy=Configured headers are forwarded to downstream services [source: src/server/routes.rs:73]
- /api/v1/*, /api/v2/* methods=POST mechanism=X-Forwarded-Access-Token rewrite enforcement=Application-level policy=Forwarded access token can be rewritten to an Authorization Bearer header [source: src/server/routes.rs:463]
- /health, /info methods=GET mechanism=None enforcement=None policy=Unauthenticated health server [source: src/server/routes.rs:73]
- All endpoints methods=ALL mechanism=TLS / mTLS enforcement=Rust TLS acceptor policy=Optional server TLS and client certificate verification [source: src/args.rs:47]
### http_endpoints

- GET /health on port 8034/TCP; transport= encryption=None auth=None owner= [source: src/server/routes.rs:64]
- GET /info on port 8034/TCP; transport= encryption=None auth=None owner= [source: src/server/routes.rs:65]
- POST /api/v1/task/classification-with-text-generation on port 8033/TCP; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: src/server/routes.rs:73]
- POST /api/v1/task/server-streaming-classification-with-text-generation on port 8033/TCP; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: src/server/routes.rs:77]
- POST /api/v2/chat/completions-detection on port 8033/TCP; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: src/server/routes.rs:99]
- POST /api/v2/text/completions-detection on port 8033/TCP; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: src/server/routes.rs:105]
- POST /api/v2/text/detection/chat on port 8033/TCP; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: src/server/routes.rs:91]
- POST /api/v2/text/detection/content on port 8033/TCP; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: src/server/routes.rs:90]
- POST /api/v2/text/detection/context on port 8033/TCP; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: src/server/routes.rs:92]
- POST /api/v2/text/detection/generated on port 8033/TCP; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: src/server/routes.rs:96]
- POST /api/v2/text/detection/stream-content on port 8033/TCP; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: src/server/routes.rs:82]
- POST /api/v2/text/generation-detection on port 8033/TCP; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: src/server/routes.rs:86]
### services

- guardrails-server port=8033 target=8033 protocol=TCP encryption= auth= [source: src/args.rs:32]
- health-server port=8034 target=8034 protocol=TCP encryption= auth= [source: src/args.rs:34]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service guardrails-server targets  with 1 port(s) [source: src/args.rs:32]
- **observed**: Service health-server targets  with 1 port(s) [source: src/args.rs:34]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: ALL All endpoints uses TLS / mTLS at Rust TLS acceptor; policy=Optional server TLS and client certificate verification [source: src/args.rs:47]
- **observed**: GET /health, /info uses None at None; policy=Unauthenticated health server [source: src/server/routes.rs:73]
- **observed**: POST /api/v1/*, /api/v2/* uses Header passthrough at Application-level filtering; policy=Configured headers are forwarded to downstream services [source: src/server/routes.rs:73]
- **observed**: POST /api/v1/*, /api/v2/* uses X-Forwarded-Access-Token rewrite at Application-level; policy=Forwarded access token can be rewritten to an Authorization Bearer header [source: src/server/routes.rs:463]
- **dependency-signal**: crypto-build-signal targets OpenSSL: Build file references OpenSSL; presence does not establish that application TLS uses a FIPS-validated provider [source: Dockerfile.amd64, Dockerfile.konflux, Dockerfile.ppc64le, Dockerfile.s390x]
- **dependency-signal**: crypto-library targets hyper-rustls: Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification [source: Cargo.toml:33]
- **dependency-signal**: crypto-library targets rustls: Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification [source: Cargo.toml:33]
- **dependency-signal**: crypto-library targets tokio-rustls: Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification [source: Cargo.toml:81]
- **dependency-signal**: crypto-provider targets openssl: Cargo.lock selects this cryptographic provider; FIPS validation depends on build and runtime configuration [source: Cargo.lock:1323]
- **dependency-signal**: crypto-provider targets ring: Cargo.lock selects ring as a cryptographic provider; ring is not a FIPS-validated provider [source: Cargo.lock:1853]
- **not-extracted**: fips-posture targets FIPS validation: FIPS validation and runtime provider selection are not fully determined by static dependency/build signals [source: Cargo.toml:33]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

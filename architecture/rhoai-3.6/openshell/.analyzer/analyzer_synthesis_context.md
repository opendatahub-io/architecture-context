# Analyzer Synthesis Context: openshell

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (observed)**: 109 grpc_services facts extracted [source: crates/openshell-sandbox-backend/proto/openshell_sandbox.proto:11, crates/openshell-sandbox-backend/proto/openshell_sandbox.proto:13, proto/compute_driver.proto:27, proto/compute_driver.proto:32, proto/compute_driver.proto:36, proto/compute_driver.proto:40, proto/compute_driver.proto:43, proto/compute_driver.proto:46, proto/compute_driver.proto:49, proto/compute_driver.proto:52, proto/compute_driver.proto:55, proto/compute_driver.proto:58, proto/compute_driver.proto:62, proto/compute_driver.proto:65, proto/credential_driver.proto:20, proto/credential_driver.proto:24, proto/credential_driver.proto:27, proto/credential_driver.proto:30, proto/credential_driver.proto:34, proto/gateway_interceptor.proto:17, proto/gateway_interceptor.proto:21, proto/gateway_interceptor.proto:26, proto/openshell.proto:102, proto/openshell.proto:112, proto/openshell.proto:122, proto/openshell.proto:132, proto/openshell.proto:142, proto/openshell.proto:152, proto/openshell.proto:162, proto/openshell.proto:172, proto/openshell.proto:181, proto/openshell.proto:190, proto/openshell.proto:199, proto/openshell.proto:208, proto/openshell.proto:217, proto/openshell.proto:226, proto/openshell.proto:235, proto/openshell.proto:244, proto/openshell.proto:25, proto/openshell.proto:253, proto/openshell.proto:262, proto/openshell.proto:273, proto/openshell.proto:282, proto/openshell.proto:291, proto/openshell.proto:300, proto/openshell.proto:309, proto/openshell.proto:319, proto/openshell.proto:32, proto/openshell.proto:329, proto/openshell.proto:339, proto/openshell.proto:349, proto/openshell.proto:359, proto/openshell.proto:368, proto/openshell.proto:378, proto/openshell.proto:388, proto/openshell.proto:39, proto/openshell.proto:398, proto/openshell.proto:408, proto/openshell.proto:417, proto/openshell.proto:427, proto/openshell.proto:443, proto/openshell.proto:452, proto/openshell.proto:462, proto/openshell.proto:472, proto/openshell.proto:48, proto/openshell.proto:482, proto/openshell.proto:490, proto/openshell.proto:499, proto/openshell.proto:507, proto/openshell.proto:513, proto/openshell.proto:522, proto/openshell.proto:530, proto/openshell.proto:539, proto/openshell.proto:552, proto/openshell.proto:559, proto/openshell.proto:566, proto/openshell.proto:584, proto/openshell.proto:597, proto/openshell.proto:604, proto/openshell.proto:610, proto/openshell.proto:617, proto/openshell.proto:631, proto/openshell.proto:64, proto/openshell.proto:644, proto/openshell.proto:652, proto/openshell.proto:661, proto/openshell.proto:671, proto/openshell.proto:681, proto/openshell.proto:691, proto/openshell.proto:700, proto/openshell.proto:709, proto/openshell.proto:719, proto/openshell.proto:732, proto/openshell.proto:74, proto/openshell.proto:744, proto/openshell.proto:756, proto/openshell.proto:765, proto/openshell.proto:774, proto/openshell.proto:783, proto/openshell.proto:792, proto/openshell.proto:801, proto/openshell.proto:810, proto/openshell.proto:83, proto/openshell.proto:92, proto/supervisor_middleware.proto:17, proto/supervisor_middleware.proto:20, proto/supervisor_middleware.proto:24, proto/supervisor_middleware.proto:33, proto/supervisor_middleware.proto:49]
- **http_endpoints (observed)**: 10 http_endpoints facts extracted [source: crates/openshell-server/src/auth/http.rs:60, crates/openshell-server/src/auth/http.rs:61, crates/openshell-server/src/auth/http.rs:62, crates/openshell-server/src/auth/http.rs:63, crates/openshell-server/src/http.rs:163, crates/openshell-server/src/http.rs:164, crates/openshell-server/src/http.rs:165, crates/openshell-server/src/http.rs:172, crates/openshell-server/src/ws_tunnel.rs:37, sdk/go/openshell/v1/oidc/authcode.go:99]
- **services (observed)**: 2 services facts extracted
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `crates/openshell-server/src/auth/http.rs`:62 (/api/v1/*, /api/v2/*, Header passthrough)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `crates/openshell-server/src/auth/http.rs`:62 (/health, /info, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.cli`:27 (deploy/docker/Dockerfile.cli:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.gateway`:23 (deploy/docker/Dockerfile.gateway:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.gateway`:24 (deploy/docker/Dockerfile.gateway:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.konflux.cli`:129 (deploy/docker/Dockerfile.konflux.cli:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.konflux.e2e-odh`:134 (deploy/docker/Dockerfile.konflux.e2e-odh:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.konflux.e2e-odh`:135 (deploy/docker/Dockerfile.konflux.e2e-odh:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.konflux.gateway`:112 (deploy/docker/Dockerfile.konflux.gateway:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.konflux.gateway`:113 (deploy/docker/Dockerfile.konflux.gateway:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.konflux.openclaw`:115 (deploy/docker/Dockerfile.konflux.openclaw:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.konflux.sandbox`:172 (deploy/docker/Dockerfile.konflux.sandbox:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.konflux.supervisor`:131 (deploy/docker/Dockerfile.konflux.supervisor:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.sandbox`:22 (deploy/docker/Dockerfile.sandbox:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### grpc_services

- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/compute_driver.proto`:27 (openshell.compute.v1.ComputeDriver/GetCapabilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/compute_driver.proto`:32 (openshell.compute.v1.ComputeDriver/AuthenticateSandbox)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/compute_driver.proto`:36 (openshell.compute.v1.ComputeDriver/ValidateSandboxCreate)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/compute_driver.proto`:40 (openshell.compute.v1.ComputeDriver/GetSandbox)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/compute_driver.proto`:43 (openshell.compute.v1.ComputeDriver/ListSandboxes)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/compute_driver.proto`:46 (openshell.compute.v1.ComputeDriver/CreateSandbox)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/compute_driver.proto`:49 (openshell.compute.v1.ComputeDriver/StopSandbox)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/compute_driver.proto`:52 (openshell.compute.v1.ComputeDriver/StartSandbox)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/compute_driver.proto`:55 (openshell.compute.v1.ComputeDriver/DeleteSandbox)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/compute_driver.proto`:58 (openshell.compute.v1.ComputeDriver/WatchSandboxes)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/compute_driver.proto`:62 (openshell.compute.v1.ComputeDriver/EnsureWorkspace)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/compute_driver.proto`:65 (openshell.compute.v1.ComputeDriver/DeleteWorkspace)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/openshell-server/src/auth/http.rs`:60 (/auth/connect, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/openshell-server/src/auth/http.rs`:61 (/auth/oidc-config, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/openshell-server/src/auth/http.rs`:62 (/.well-known/jwks.json, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/openshell-server/src/auth/http.rs`:63 (/.well-known/openid-configuration, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/openshell-server/src/http.rs`:163 (/health, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/openshell-server/src/http.rs`:164 (/healthz, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/openshell-server/src/http.rs`:165 (/readyz, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/openshell-server/src/http.rs`:172 (/metrics, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/openshell-server/src/ws_tunnel.rs`:37 (/_ws_tunnel, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `sdk/go/openshell/v1/oidc/authcode.go`:99 (/callback, Unknown, openshell/v1/oidc)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `e2e/python/oidc/helpers.py`:18 (Python library, gRPC framework)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `e2e/helm-plugins/openshell-external-compute-driver/workload-patch.yaml`:4 (openshell)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /api/v1/*, /api/v2/* methods=POST mechanism=Header passthrough enforcement=Application-level filtering policy=Configured headers are forwarded to downstream services [source: crates/openshell-server/src/auth/http.rs:62]
- /health, /info methods=GET mechanism=None enforcement=None policy=Unauthenticated health server [source: crates/openshell-server/src/auth/http.rs:62]
### http_endpoints

- GET /.well-known/jwks.json on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/openshell-server/src/auth/http.rs:62]
- GET /.well-known/openid-configuration on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/openshell-server/src/auth/http.rs:63]
- GET /_ws_tunnel on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/openshell-server/src/ws_tunnel.rs:37]
- GET /auth/connect on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/openshell-server/src/auth/http.rs:60]
- GET /auth/oidc-config on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/openshell-server/src/auth/http.rs:61]
- GET /health on port ; transport= encryption=None auth=None owner= [source: crates/openshell-server/src/http.rs:163]
- GET /healthz on port ; transport= encryption=None auth=None owner= [source: crates/openshell-server/src/http.rs:164]
- GET /metrics on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/openshell-server/src/http.rs:172]
- GET /readyz on port ; transport= encryption=None auth=None owner= [source: crates/openshell-server/src/http.rs:165]
- Unknown /callback on port ; transport=HTTP/1.1 encryption= auth= owner=openshell/v1/oidc [source: sdk/go/openshell/v1/oidc/authcode.go:99]
### internal_dependencies

- gRPC framework interaction=Python library role=runtime-library purpose=gRPC transport for service communication [source: e2e/python/oidc/helpers.py:18]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: StatefulSet workload openshell uses service account  and 2 container(s) [source: e2e/helm-plugins/openshell-external-compute-driver/workload-patch.yaml:4]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP Unknown /callback is owned by openshell/v1/oidc [source: sdk/go/openshell/v1/oidc/authcode.go:99]
### security

- **observed**: GET /health, /info uses None at None; policy=Unauthenticated health server [source: crates/openshell-server/src/auth/http.rs:62]
- **observed**: POST /api/v1/*, /api/v2/* uses Header passthrough at Application-level filtering; policy=Configured headers are forwarded to downstream services [source: crates/openshell-server/src/auth/http.rs:62]
- **dependency-signal**: crypto-library targets rustls: Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification [source: Cargo.toml:40]
- **dependency-signal**: crypto-library targets tokio-rustls: Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification [source: Cargo.toml:40]
- **dependency-signal**: crypto-provider targets aws-lc-rs: Cargo.lock selects this cryptographic provider; FIPS validation depends on build and runtime configuration [source: Cargo.lock:353]
- **dependency-signal**: crypto-provider targets ring: Cargo.lock selects ring as a cryptographic provider; ring is not a FIPS-validated provider [source: Cargo.lock:6516]
- **not-extracted**: fips-posture targets FIPS validation: FIPS validation and runtime provider selection are not fully determined by static dependency/build signals [source: Cargo.toml:40]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: sdk/go/openshell/v1/edge/tunnel.go, sdk/go/openshell/v1/internal/grpc/conn.go]
- **dependency-signal**: tls-config targets google.golang.org/grpc/credentials: TLS configuration import [source: sdk/go/openshell/v1/internal/grpc/conn.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

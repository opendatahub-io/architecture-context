# Analyzer Synthesis Context: openshell

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (observed)**: 124 grpc_services facts extracted [source: proto/compute_driver.proto:27, proto/compute_driver.proto:32, proto/compute_driver.proto:36, proto/compute_driver.proto:40, proto/compute_driver.proto:43, proto/compute_driver.proto:46, proto/compute_driver.proto:49, proto/compute_driver.proto:52, proto/compute_driver.proto:61, proto/compute_driver.proto:64, proto/compute_driver.proto:67, proto/compute_driver.proto:71, proto/compute_driver.proto:74, proto/compute_driver.proto:83, proto/compute_driver.proto:91, proto/credential_driver.proto:20, proto/credential_driver.proto:24, proto/credential_driver.proto:27, proto/credential_driver.proto:30, proto/credential_driver.proto:34, proto/gateway_interceptor.proto:17, proto/gateway_interceptor.proto:21, proto/gateway_interceptor.proto:26, proto/isolation_backend.proto:38, proto/isolation_backend.proto:54, proto/isolation_backend.proto:61, proto/isolation_backend.proto:71, proto/openshell.proto:102, proto/openshell.proto:112, proto/openshell.proto:122, proto/openshell.proto:132, proto/openshell.proto:142, proto/openshell.proto:152, proto/openshell.proto:162, proto/openshell.proto:172, proto/openshell.proto:181, proto/openshell.proto:190, proto/openshell.proto:201, proto/openshell.proto:210, proto/openshell.proto:219, proto/openshell.proto:228, proto/openshell.proto:237, proto/openshell.proto:246, proto/openshell.proto:25, proto/openshell.proto:255, proto/openshell.proto:264, proto/openshell.proto:273, proto/openshell.proto:282, proto/openshell.proto:293, proto/openshell.proto:302, proto/openshell.proto:311, proto/openshell.proto:32, proto/openshell.proto:321, proto/openshell.proto:327, proto/openshell.proto:336, proto/openshell.proto:346, proto/openshell.proto:356, proto/openshell.proto:366, proto/openshell.proto:376, proto/openshell.proto:386, proto/openshell.proto:39, proto/openshell.proto:395, proto/openshell.proto:405, proto/openshell.proto:415, proto/openshell.proto:425, proto/openshell.proto:435, proto/openshell.proto:444, proto/openshell.proto:456, proto/openshell.proto:472, proto/openshell.proto:48, proto/openshell.proto:481, proto/openshell.proto:491, proto/openshell.proto:501, proto/openshell.proto:511, proto/openshell.proto:519, proto/openshell.proto:528, proto/openshell.proto:536, proto/openshell.proto:544, proto/openshell.proto:553, proto/openshell.proto:561, proto/openshell.proto:570, proto/openshell.proto:585, proto/openshell.proto:592, proto/openshell.proto:599, proto/openshell.proto:617, proto/openshell.proto:630, proto/openshell.proto:637, proto/openshell.proto:64, proto/openshell.proto:643, proto/openshell.proto:650, proto/openshell.proto:660, proto/openshell.proto:673, proto/openshell.proto:686, proto/openshell.proto:694, proto/openshell.proto:703, proto/openshell.proto:713, proto/openshell.proto:723, proto/openshell.proto:733, proto/openshell.proto:74, proto/openshell.proto:742, proto/openshell.proto:751, proto/openshell.proto:761, proto/openshell.proto:774, proto/openshell.proto:786, proto/openshell.proto:798, proto/openshell.proto:807, proto/openshell.proto:816, proto/openshell.proto:825, proto/openshell.proto:83, proto/openshell.proto:834, proto/openshell.proto:843, proto/openshell.proto:852, proto/openshell.proto:868, proto/openshell.proto:92, proto/sandbox_protocol.proto:24, proto/sandbox_protocol.proto:26, proto/supervisor_host.proto:30, proto/supervisor_middleware.proto:17, proto/supervisor_middleware.proto:20, proto/supervisor_middleware.proto:24, proto/supervisor_middleware.proto:33, proto/supervisor_middleware.proto:49, python/credential_driver_proto_test.py:44, python/grpc_transport_test.py:47]
- **http_endpoints (observed)**: 10 http_endpoints facts extracted [source: crates/openshell-server/src/auth/http.rs:94, crates/openshell-server/src/auth/http.rs:95, crates/openshell-server/src/auth/http.rs:96, crates/openshell-server/src/auth/http.rs:97, crates/openshell-server/src/http.rs:163, crates/openshell-server/src/http.rs:164, crates/openshell-server/src/http.rs:165, crates/openshell-server/src/http.rs:172, crates/openshell-server/src/ws_tunnel.rs:38, sdk/go/openshell/v1/oidc/authcode.go:99]
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
  **Candidate:** `crates/openshell-server/src/auth/http.rs`:96 (/api/v1/*, /api/v2/*, Header passthrough)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `crates/openshell-server/src/auth/http.rs`:96 (/health, /info, None)
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
  **Candidate:** `deploy/docker/Dockerfile.konflux.cli`:131 (deploy/docker/Dockerfile.konflux.cli:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.konflux.e2e-odh`:171 (deploy/docker/Dockerfile.konflux.e2e-odh:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.konflux.e2e-odh`:172 (deploy/docker/Dockerfile.konflux.e2e-odh:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.konflux.gateway`:113 (deploy/docker/Dockerfile.konflux.gateway:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.konflux.gateway`:114 (deploy/docker/Dockerfile.konflux.gateway:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.konflux.openclaw`:119 (deploy/docker/Dockerfile.konflux.openclaw:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.konflux.sandbox`:172 (deploy/docker/Dockerfile.konflux.sandbox:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/docker/Dockerfile.konflux.supervisor`:127 (deploy/docker/Dockerfile.konflux.supervisor:ENTRYPOINT)
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
  **Candidate:** `proto/compute_driver.proto`:61 (openshell.compute.v1.ComputeDriver/SuspendSandbox)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/compute_driver.proto`:64 (openshell.compute.v1.ComputeDriver/DeleteSandbox)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/compute_driver.proto`:71 (openshell.compute.v1.ComputeDriver/EnsureWorkspace)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `proto/compute_driver.proto`:74 (openshell.compute.v1.ComputeDriver/DeleteWorkspace)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/openshell-server/src/auth/http.rs`:94 (/auth/connect, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/openshell-server/src/auth/http.rs`:95 (/auth/oidc-config, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/openshell-server/src/auth/http.rs`:96 (/.well-known/jwks.json, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/openshell-server/src/auth/http.rs`:97 (/.well-known/openid-configuration, GET)
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
  **Candidate:** `crates/openshell-server/src/ws_tunnel.rs`:38 (/_ws_tunnel, GET)
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

- /api/v1/*, /api/v2/* methods=POST mechanism=Header passthrough enforcement=Application-level filtering policy=Configured headers are forwarded to downstream services [source: crates/openshell-server/src/auth/http.rs:96]
- /health, /info methods=GET mechanism=None enforcement=None policy=Unauthenticated health server [source: crates/openshell-server/src/auth/http.rs:96]
### http_endpoints

- GET /.well-known/jwks.json on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/openshell-server/src/auth/http.rs:96]
- GET /.well-known/openid-configuration on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/openshell-server/src/auth/http.rs:97]
- GET /_ws_tunnel on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/openshell-server/src/ws_tunnel.rs:38]
- GET /auth/connect on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/openshell-server/src/auth/http.rs:94]
- GET /auth/oidc-config on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/openshell-server/src/auth/http.rs:95]
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

- **observed**: GET /health, /info uses None at None; policy=Unauthenticated health server [source: crates/openshell-server/src/auth/http.rs:96]
- **observed**: POST /api/v1/*, /api/v2/* uses Header passthrough at Application-level filtering; policy=Configured headers are forwarded to downstream services [source: crates/openshell-server/src/auth/http.rs:96]
- **dependency-signal**: crypto-library targets rustls: Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification [source: Cargo.toml:43]
- **dependency-signal**: crypto-library targets tokio-rustls: Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification [source: Cargo.toml:43]
- **dependency-signal**: crypto-provider targets aws-lc-rs: Cargo.lock selects this cryptographic provider; FIPS validation depends on build and runtime configuration [source: Cargo.lock:382]
- **dependency-signal**: crypto-provider targets openssl: Cargo.lock selects this cryptographic provider; FIPS validation depends on build and runtime configuration [source: Cargo.lock:5452]
- **dependency-signal**: crypto-provider targets ring: Cargo.lock selects ring as a cryptographic provider; ring is not a FIPS-validated provider [source: Cargo.lock:6813]
- **not-extracted**: fips-posture targets FIPS validation: FIPS validation and runtime provider selection are not fully determined by static dependency/build signals [source: Cargo.toml:43]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: sdk/go/openshell/v1/edge/tunnel.go, sdk/go/openshell/v1/internal/grpc/conn.go]
- **dependency-signal**: tls-config targets google.golang.org/grpc/credentials: TLS configuration import [source: sdk/go/openshell/v1/internal/grpc/conn.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

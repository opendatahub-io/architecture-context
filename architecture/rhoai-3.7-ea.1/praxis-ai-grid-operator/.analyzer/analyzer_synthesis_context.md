# Analyzer Synthesis Context: praxis-ai-grid-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 5 crds facts extracted [source: deploy/crds/agenttoolprovider.yaml:1, deploy/crds/gridnetwork.yaml:1, deploy/crds/gridsite.yaml:1, deploy/crds/inferenceprovider.yaml:1, deploy/crds/siteinvite.yaml:1]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 23 http_endpoints facts extracted [source: crates/enrollment/src/api.rs:381, crates/enrollment/src/api.rs:382, crates/enrollment/src/api.rs:383, crates/enrollment/src/api.rs:385, crates/enrollment/src/api.rs:386, crates/enrollment/src/api.rs:390, crates/fleet-dashboard/src/api/routes.rs:45, crates/fleet-dashboard/src/api/routes.rs:46, crates/fleet-dashboard/src/api/routes.rs:47, crates/fleet-dashboard/src/api/routes.rs:48, crates/fleet-dashboard/src/api/routes.rs:49, crates/fleet-dashboard/src/api/routes.rs:53, crates/mock-providers/src/anthropic.rs:25, crates/mock-providers/src/anthropic.rs:26, crates/mock-providers/src/bedrock.rs:26, crates/mock-providers/src/bedrock.rs:27, crates/mock-providers/src/openai.rs:37, crates/mock-providers/src/openai.rs:38, crates/mock-providers/src/openai.rs:39, crates/mock-providers/src/vertex.rs:31, crates/overlay-sync/src/main.rs:345, crates/overlay-sync/src/main.rs:347]
- **services (observed)**: 4 services facts extracted [source: deploy/overlays/kind/service-metrics.yaml:2, deploy/overlays/kind/service-swim.yaml:2]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `crates/fleet-dashboard/src/api/routes.rs`:45 (/api/v1/*, /api/v2/*, Header passthrough)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `crates/fleet-dashboard/src/api/routes.rs`:45 (/health, /info, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `deploy/overlays/kind/deployment.yaml`:2 (:9090/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `deploy/overlays/kind/deployment.yaml`:2 (:9090/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deploy/overlays/kind/clusterrole-crd.yaml`:2 (grid-operator-crd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deploy/overlays/kind/clusterrole-metrics-scraper.yaml`:2 (grid-operator-metrics-scraper)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deploy/overlays/kind/clusterrole-resources.yaml`:2 (grid-operator-resources)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `deploy/overlays/kind/clusterrolebinding-crd.yaml`:2 (grid-operator-crd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `deploy/overlays/kind/clusterrolebinding-metrics-scraper.yaml`:2 (grid-operator-metrics-scraper)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deploy/overlays/kind/role-leader-election.yaml`:3 (grid-operator-leader-election)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deploy/overlays/kind/role-metrics-scraper-token.yaml`:2 (grid-operator-metrics-scraper-token)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deploy/overlays/kind/role-operator-config.yaml`:4 (grid-operator-operator-config)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `deploy/overlays/kind/rolebinding-leader-election.yaml`:2 (grid-operator-leader-election)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `deploy/overlays/kind/rolebinding-metrics-scraper-token.yaml`:2 (grid-operator-metrics-scraper-token)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `deploy/overlays/kind/rolebinding-operator-config.yaml`:2 (grid-operator-operator-config)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `deploy/overlays/kind/rolebinding-resources.yaml`:2 (grid-operator-resources)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/enrollment/Dockerfile.konflux`:30 (deploy/enrollment/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/gateway/Dockerfile.konflux`:38 (deploy/gateway/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/operator/Dockerfile.konflux`:28 (deploy/operator/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `go/_example/main.go`:15 (_example)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `go/cmd/gen-types/main.go`:1196 (gen-types)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/enrollment/src/api.rs`:381 (/healthz, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/enrollment/src/api.rs`:382 (/readyz, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/fleet-dashboard/src/api/routes.rs`:45 (/api/v1/config, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/fleet-dashboard/src/api/routes.rs`:46 (/api/v1/fleet, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/fleet-dashboard/src/api/routes.rs`:47 (/api/v1/sites/{name}, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/fleet-dashboard/src/api/routes.rs`:48 (/api/v1/series, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/fleet-dashboard/src/api/routes.rs`:49 (/api/v1/stream, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/fleet-dashboard/src/api/routes.rs`:53 (/metrics, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/mock-providers/src/anthropic.rs`:26 (/health, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/mock-providers/src/bedrock.rs`:26 (/model/{model_id}/converse, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/mock-providers/src/bedrock.rs`:27 (/model/{model_id}/converse-stream, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `crates/overlay-sync/src/main.rs`:345 (/livez, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deploy/overlays/kind/deployment.yaml`:2 (grid-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/overlays/kind/service-metrics.yaml`:2 (grid-operator, grid-operator-metrics)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/overlays/kind/service-swim.yaml`:2 (grid-operator-swim)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /api/v1/*, /api/v2/* methods=POST mechanism=Header passthrough enforcement=Application-level filtering policy=Configured headers are forwarded to downstream services [source: crates/fleet-dashboard/src/api/routes.rs:45]
- /health, /info methods=GET mechanism=None enforcement=None policy=Unauthenticated health server [source: crates/fleet-dashboard/src/api/routes.rs:45]
- :9090/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/overlays/kind/deployment.yaml:2]
- :9090/readyz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes readiness probe endpoint [source: deploy/overlays/kind/deployment.yaml:2]
### http_endpoints

- DELETE /v1alpha1/enrollments/{site_name} on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/enrollment/src/api.rs:386]
- GET /api/v1/config on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/fleet-dashboard/src/api/routes.rs:45]
- GET /api/v1/fleet on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/fleet-dashboard/src/api/routes.rs:46]
- GET /api/v1/series on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/fleet-dashboard/src/api/routes.rs:48]
- GET /api/v1/sites/{name} on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/fleet-dashboard/src/api/routes.rs:47]
- GET /api/v1/stream on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/fleet-dashboard/src/api/routes.rs:49]
- GET /health on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/mock-providers/src/anthropic.rs:26]
- GET /healthz on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/enrollment/src/api.rs:381]
- GET /livez on port ; transport= encryption=None auth=None owner= [source: crates/overlay-sync/src/main.rs:345]
- GET /metrics on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/fleet-dashboard/src/api/routes.rs:53]
- GET /readyz on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/enrollment/src/api.rs:382]
- GET /status on port ; transport= encryption=None auth=None owner= [source: crates/overlay-sync/src/main.rs:347]
- GET /v1/models on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/mock-providers/src/openai.rs:39]
- GET /v1alpha1/enrollments/{site_name} on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/enrollment/src/api.rs:386]
- POST /model/{model_id}/converse on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/mock-providers/src/bedrock.rs:26]
- POST /model/{model_id}/converse-stream on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/mock-providers/src/bedrock.rs:27]
- POST /v1/chat/completions on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/mock-providers/src/openai.rs:37]
- POST /v1/messages on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/mock-providers/src/anthropic.rs:25]
- POST /v1/projects/{project}/locations/{location}/publishers/google/models/{*rest} on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/mock-providers/src/vertex.rs:31]
- POST /v1/responses on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/mock-providers/src/openai.rs:38]
- POST /v1alpha1/enrollments on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/enrollment/src/api.rs:385]
- POST /v1alpha1/enrollmenttokens on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/enrollment/src/api.rs:383]
- POST /v1alpha1/rotations on port ; transport= encryption=TLS 1.2+ (optional) auth=Passthrough headers owner= [source: crates/enrollment/src/api.rs:390]
### services

- grid-operator-metrics port=9090 target=metrics protocol=TCP encryption= auth= [source: deploy/overlays/kind/service-metrics.yaml:2]
- grid-operator-swim port=7946 target=swim-udp protocol=UDP encryption= auth= [source: deploy/overlays/kind/service-swim.yaml:2]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload grid-operator uses service account grid-operator and 1 container(s) [source: deploy/overlays/kind/deployment.yaml:2]
- **observed**: Service grid-operator-metrics targets grid-operator with 1 port(s) [source: deploy/overlays/kind/service-metrics.yaml:2]
- **observed**: Service grid-operator-swim targets  with 1 port(s) [source: deploy/overlays/kind/service-swim.yaml:2]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: GET /health, /info uses None at None; policy=Unauthenticated health server [source: crates/fleet-dashboard/src/api/routes.rs:45]
- **observed**: GET :9090/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/overlays/kind/deployment.yaml:2]
- **observed**: GET :9090/readyz uses None at N/A; policy=Unauthenticated Kubernetes readiness probe endpoint [source: deploy/overlays/kind/deployment.yaml:2]
- **observed**: POST /api/v1/*, /api/v2/* uses Header passthrough at Application-level filtering; policy=Configured headers are forwarded to downstream services [source: crates/fleet-dashboard/src/api/routes.rs:45]
- **observed**: RBAC role grid-operator-crd grants 4 rule(s) [source: deploy/overlays/kind/clusterrole-crd.yaml:2]
- **observed**: RBAC role grid-operator-leader-election grants 7 rule(s) [source: deploy/overlays/kind/role-leader-election.yaml:3]
- **observed**: RBAC role grid-operator-metrics-scraper grants 1 rule(s) [source: deploy/overlays/kind/clusterrole-metrics-scraper.yaml:2]
- **observed**: RBAC role grid-operator-metrics-scraper-token grants 1 rule(s) [source: deploy/overlays/kind/role-metrics-scraper-token.yaml:2]
- **observed**: RBAC role grid-operator-operator-config grants 1 rule(s) [source: deploy/overlays/kind/role-operator-config.yaml:4]
- **observed**: RBAC role grid-operator-resources grants 6 rule(s) [source: deploy/overlays/kind/clusterrole-resources.yaml:2]
- **dependency-signal**: crypto-library targets hyper-rustls: Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification [source: Cargo.toml:54]
- **dependency-signal**: crypto-library targets rustls: Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification [source: Cargo.toml:54]
- **dependency-signal**: crypto-library targets tokio-rustls: Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification [source: Cargo.toml:107]
- **dependency-signal**: crypto-provider targets openssl: Cargo.lock selects this cryptographic provider; FIPS validation depends on build and runtime configuration [source: Cargo.lock:2494]
- **dependency-signal**: crypto-provider targets ring: Cargo.lock selects ring as a cryptographic provider; ring is not a FIPS-validated provider [source: Cargo.lock:3107]
- **not-extracted**: fips-posture targets FIPS validation: FIPS validation and runtime provider selection are not fully determined by static dependency/build signals [source: Cargo.toml:54]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

# Analyzer Synthesis Context: trustyai-explainability

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (observed)**: 1 services facts extracted [source: explainability-service/manifests/base/trustyai-deployment.yaml:2]
- **ingress (observed)**: 1 ingress facts extracted [source: explainability-service/manifests/base/route.yaml:1]
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Gap Evidence Index

### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `explainability-service/manifests/base/trustyai-deployment.yaml`:159 (trustyai-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `explainability-service/manifests/base/trustyai-deployment.yaml`:177 (trustyai-clusterrolebinding, trustyai-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `explainability-service/src/main/docker/Dockerfile.native`:27 (explainability-service/src/main/docker/Dockerfile.native:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `explainability-service/src/main/docker/Dockerfile.native-micro`:30 (explainability-service/src/main/docker/Dockerfile.native-micro:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `tests/Dockerfile`:49 (tests/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `explainability-service/manifests/base/trustyai-deployment.yaml`:2 (Inbound scrape, Prometheus)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `explainability-service/manifests/base/trustyai-deployment.yaml`:2 (Prometheus, monitoring)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `explainability-service/manifests/base/trustyai-deployment.yaml`:27 (trustyai-service, trustyai-serviceaccount)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `explainability-service/manifests/base/trustyai-deployment.yaml`:2 (trustyai-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### integrations

- Prometheus interaction=Inbound scrape role=unknown protocol=HTTP purpose=Metrics collection via prometheus.io/scrape annotation at /q/metrics [source: explainability-service/manifests/base/trustyai-deployment.yaml:2]
### internal_dependencies

- Prometheus interaction=monitoring role=unknown purpose=Metrics scraping via service annotations [source: explainability-service/manifests/base/trustyai-deployment.yaml:2]
### services

- trustyai-service port=80 target=8080 protocol=TCP encryption= auth= [source: explainability-service/manifests/base/trustyai-deployment.yaml:2]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload trustyai-service uses service account trustyai-serviceaccount and 1 container(s) [source: explainability-service/manifests/base/trustyai-deployment.yaml:27]
- **observed**: Service trustyai-service targets trustyai-service with 1 port(s) [source: explainability-service/manifests/base/trustyai-deployment.yaml:2]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: Route trustyai serves host  via plaintext; backend=trustyai-service; transport=HTTP [source: explainability-service/manifests/base/route.yaml:1]
### security

- **observed**: RBAC role trustyai-role grants 1 rule(s) [source: explainability-service/manifests/base/trustyai-deployment.yaml:159]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

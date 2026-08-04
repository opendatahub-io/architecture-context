# Analyzer Synthesis Context: llm-d-routing-sidecar

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 1 http_endpoints facts extracted [source: internal/proxy/proxy.go:276]
- **services (observed)**: 1 services facts extracted [source: deploy/common/patch-service.yaml:1]
- **ingress (observed)**: 1 ingress facts extracted [source: deploy/openshift/patch-route.yaml:1]
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `internal/proxy/allowlist.go`:68 (Kubernetes API, kubeconfig credential chain)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deploy/rbac/patch-rbac-role.yaml`:1 (${PROJECT_NAME}-exec-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `deploy/rbac/patch-rbac-rolebinding.yaml`:1 (${PROJECT_NAME}-exec-role, ${PROJECT_NAME}-exec-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:31 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/llm-d-routing-sidecar/main.go`:30 (llm-d-routing-sidecar)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `internal/proxy/allowlist.go`:85 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `internal/proxy/proxy.go`:276 (/, Unknown, internal/proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/common/patch-service.yaml`:1 (${PROJECT_NAME}-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deploy/common/patch-statefulset.yaml`:1 (${PROJECT_NAME}-0, operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- Kubernetes API methods=REST mechanism=kubeconfig credential chain enforcement=kube-apiserver policy=Kubeconfig-based authentication using user-provided credentials [source: internal/proxy/allowlist.go:68]
### http_endpoints

- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=internal/proxy [source: internal/proxy/proxy.go:276]
### services

- ${PROJECT_NAME}-service port=8080 target=8080 protocol=TCP encryption= auth= [source: deploy/common/patch-service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service ${PROJECT_NAME}-service targets  with 1 port(s) [source: deploy/common/patch-service.yaml:1]
- **observed**: StatefulSet workload ${PROJECT_NAME}-0 uses service account operator-controller-manager and 1 container(s) [source: deploy/common/patch-statefulset.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP Unknown / is owned by internal/proxy [source: internal/proxy/proxy.go:276]
- **observed**: Route ${PROJECT_NAME}-route serves host  via TLS; backend=${PROJECT_NAME}-service; transport=HTTPS [source: deploy/openshift/patch-route.yaml:1]
### security

- **observed**: RBAC role ${PROJECT_NAME}-exec-role grants 1 rule(s) [source: deploy/rbac/patch-rbac-role.yaml:1]
- **observed**: REST Kubernetes API uses kubeconfig credential chain at kube-apiserver; policy=Kubeconfig-based authentication using user-provided credentials [source: internal/proxy/allowlist.go:68]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: internal/proxy/proxy.go, internal/proxy/tls.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

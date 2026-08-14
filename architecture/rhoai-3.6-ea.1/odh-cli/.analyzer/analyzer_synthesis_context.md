# Analyzer Synthesis Context: odh-cli

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/util/kube/rbac/check.go`:60 (Kubernetes API (6443/TCP), k8s.io/client-go transport credentials)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:98 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:60 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/main.go`:28 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `tools/gen-schemas/main.go`:25 (gen-schemas)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/util/client/client.go`:152 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/diagnose/format.go`:8 (Go library, opendatahub-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/util/client/client.go`:87 (Go module import (API + client), Operator Lifecycle Manager (OLM))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/util/kube/olm/install.go`:292 (/v1/Namespace, create operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/util/kube/rbac/check.go`:60 (authorization/v1/SelfSubjectAccessReview, create operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/util/kube/olm/install.go`:292 (/v1/Namespace, create operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/util/kube/rbac/check.go`:60 (authorization/v1/SelfSubjectAccessReview, create operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- Kubernetes API (6443/TCP) methods=kubeconfig credential chain (bearer token, client certificate, OIDC) mechanism=k8s.io/client-go transport credentials enforcement=kube-apiserver policy=RBAC pre-flight via SelfSubjectAccessReview before privileged operations [source: pkg/util/kube/rbac/check.go:60]
### internal_dependencies

- Operator Lifecycle Manager (OLM) interaction=Go module import (API + client) role=runtime-integration purpose=CSV and subscription inspection for operator lifecycle operations [source: pkg/util/client/client.go:87]
- opendatahub-operator interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/opendatahub-operator/pkg/clusterhealth [source: pkg/diagnose/format.go:8]

## Cross-Cutting Evidence

### deployment_topology

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:deployment_topology]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: kubeconfig credential chain (bearer token, client certificate, OIDC) Kubernetes API (6443/TCP) uses k8s.io/client-go transport credentials at kube-apiserver; policy=RBAC pre-flight via SelfSubjectAccessReview before privileged operations [source: pkg/util/kube/rbac/check.go:60]
- **literal**: rbac-ref targets SelfSubjectAccessReviews: Token or subject access review call [source: pkg/util/kube/rbac/check.go:60]
- **dependency-signal**: rbac-ref targets k8s.io/client-go/kubernetes/typed/authorization/v1: RBAC/authorization API import [source: pkg/util/client/client.go, pkg/util/client/interfaces.go, pkg/util/kube/rbac/check.go]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: pkg/migrate/actions/trustyai/metrics/http.go, pkg/util/errors/errors.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

# Analyzer Synthesis Context: kube-auth-proxy

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (observed)**: 2 services facts extracted [source: examples/openshift/service-account/deployment.yaml:131, examples/openshift/service-account/deployment.yaml:191]
- **ingress (observed)**: 1 ingress facts extracted [source: examples/openshift/service-account/deployment.yaml:208]
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/authentication/k8s/tokenreview.go`:84 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:74 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:88 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.redhat`:85 (Dockerfile.redhat:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `main.go`:17 (v1)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/authentication/k8s/tokenreview.go`:107 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/sessions/redis/redis_store.go`:178 (Redis/Valkey, go-redis client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `pkg/sessions/redis/redis_store.go`:178 (Exchange client, Redis/Valkey)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/authentication/k8s/tokenreview.go`:227 (authentication/v1/TokenReview, create operations by TokenReviewValidator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/authentication/k8s/tokenreview.go`:227 (authentication/v1/TokenReview, create operations by TokenReviewValidator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `examples/openshift/service-account/deployment.yaml`:2 (kube-auth-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `examples/openshift/service-account/deployment.yaml`:131 (kube-auth-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=In-cluster configuration provides automatic ServiceAccount token authentication [source: pkg/authentication/k8s/tokenreview.go:84]
- Token validation methods=Kubernetes TokenReview API mechanism=Kubernetes TokenReview API enforcement=Application-level token validation via kube-apiserver policy=Validates bearer tokens against Kubernetes TokenReview API [source: pkg/authentication/k8s/tokenreview.go:219]
### integrations

- Redis/Valkey interaction=Exchange client role=runtime-integration protocol=TCP purpose=Runtime queue and key-value data store [source: pkg/sessions/redis/redis_store.go:178]
### services

- example-app port=8080 target=8080 protocol=TCP encryption= auth= [source: examples/openshift/service-account/deployment.yaml:191]
- kube-auth-proxy port=80 target=4180 protocol=TCP encryption= auth= [source: examples/openshift/service-account/deployment.yaml:131]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload example-app uses service account  and 1 container(s) [source: examples/openshift/service-account/deployment.yaml:158]
- **observed**: Deployment workload kube-auth-proxy uses service account kube-auth-proxy and 1 container(s) [source: examples/openshift/service-account/deployment.yaml:2]
- **observed**: Service example-app targets example-app with 1 port(s) [source: examples/openshift/service-account/deployment.yaml:191]
- **observed**: Service kube-auth-proxy targets kube-auth-proxy with 1 port(s) [source: examples/openshift/service-account/deployment.yaml:131]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: Route kube-auth-proxy serves host your-app.apps.cluster.example.com via TLS; backend=kube-auth-proxy; transport=HTTPS [source: examples/openshift/service-account/deployment.yaml:208]
### security

- **observed**: Kubernetes TokenReview API Token validation uses Kubernetes TokenReview API at Application-level token validation via kube-apiserver; policy=Validates bearer tokens against Kubernetes TokenReview API [source: pkg/authentication/k8s/tokenreview.go:219]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=In-cluster configuration provides automatic ServiceAccount token authentication [source: pkg/authentication/k8s/tokenreview.go:84]
- **literal**: rbac-ref targets NewTokenReviewValidator: Token or subject access review call [source: main.go:62]
- **literal**: rbac-ref targets TokenReviews: Token or subject access review call [source: pkg/authentication/k8s/tokenreview.go:227]
- **literal**: rbac-ref targets doTokenReview: Token or subject access review call [source: pkg/authentication/k8s/tokenreview.go:179]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: pkg/http/server.go, pkg/sessions/redis/redis_store.go, pkg/validation/options.go, providers/openshift.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

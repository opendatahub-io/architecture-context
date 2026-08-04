# Analyzer Synthesis Context: kube-rbac-proxy

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:341, cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:422]
- **services (observed)**: 2 services facts extracted [source: examples/verb-override/deployment.yaml:33, test/kubetest/testtemplates/data/service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/kube-rbac-proxy/app/kube-rbac-proxy.go`:507 (Kubernetes API, kubeconfig credential chain)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `examples/minikube-rbac/minikube-rbac-fix.yaml`:2 (cluster-writer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `examples/minikube-rbac/minikube-rbac-fix.yaml`:28 (cluster-write, cluster-writer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `examples/oidc/client-rbac.yaml`:9 (metrics)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `examples/resource-attributes/client-rbac.yaml`:1 (kube-rbac-proxy-client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `examples/resource-attributes/client-rbac.yaml`:10 (kube-rbac-proxy-client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `examples/static-auth/client-rbac.yaml`:14 (namespace-metrics)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `examples/verb-override/client-rbac.yaml`:7 (kube-rbac-proxy-verb-override-client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `examples/verb-override/deployment.yaml`:19 (kube-rbac-proxy-verb-override)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `examples/verb-override/deployment.yaml`:6 (kube-rbac-proxy-verb-override)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `scripts/templates/rewrites-deployment.yaml`:6 (kube-rbac-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `test/kubetest/testtemplates/data/auth-delegator-clusterrole.yaml`:1 (kube-rbac-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `test/kubetest/testtemplates/data/metrics-clusterrole.yaml`:1 (metrics)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:13 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:25 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.ocp`:24 (Dockerfile.ocp:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.redhat`:29 (Dockerfile.redhat:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/kube-rbac-proxy/main.go`:27 (kube-rbac-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/example-client-urlquery/Dockerfile`:5 (examples/example-client-urlquery/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/example-client/Dockerfile`:5 (examples/example-client/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/grpcc/Dockerfile`:20 (examples/grpcc/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/kube-rbac-proxy/app/kube-rbac-proxy.go`:213 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/kube-rbac-proxy/app/kube-rbac-proxy.go`:341 (/, Unknown, cmd/kube-rbac-proxy/app)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `cmd/kube-rbac-proxy/main.go` (Sidecar (localhost), kube-rbac-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `examples/verb-override/deployment.yaml`:60 (Sidecar (localhost), kube-rbac-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `test/kubetest/testtemplates/data/deployment.yaml`:1 (Sidecar (localhost), kube-rbac-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `cmd/kube-rbac-proxy/main.go` (Sidecar Container, kube-rbac-proxy (odh-kube-auth-proxy))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `examples/verb-override/deployment.yaml`:60 (Sidecar Container, kube-rbac-proxy (odh-kube-auth-proxy))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `test/kubetest/testtemplates/data/deployment.yaml`:1 (Sidecar Container, kube-rbac-proxy (odh-kube-auth-proxy))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `examples/verb-override/deployment.yaml`:60 (kube-rbac-proxy-verb-override)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `examples/verb-override/deployment.yaml`:33 (kube-rbac-proxy-verb-override)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `test/kubetest/testtemplates/data/deployment.yaml`:1 (kube-rbac-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `test/kubetest/testtemplates/data/service.yaml`:1 (kube-rbac-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via kube-rbac-proxy ClusterRole; SA kube-rbac-proxy [source: cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:213]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via kube-rbac-proxy-verb-override ClusterRole; SA kube-rbac-proxy-verb-override [source: cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:213]
- Kubernetes API methods=REST mechanism=kubeconfig credential chain enforcement=kube-apiserver policy=Kubeconfig-based authentication using user-provided credentials [source: cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:507]
- Proxied HTTP requests methods=ALL mechanism=Configured request authentication (OIDC or Kubernetes TokenReview) enforcement=WithAuthentication and WithAuthorization handler chain policy=Non-bypassed requests require authentication and static or SubjectAccessReview authorization; configured ignore paths bypass these checks [source: cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:330]
### http_endpoints

- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/kube-rbac-proxy/app [source: cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:341]
- Unknown /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/kube-rbac-proxy/app [source: cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:422]
### integrations

- kube-rbac-proxy interaction=Sidecar (localhost) role=unknown protocol=HTTPS to HTTP purpose=Authentication enforcement [source: test/kubetest/testtemplates/data/deployment.yaml:1]
- kube-rbac-proxy interaction=Sidecar (localhost) role=unknown protocol=HTTPS to HTTP purpose=Authentication enforcement [source: examples/verb-override/deployment.yaml:60]
- kube-rbac-proxy interaction=Sidecar (localhost) role=unknown protocol=HTTPS to HTTP purpose=Authentication enforcement [source: cmd/kube-rbac-proxy/main.go]
### internal_dependencies

- kube-rbac-proxy (odh-kube-auth-proxy) interaction=Sidecar Container role=unknown purpose=TLS termination and authentication enforcement [source: test/kubetest/testtemplates/data/deployment.yaml:1]
- kube-rbac-proxy (odh-kube-auth-proxy) interaction=Sidecar Container role=unknown purpose=TLS termination and authentication enforcement [source: examples/verb-override/deployment.yaml:60]
- kube-rbac-proxy (odh-kube-auth-proxy) interaction=Sidecar Container role=unknown purpose=TLS termination and authentication enforcement [source: cmd/kube-rbac-proxy/main.go]
### services

- kube-rbac-proxy port=8443 target=https protocol=TCP encryption= auth= [source: test/kubetest/testtemplates/data/service.yaml:1]
- kube-rbac-proxy-verb-override port=8443 target=https protocol=TCP encryption= auth= [source: examples/verb-override/deployment.yaml:33]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload kube-rbac-proxy uses service account kube-rbac-proxy and 2 container(s) [source: test/kubetest/testtemplates/data/deployment.yaml:1]
- **observed**: Deployment workload kube-rbac-proxy-verb-override uses service account kube-rbac-proxy-verb-override and 2 container(s) [source: examples/verb-override/deployment.yaml:60]
- **observed**: Service kube-rbac-proxy targets kube-rbac-proxy with 1 port(s) [source: test/kubetest/testtemplates/data/service.yaml:1]
- **observed**: Service kube-rbac-proxy-verb-override targets kube-rbac-proxy-verb-override with 1 port(s) [source: examples/verb-override/deployment.yaml:33]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP Unknown / is owned by cmd/kube-rbac-proxy/app [source: cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:341]
- **observed**: HTTP Unknown /healthz is owned by cmd/kube-rbac-proxy/app [source: cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:422]
### security

- **observed**: ALL Proxied HTTP requests uses Configured request authentication (OIDC or Kubernetes TokenReview) at WithAuthentication and WithAuthorization handler chain; policy=Non-bypassed requests require authentication and static or SubjectAccessReview authorization; configured ignore paths bypass these checks [source: cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:330]
- **observed**: RBAC role cluster-reader grants 2 rule(s) [source: examples/minikube-rbac/minikube-rbac-fix.yaml:16]
- **observed**: RBAC role cluster-writer grants 2 rule(s) [source: examples/minikube-rbac/minikube-rbac-fix.yaml:2]
- **observed**: RBAC role kube-rbac-proxy grants 2 rule(s) [source: test/kubetest/testtemplates/data/auth-delegator-clusterrole.yaml:1]
- **observed**: RBAC role kube-rbac-proxy-client grants 1 rule(s) [source: examples/resource-attributes/client-rbac.yaml:1]
- **observed**: RBAC role kube-rbac-proxy-verb-override grants 2 rule(s) [source: examples/verb-override/deployment.yaml:19]
- **observed**: RBAC role kube-rbac-proxy-verb-override-client grants 1 rule(s) [source: examples/verb-override/client-rbac.yaml:7]
- **observed**: RBAC role metrics grants 1 rule(s) [source: test/kubetest/testtemplates/data/metrics-clusterrole.yaml:1]
- **observed**: RBAC role namespace-metrics grants 1 rule(s) [source: examples/static-auth/client-rbac.yaml:14]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via kube-rbac-proxy ClusterRole; SA kube-rbac-proxy [source: cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:213]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via kube-rbac-proxy-verb-override ClusterRole; SA kube-rbac-proxy-verb-override [source: cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:213]
- **observed**: REST Kubernetes API uses kubeconfig credential chain at kube-apiserver; policy=Kubeconfig-based authentication using user-provided credentials [source: cmd/kube-rbac-proxy/app/kube-rbac-proxy.go:507]
- **dependency-signal**: rbac-ref targets k8s.io/apiserver/pkg/authorization/authorizer: RBAC/authorization API import [source: pkg/authz/auth.go, pkg/authz/endpoints.go, pkg/filters/auth.go, pkg/hardcodedauthorizer/metrics.go, pkg/proxy/proxy.go]
- **dependency-signal**: rbac-ref targets k8s.io/client-go/kubernetes/typed/authorization/v1: RBAC/authorization API import [source: pkg/authz/auth.go]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/kube-rbac-proxy/app/kube-rbac-proxy.go, cmd/kube-rbac-proxy/app/transport.go, pkg/tls/reloader.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

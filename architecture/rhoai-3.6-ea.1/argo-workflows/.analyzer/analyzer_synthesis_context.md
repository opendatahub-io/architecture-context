# Analyzer Synthesis Context: argo-workflows

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 8 crds facts extracted [source: manifests/base/crds/minimal/argoproj.io_clusterworkflowtemplates.yaml:1, manifests/base/crds/minimal/argoproj.io_cronworkflows.yaml:1, manifests/base/crds/minimal/argoproj.io_workflowartifactgctasks.yaml:2, manifests/base/crds/minimal/argoproj.io_workfloweventbindings.yaml:2, manifests/base/crds/minimal/argoproj.io_workflows.yaml:1, manifests/base/crds/minimal/argoproj.io_workflowtaskresults.yaml:2, manifests/base/crds/minimal/argoproj.io_workflowtasksets.yaml:1, manifests/base/crds/minimal/argoproj.io_workflowtemplates.yaml:1]
- **grpc_services (observed)**: 9 grpc_services facts extracted [source: server/apiserver/argoserver.go:316, server/apiserver/argoserver.go:317, server/apiserver/argoserver.go:318, server/apiserver/argoserver.go:319, server/apiserver/argoserver.go:320, server/apiserver/argoserver.go:321, server/apiserver/argoserver.go:322, server/apiserver/argoserver.go:323, server/apiserver/argoserver.go:324]
- **http_endpoints (observed)**: 16 http_endpoints facts extracted [source: cmd/workflow-controller/main.go:181, server/apiserver/argoserver.go:381, server/apiserver/argoserver.go:389, server/apiserver/argoserver.go:390, server/apiserver/argoserver.go:391, server/apiserver/argoserver.go:392, server/apiserver/argoserver.go:393, server/apiserver/argoserver.go:395, server/apiserver/argoserver.go:396, server/apiserver/argoserver.go:397, server/apiserver/argoserver.go:416, util/pprof/pprof.go:16, util/pprof/pprof.go:17, util/pprof/pprof.go:18, util/pprof/pprof.go:19, util/pprof/pprof.go:20]
- **services (observed)**: 1 services facts extracted [source: manifests/base/argo-server/argo-server-service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/workflow-controller/main.go`:181 (/healthz (Go HTTP default mux), None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:97 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.windows`:61 (Dockerfile.windows:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `argo-argoexec/Dockerfile.ODH`:43 (argo-argoexec/Dockerfile.ODH:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `argo-argoexec/Dockerfile.konflux`:53 (argo-argoexec/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `argo-workflowcontroller/Dockerfile.ODH`:37 (argo-workflowcontroller/Dockerfile.ODH:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `argo-workflowcontroller/Dockerfile.konflux`:48 (argo-workflowcontroller/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/argo/main.go`:12 (argo)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/argoexec/main.go`:18 (argoexec)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `rhoai/Dockerfile.argoexec`:53 (rhoai/Dockerfile.argoexec:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `rhoai/Dockerfile.workflowcontroller`:48 (rhoai/Dockerfile.workflowcontroller:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `test/e2e/images/argosay/v1/Dockerfile`:17 (test/e2e/images/argosay/v1/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `test/e2e/images/argosay/v2/Dockerfile`:5 (test/e2e/images/argosay/v2/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/argo/commands/server.go`:83 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/argoexec/commands/agent.go`:98 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/argoexec/commands/root.go`:99 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/workflow-controller/main.go`:103 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/apiclient/argo-kube-client.go`:53 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `server/auth/gatekeeper.go`:339 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `workflow/common/util.go`:73 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `workflow/controller/controller.go`:183 (Kubernetes API, client-go dynamic client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### grpc_services

- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `server/apiserver/argoserver.go`:323 (ArchivedWorkflowService, server/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/workflow-controller/main.go`:181 (/healthz, Unknown, cmd/workflow-controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `server/apiserver/argoserver.go`:416 (/, Unknown, server/apiserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `util/pprof/pprof.go`:16 (/debug/pprof/, Unknown, util/pprof)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `server/auth/sso/sso.go`:142 (/v1/Secret, create operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `util/auth/auth.go`:16 (authorization/v1/SelfSubjectAccessReview, create operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `workflow/controller/agent.go`:255 (/v1/Pod, create operations by wfOperationCtx)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `workflow/controller/cache/configmap_cache.go`:164 (/v1/ConfigMap, create, update operations by WorkflowController, configMapCache, wfOperationCtx)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `workflow/controller/operator.go`:3928 (create operations by wfOperationCtx, policy/v1/PodDisruptionBudget)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `server/auth/sso/sso.go`:142 (/v1/Secret, create operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `util/auth/auth.go`:16 (authorization/v1/SelfSubjectAccessReview, create operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `workflow/controller/agent.go`:255 (/v1/Pod, create operations by wfOperationCtx)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `workflow/controller/cache/configmap_cache.go`:164 (/v1/ConfigMap, create, update operations by WorkflowController, configMapCache, wfOperationCtx)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `workflow/controller/operator.go`:3928 (create operations by wfOperationCtx, policy/v1/PodDisruptionBudget)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `manifests/base/argo-server/argo-server-deployment.yaml`:1 (argo-server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `manifests/base/argo-server/argo-server-service.yaml`:1 (argo-server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `manifests/base/workflow-controller/workflow-controller-deployment.yaml`:1 (argo, workflow-controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /healthz (Go HTTP default mux) methods=GET mechanism=None enforcement=N/A policy=Default mux health endpoint with no authentication enforcement [source: cmd/workflow-controller/main.go:181]
### http_endpoints

- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=server/apiserver [source: server/apiserver/argoserver.go:416]
- Unknown /api/ on port ; transport=HTTP/1.1 encryption= auth= owner=server/apiserver [source: server/apiserver/argoserver.go:381]
- Unknown /artifact-files/ on port ; transport=HTTP/1.1 encryption= auth= owner=server/apiserver [source: server/apiserver/argoserver.go:393]
- Unknown /artifacts-by-uid/ on port ; transport=HTTP/1.1 encryption= auth= owner=server/apiserver [source: server/apiserver/argoserver.go:391]
- Unknown /artifacts/ on port ; transport=HTTP/1.1 encryption= auth= owner=server/apiserver [source: server/apiserver/argoserver.go:389]
- Unknown /debug/pprof/ on port ; transport=HTTP/1.1 encryption= auth= owner=util/pprof [source: util/pprof/pprof.go:16]
- Unknown /debug/pprof/cmdline on port ; transport=HTTP/1.1 encryption= auth= owner=util/pprof [source: util/pprof/pprof.go:17]
- Unknown /debug/pprof/profile on port ; transport=HTTP/1.1 encryption= auth= owner=util/pprof [source: util/pprof/pprof.go:18]
- Unknown /debug/pprof/symbol on port ; transport=HTTP/1.1 encryption= auth= owner=util/pprof [source: util/pprof/pprof.go:19]
- Unknown /debug/pprof/trace on port ; transport=HTTP/1.1 encryption= auth= owner=util/pprof [source: util/pprof/pprof.go:20]
- Unknown /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/workflow-controller [source: cmd/workflow-controller/main.go:181]
- Unknown /input-artifacts-by-uid/ on port ; transport=HTTP/1.1 encryption= auth= owner=server/apiserver [source: server/apiserver/argoserver.go:392]
- Unknown /input-artifacts/ on port ; transport=HTTP/1.1 encryption= auth= owner=server/apiserver [source: server/apiserver/argoserver.go:390]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=server/apiserver [source: server/apiserver/argoserver.go:397]
- Unknown /oauth2/callback on port ; transport=HTTP/1.1 encryption= auth= owner=server/apiserver [source: server/apiserver/argoserver.go:396]
- Unknown /oauth2/redirect on port ; transport=HTTP/1.1 encryption= auth= owner=server/apiserver [source: server/apiserver/argoserver.go:395]
### services

- argo-server port=2746 target=2746 protocol=TCP encryption= auth= [source: manifests/base/argo-server/argo-server-service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload argo-server uses service account argo-server and 1 container(s) [source: manifests/base/argo-server/argo-server-deployment.yaml:1]
- **observed**: Deployment workload workflow-controller uses service account argo and 1 container(s) [source: manifests/base/workflow-controller/workflow-controller-deployment.yaml:1]
- **observed**: Service argo-server targets argo-server with 1 port(s) [source: manifests/base/argo-server/argo-server-service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP Unknown / is owned by server/apiserver [source: server/apiserver/argoserver.go:416]
- **observed**: HTTP Unknown /api/ is owned by server/apiserver [source: server/apiserver/argoserver.go:381]
- **observed**: HTTP Unknown /artifact-files/ is owned by server/apiserver [source: server/apiserver/argoserver.go:393]
- **observed**: HTTP Unknown /artifacts-by-uid/ is owned by server/apiserver [source: server/apiserver/argoserver.go:391]
- **observed**: HTTP Unknown /artifacts/ is owned by server/apiserver [source: server/apiserver/argoserver.go:389]
- **observed**: HTTP Unknown /debug/pprof/ is owned by util/pprof [source: util/pprof/pprof.go:16]
- **observed**: HTTP Unknown /debug/pprof/cmdline is owned by util/pprof [source: util/pprof/pprof.go:17]
- **observed**: HTTP Unknown /debug/pprof/profile is owned by util/pprof [source: util/pprof/pprof.go:18]
- **observed**: HTTP Unknown /debug/pprof/symbol is owned by util/pprof [source: util/pprof/pprof.go:19]
- **observed**: HTTP Unknown /debug/pprof/trace is owned by util/pprof [source: util/pprof/pprof.go:20]
- **observed**: HTTP Unknown /healthz is owned by cmd/workflow-controller [source: cmd/workflow-controller/main.go:181]
- **observed**: HTTP Unknown /input-artifacts-by-uid/ is owned by server/apiserver [source: server/apiserver/argoserver.go:392]
- **observed**: HTTP Unknown /input-artifacts/ is owned by server/apiserver [source: server/apiserver/argoserver.go:390]
- **observed**: HTTP Unknown /metrics is owned by server/apiserver [source: server/apiserver/argoserver.go:397]
- **observed**: HTTP Unknown /oauth2/callback is owned by server/apiserver [source: server/apiserver/argoserver.go:396]
- **observed**: HTTP Unknown /oauth2/redirect is owned by server/apiserver [source: server/apiserver/argoserver.go:395]
### security

- **observed**: GET /healthz (Go HTTP default mux) uses None at N/A; policy=Default mux health endpoint with no authentication enforcement [source: cmd/workflow-controller/main.go:181]
- **literal**: rbac-ref targets SelfSubjectAccessReviews: Token or subject access review call [source: util/auth/auth.go:16]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/argo/commands/cp.go, cmd/argo/commands/server.go, pkg/apiclient/argo-server-client.go, pkg/apiclient/http1/facade.go, server/apiserver/argoserver.go, server/auth/sso/sso.go, util/telemetry/exporter_prometheus.go, util/tls/tls.go, workflow/artifacts/http/clients.go, workflow/executor/agent.go]
- **dependency-signal**: tls-config targets google.golang.org/grpc/credentials: TLS configuration import [source: pkg/apiclient/argo-server-client.go, server/apiserver/argoserver.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

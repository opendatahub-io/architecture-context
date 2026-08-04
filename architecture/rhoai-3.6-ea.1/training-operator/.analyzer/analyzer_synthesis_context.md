# Analyzer Synthesis Context: training-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 6 crds facts extracted [source: manifests/base/crds/kubeflow.org_jaxjobs.yaml:2, manifests/base/crds/kubeflow.org_mpijobs.yaml:2, manifests/base/crds/kubeflow.org_paddlejobs.yaml:2, manifests/base/crds/kubeflow.org_pytorchjobs.yaml:2, manifests/base/crds/kubeflow.org_tfjobs.yaml:2, manifests/base/crds/kubeflow.org_xgboostjobs.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 2 http_endpoints facts extracted [source: cmd/training-operator.v1/main.go:436, cmd/training-operator.v1/main.go:448]
- **services (observed)**: 1 services facts extracted [source: manifests/base/service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 5 webhooks facts extracted [source: manifests/base/webhook/patch.yaml:1, pkg/webhooks/jax/jaxjob_webhook.go:50, pkg/webhooks/paddlepaddle/paddlepaddle_webhook.go:51, pkg/webhooks/pytorch/pytorchjob_webhook.go:51, pkg/webhooks/tensorflow/tfjob_webhook.go:50, pkg/webhooks/xgboost/xgboostjob_webhook.go:51]

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/training-operator.v1/main.go`:436 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `manifests/base/webhook/patch.yaml`:1 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/controller.v1/jax/jaxjob_controller.go`:73 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/util/k8sutil/k8sutil.go`:45 (Kubernetes API, kubeconfig credential chain)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/base/rbac/cluster-role-binding.yaml`:2 (training-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/base/rbac/role.yaml`:2 (training-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `manifests/base/rbac/webhook-secret-role-binding.yaml`:2 (training-operator-webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `manifests/base/rbac/webhook-secret-role.yaml`:2 (training-operator-webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `build/images/kubectl-delivery/Dockerfile`:15 (build/images/kubectl-delivery/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `build/images/training-operator/Dockerfile`:23 (build/images/training-operator/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `build/images/training-operator/Dockerfile.konflux`:40 (build/images/training-operator/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `build/images/training-operator/Dockerfile.multiarch`:7 (build/images/training-operator/Dockerfile.multiarch:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `build/images/training-operator/Dockerfile.rhoai`:26 (build/images/training-operator/Dockerfile.rhoai:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/jax/jax-dist-spmd-mnist/Dockerfile`:29 (examples/jax/jax-dist-spmd-mnist/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/pytorch/elastic/echo/Dockerfile`:8 (examples/pytorch/elastic/echo/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/pytorch/elastic/imagenet/Dockerfile`:19 (examples/pytorch/elastic/imagenet/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/pytorch/mnist/Dockerfile`:15 (examples/pytorch/mnist/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/pytorch/smoke-dist/Dockerfile`:8 (examples/pytorch/smoke-dist/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/tensorflow/dist-mnist/Dockerfile`:24 (examples/tensorflow/dist-mnist/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/tensorflow/distribution_strategy/Dockerfile`:11 (examples/tensorflow/distribution_strategy/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/controller.v1/jax/jaxjob_controller.go`:73 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/controller.v1/mpi/mpijob_controller.go`:82 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/controller.v1/paddlepaddle/paddlepaddle_controller.go`:74 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/controller.v1/pytorch/pytorchjob_controller.go`:77 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/controller.v1/tensorflow/tfjob_controller.go`:77 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/controller.v1/xgboost/xgboostjob_controller.go`:77 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/util/k8sutil/k8sutil.go`:41 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/training-operator.v1/main.go`:436 (/healthz, GET, cmd/training-operator.v1)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `manifests/base/rbac/role.yaml`:2 (CRD CRUD, Kubeflow Notebooks)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `manifests/base/service.yaml`:1 (Inbound scrape, Prometheus)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `cmd/training-operator.v1/main.go`:106 (config.openshift.io/v1/APIServer, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `cmd/training-operator.v1/main.go`:106 (APIServer resource read, OpenShift Cluster Configuration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `manifests/base/rbac/role.yaml`:2 (CRD CRUD, Kubeflow Notebooks (kubeflow.org))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `manifests/base/service.yaml`:1 (Prometheus, monitoring)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller.v1/jax/jaxjob_controller.go`:278 (/v1/Pod, get, list operations by JAXJobReconciler, MPIJobReconciler, PaddleJobReconciler, PyTorchJobReconciler, TFJobReconciler, XGBoostJobReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller.v1/mpi/mpijob_controller.go`:693 (/v1/ConfigMap, get operations by MPIJobReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/controller.v1/pytorch/hpa.go`:50 (autoscaling/v2/HorizontalPodAutoscaler, delete, get operations by PyTorchJobReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `cmd/training-operator.v1/main.go`:106 (config.openshift.io/v1/APIServer, get operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/controller.v1/jax/jaxjob_controller.go`:278 (/v1/Pod, get, list operations by JAXJobReconciler, MPIJobReconciler, PaddleJobReconciler, PyTorchJobReconciler, TFJobReconciler, XGBoostJobReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/controller.v1/mpi/mpijob_controller.go`:693 (/v1/ConfigMap, get operations by MPIJobReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/controller.v1/pytorch/hpa.go`:50 (autoscaling/v2/HorizontalPodAutoscaler, delete, get operations by PyTorchJobReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `manifests/base/deployment.yaml`:1 (training-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `manifests/base/service.yaml`:1 (training-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `manifests/base/webhook/patch.yaml`:1 (/validate-kubeflow-org-v1-jaxjob, validator.jaxjob.training-operator.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/jax/jaxjob_webhook.go`:50 (/validate-kubeflow-org-v1-jaxjob, validator.jaxjob.training-operator.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/paddlepaddle/paddlepaddle_webhook.go`:51 (/validate-kubeflow-org-v1-paddlejob, validator.paddlejob.training-operator.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/pytorch/pytorchjob_webhook.go`:51 (/validate-kubeflow-org-v1-pytorchjob, validator.pytorchjob.training-operator.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/tensorflow/tfjob_webhook.go`:50 (/validate-kubeflow-org-v1-tfjob, validator.tfjob.training-operator.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `pkg/webhooks/xgboost/xgboostjob_webhook.go`:51 (/validate-kubeflow-org-v1-xgboostjob, validator.xgboostjob.training-operator.kubeflow.org)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/training-operator.v1/main.go:436]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/training-operator.v1/main.go:448]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via training-operator ClusterRole; SA training-operator [source: pkg/controller.v1/jax/jaxjob_controller.go:73]
- Kubernetes API methods=REST mechanism=kubeconfig credential chain enforcement=kube-apiserver policy=Kubeconfig-based authentication using user-provided credentials [source: pkg/util/k8sutil/k8sutil.go:45]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: manifests/base/webhook/patch.yaml:1]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/training-operator.v1 [source: cmd/training-operator.v1/main.go:436]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/training-operator.v1 [source: cmd/training-operator.v1/main.go:448]
### integrations

- Kubeflow Notebooks interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Create and manage notebook workbenches [source: manifests/base/rbac/role.yaml:2]
- Prometheus interaction=Inbound scrape role=unknown protocol=HTTP purpose=Metrics collection via prometheus.io/scrape annotation at /metrics [source: manifests/base/service.yaml:1]
### internal_dependencies

- Kubeflow Notebooks (kubeflow.org) interaction=CRD CRUD role=unknown purpose=Create and manage notebook workbenches [source: manifests/base/rbac/role.yaml:2]
- OpenShift Cluster Configuration interaction=APIServer resource read role=runtime-integration purpose=Read cluster-wide API server configuration [source: cmd/training-operator.v1/main.go:106]
- Prometheus interaction=monitoring role=unknown purpose=Metrics scraping via service annotations [source: manifests/base/service.yaml:1]
### services

- training-operator port=443 target=9443 protocol=TCP encryption= auth= [source: manifests/base/service.yaml:1]
- training-operator port=8080 target=8080 protocol=TCP encryption= auth= [source: manifests/base/service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload training-operator uses service account training-operator and 1 container(s) [source: manifests/base/deployment.yaml:1]
- **observed**: Service training-operator targets training-operator with 2 port(s) [source: manifests/base/service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd/training-operator.v1 [source: cmd/training-operator.v1/main.go:436]
- **observed**: HTTP GET /readyz is owned by cmd/training-operator.v1 [source: cmd/training-operator.v1/main.go:448]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: manifests/base/webhook/patch.yaml:1]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/training-operator.v1/main.go:436]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/training-operator.v1/main.go:448]
- **observed**: RBAC role training-operator grants 32 rule(s) [source: manifests/base/rbac/role.yaml:2]
- **observed**: RBAC role training-operator-webhook grants 1 rule(s) [source: manifests/base/rbac/webhook-secret-role.yaml:2]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via training-operator ClusterRole; SA training-operator [source: pkg/controller.v1/jax/jaxjob_controller.go:73]
- **observed**: REST Kubernetes API uses kubeconfig credential chain at kube-apiserver; policy=Kubeconfig-based authentication using user-provided credentials [source: pkg/util/k8sutil/k8sutil.go:45]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/training-operator.v1/main.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

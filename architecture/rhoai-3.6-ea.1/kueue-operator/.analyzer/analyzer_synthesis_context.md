# Analyzer Synthesis Context: kueue-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 24 crds facts extracted [source: bindata/assets/kueue-operator/crds/crd-admissionchecks.kueue.x-k8s.io.yaml:2, bindata/assets/kueue-operator/crds/crd-clusterqueues.kueue.x-k8s.io.yaml:2, bindata/assets/kueue-operator/crds/crd-cohorts.kueue.x-k8s.io.yaml:2, bindata/assets/kueue-operator/crds/crd-localqueues.kueue.x-k8s.io.yaml:2, bindata/assets/kueue-operator/crds/crd-multikueueclusters.kueue.x-k8s.io.yaml:2, bindata/assets/kueue-operator/crds/crd-multikueueconfigs.kueue.x-k8s.io.yaml:2, bindata/assets/kueue-operator/crds/crd-provisioningrequestconfigs.kueue.x-k8s.io.yaml:2, bindata/assets/kueue-operator/crds/crd-resourceflavors.kueue.x-k8s.io.yaml:2, bindata/assets/kueue-operator/crds/crd-topologies.kueue.x-k8s.io.yaml:2, bindata/assets/kueue-operator/crds/crd-workloadpriorityclasses.kueue.x-k8s.io.yaml:2, bindata/assets/kueue-operator/crds/crd-workloads.kueue.x-k8s.io.yaml:2, manifests/kueue.openshift.io_kueues.yaml:2, manifests/operator.openshift.io_kueue.yaml:2]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (observed)**: 6 services facts extracted [source: bindata/assets/kueue-operator/controller-manager-metrics-service.yaml:1, bindata/assets/kueue-operator/visibility-server.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **ingress (not-verified)**: 0 ingress facts extracted; absence is not proven by the available coverage
- **webhooks (observed)**: 70 webhooks facts extracted [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/validatingwebhook.yaml:1]

## Deterministic Cross-References

- **webhook**: mappwrapper.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: mclusterqueue.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: mdeployment.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: mjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: mjobset.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: mleaderworkerset.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: mmpijob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: mpaddlejob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: mpod.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: mpytorchjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: mraycluster.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: mrayjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: mresourceflavor.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: mstatefulset.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: mtfjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: mworkload.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: mxgboostjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/mutatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vappwrapper.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vclusterqueue.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vcohort.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vdeployment.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vjobset.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vleaderworkerset.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vmpijob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vpaddlejob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vpod.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vpytorchjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vraycluster.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vrayjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vresourceflavor.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vstatefulset.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vtfjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vworkload.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]
- **webhook**: vxgboostjob.kb.io —served-by→ kueue-webhook-service; admission webhook declares an explicit service reference [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1, bindata/assets/kueue-operator/webhook-service.yaml:1]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `bindata/assets/kueue-operator/validatingwebhook.yaml`:1 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/operator/starter.go`:45 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `bindata/assets/kueue-operator/clusterroles/clusterrole-clusterqueue-editor-role.yaml`:2 (kueue-clusterqueue-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `bindata/assets/kueue-operator/clusterroles/clusterrole-clusterqueue-viewer-role.yaml`:2 (kueue-clusterqueue-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `bindata/assets/kueue-operator/clusterroles/clusterrole-cohort-editor-role.yaml`:2 (kueue-cohort-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `bindata/assets/kueue-operator/clusterroles/clusterrole-cohort-viewer-role.yaml`:2 (kueue-cohort-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `bindata/assets/kueue-operator/clusterroles/clusterrole-job-editor-role.yaml`:2 (kueue-job-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `bindata/assets/kueue-operator/clusterroles/clusterrole-job-viewer-role.yaml`:2 (kueue-job-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `bindata/assets/kueue-operator/clusterroles/clusterrole-jobset-editor-role.yaml`:2 (kueue-jobset-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `bindata/assets/kueue-operator/clusterroles/clusterrole-jobset-viewer-role.yaml`:2 (kueue-jobset-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `bindata/assets/kueue-operator/clusterroles/clusterrole-localqueue-editor-role.yaml`:2 (kueue-localqueue-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `bindata/assets/kueue-operator/clusterroles/clusterrole-localqueue-viewer-role.yaml`:2 (kueue-localqueue-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deploy/05_clusterrole_kueue-batch.yaml`:1 (kueue-batch-admin-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deploy/06_clusterrole_kueue-admin.yaml`:2 (kueue-batch-user-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/kueue-operator/main.go`:12 (kueue-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `must-gather/Dockerfile`:21 (must-gather/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/operator/starter.go`:45 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `bindata/assets/kueue-operator/clusterroles/clusterrole-manager-role.yaml`:2 (CRD CRUD, Kubeflow Notebooks)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `deploy/02_clusterrole.yaml`:1 (Certificate CR, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `bindata/assets/kueue-operator/clusterroles/clusterrole-manager-role.yaml`:2 (CRD CRUD, Kubeflow Notebooks (kubeflow.org))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `deploy/02_clusterrole.yaml`:1 (CRD CRUD, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `bindata/assets/kueue-operator/controller-manager-metrics-service.yaml`:1 (kueue-controller-manager, kueue-controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `bindata/assets/kueue-operator/deployment.yaml`:1 (kueue-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `bindata/assets/kueue-operator/visibility-server.yaml`:1 (kueue-controller-manager, kueue-visibility-server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `bindata/assets/kueue-operator/webhook-service.yaml`:1 (kueue-controller-manager, kueue-webhook-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deploy/07_deployment.yaml`:1 (openshift-kueue-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `bindata/assets/kueue-operator/mutatingwebhook.yaml`:1 (/mutate--v1-pod, mpod.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `bindata/assets/kueue-operator/validatingwebhook.yaml`:1 (/validate--v1-pod, vpod.kb.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via kueue-manager-role ClusterRole; SA kueue-controller-manager [source: pkg/operator/starter.go:45]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via openshift-kueue-operator ClusterRole; SA openshift-kueue-operator [source: pkg/operator/starter.go:45]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1]
### integrations

- Kubeflow Notebooks interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Create and manage notebook workbenches [source: bindata/assets/kueue-operator/clusterroles/clusterrole-manager-role.yaml:2]
- Kubernetes API interaction=API client role=runtime-integration protocol=HTTPS purpose=Cluster resource management via RBAC [source: bindata/assets/kueue-operator/clusterroles/clusterrole-manager-role.yaml:2]
- cert-manager interaction=Certificate CR role=unknown protocol=HTTPS purpose=Manage TLS certificates through cert-manager CRDs [source: deploy/02_clusterrole.yaml:1]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: deploy/02_clusterrole.yaml:1]
### internal_dependencies

- Kubeflow Notebooks (kubeflow.org) interaction=CRD CRUD role=unknown purpose=Create and manage notebook workbenches [source: bindata/assets/kueue-operator/clusterroles/clusterrole-manager-role.yaml:2]
- Kubernetes API (nodes) interaction=list role=unknown purpose=nodes resource access via RBAC [source: bindata/assets/kueue-operator/clusterroles/clusterrole-manager-role.yaml:2]
- cert-manager interaction=CRD CRUD role=unknown purpose=Manage TLS certificates through cert-manager CRDs [source: deploy/02_clusterrole.yaml:1]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: deploy/02_clusterrole.yaml:1]
### services

- kueue-controller-manager-metrics-service port=8443 target=8443 protocol=TCP encryption= auth= [source: bindata/assets/kueue-operator/controller-manager-metrics-service.yaml:1]
- kueue-controller-manager-metrics-service port=8443 target=8443 protocol=TCP encryption= auth= [source: bindata/assets/kueue-operator/controller-manager-metrics-service.yaml:1]
- kueue-visibility-server port=443 target=8082 protocol=TCP encryption= auth= [source: bindata/assets/kueue-operator/visibility-server.yaml:1]
- kueue-visibility-server port=443 target=8082 protocol=TCP encryption= auth= [source: bindata/assets/kueue-operator/visibility-server.yaml:1]
- kueue-webhook-service port=443 target=9443 protocol=TCP encryption= auth= [source: bindata/assets/kueue-operator/webhook-service.yaml:1]
- kueue-webhook-service port=443 target=9443 protocol=TCP encryption= auth= [source: bindata/assets/kueue-operator/webhook-service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Controller-created Deployment workload kueue-controller-manager uses service account kueue-controller-manager and 1 container(s) [source: bindata/assets/kueue-operator/deployment.yaml:1]
- **observed**: Deployment workload kueue-controller-manager uses service account kueue-controller-manager and 1 container(s) [source: bindata/assets/kueue-operator/deployment.yaml:1]
- **observed**: Deployment workload openshift-kueue-operator uses service account openshift-kueue-operator and 1 container(s) [source: deploy/07_deployment.yaml:1]
- **observed**: Service kueue-controller-manager-metrics-service targets kueue-controller-manager with 1 port(s) [source: bindata/assets/kueue-operator/controller-manager-metrics-service.yaml:1]
- **observed**: Service kueue-visibility-server targets kueue-controller-manager with 1 port(s) [source: bindata/assets/kueue-operator/visibility-server.yaml:1]
- **observed**: Service kueue-webhook-service targets kueue-controller-manager with 1 port(s) [source: bindata/assets/kueue-operator/webhook-service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: bindata/assets/kueue-operator/validatingwebhook.yaml:1]
- **observed**: RBAC role kueue-batch-admin-role grants 0 rule(s) [source: deploy/05_clusterrole_kueue-batch.yaml:1]
- **observed**: RBAC role kueue-batch-user-role grants 0 rule(s) [source: deploy/06_clusterrole_kueue-admin.yaml:2]
- **observed**: RBAC role kueue-clusterqueue-editor-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-clusterqueue-editor-role.yaml:2]
- **observed**: RBAC role kueue-clusterqueue-viewer-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-clusterqueue-viewer-role.yaml:2]
- **observed**: RBAC role kueue-cohort-editor-role grants 1 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-cohort-editor-role.yaml:2]
- **observed**: RBAC role kueue-cohort-viewer-role grants 1 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-cohort-viewer-role.yaml:2]
- **observed**: RBAC role kueue-job-editor-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-job-editor-role.yaml:2]
- **observed**: RBAC role kueue-job-viewer-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-job-viewer-role.yaml:2]
- **observed**: RBAC role kueue-jobset-editor-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-jobset-editor-role.yaml:2]
- **observed**: RBAC role kueue-jobset-viewer-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-jobset-viewer-role.yaml:2]
- **observed**: RBAC role kueue-localqueue-editor-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-localqueue-editor-role.yaml:2]
- **observed**: RBAC role kueue-localqueue-viewer-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-localqueue-viewer-role.yaml:2]
- **observed**: RBAC role kueue-manager-role grants 36 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-manager-role.yaml:2]
- **observed**: RBAC role kueue-metrics-auth-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-metrics-auth-role.yaml:2]
- **observed**: RBAC role kueue-metrics-reader grants 1 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-metrics-reader.yaml:2]
- **observed**: RBAC role kueue-mpijob-editor-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-mpijob-editor-role.yaml:2]
- **observed**: RBAC role kueue-mpijob-viewer-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-mpijob-viewer-role.yaml:2]
- **observed**: RBAC role kueue-mxjob-editor-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-mxjob-editor-role.yaml:2]
- **observed**: RBAC role kueue-mxjob-viewer-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-mxjob-viewer-role.yaml:2]
- **observed**: RBAC role kueue-paddlejob-editor-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-paddlejob-editor-role.yaml:2]
- **observed**: RBAC role kueue-paddlejob-viewer-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-paddlejob-viewer-role.yaml:2]
- **observed**: RBAC role kueue-pending-workloads-cq-viewer-role grants 1 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-pending-workloads-cq-viewer-role.yaml:2]
- **observed**: RBAC role kueue-pending-workloads-lq-viewer-role grants 1 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-pending-workloads-lq-viewer-role.yaml:2]
- **observed**: RBAC role kueue-proxy-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-proxy-role.yaml:2]
- **observed**: RBAC role kueue-pytorchjob-editor-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-pytorchjob-editor-role.yaml:2]
- **observed**: RBAC role kueue-pytorchjob-viewer-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-pytorchjob-viewer-role.yaml:2]
- **observed**: RBAC role kueue-raycluster-editor-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-raycluster-editor-role.yaml:2]
- **observed**: RBAC role kueue-raycluster-viewer-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-raycluster-viewer-role.yaml:2]
- **observed**: RBAC role kueue-rayjob-editor-role grants 2 rule(s) [source: bindata/assets/kueue-operator/clusterroles/clusterrole-rayjob-editor-role.yaml:2]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via kueue-manager-role ClusterRole; SA kueue-controller-manager [source: pkg/operator/starter.go:45]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via openshift-kueue-operator ClusterRole; SA openshift-kueue-operator [source: pkg/operator/starter.go:45]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

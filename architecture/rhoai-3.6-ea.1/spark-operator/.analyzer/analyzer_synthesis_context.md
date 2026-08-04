# Analyzer Synthesis Context: spark-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 4 crds facts extracted [source: config/crd/patches/webhook_in_scheduledsparkapplications.yaml:2, config/crd/patches/webhook_in_sparkapplications.yaml:2, config/crd/patches/webhook_in_sparkconnects.yaml:2, spark-operator-module/pkg/apis/v1alpha1/types.go:26]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 6 http_endpoints facts extracted [source: cmd/operator/controller/start.go:429, cmd/operator/controller/start.go:434, cmd/operator/webhook/start.go:336, cmd/operator/webhook/start.go:341, spark-operator-module/cmd/spark-operator-module/main.go:89, spark-operator-module/cmd/spark-operator-module/main.go:93]
- **services (observed)**: 1 services facts extracted [source: config/webhook/service.yaml:3]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 20 webhooks facts extracted [source: config/crd/patches/webhook_in_scheduledsparkapplications.yaml:3, config/crd/patches/webhook_in_sparkapplications.yaml:3, config/crd/patches/webhook_in_sparkconnects.yaml:3, config/webhook/mutatingwebhookconfiguration.yaml:7, config/webhook/validatingwebhookconfiguration.yaml:8, config/webhook/webhook-objectselector-patch.yaml:1, config/webhook/webhook-validating-selector-patch.yaml:9, internal/webhook/scheduledsparkapplication_defaulter.go:28, internal/webhook/scheduledsparkapplication_validator.go:34, internal/webhook/sparkapplication_defaulter.go:30, internal/webhook/sparkapplication_validator.go:37, internal/webhook/sparkconnect_defaulter.go:29, internal/webhook/sparkconnect_validator.go:35, internal/webhook/sparkpod_defaulter.go:43]

## Deterministic Cross-References

- **controller**: Reconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/sparkapplication/monitoring_config.go:50, internal/controller/sparkconnect/reconciler.go:112]
- **controller**: Reconciler —watches-reference→ /v1/Pod; /v1/Pod [source: internal/controller/sparkapplication/controller.go:1162, internal/controller/sparkapplication/controller.go:279]
- **controller**: Reconciler —watches-reference→ /v1/Service; /v1/Service [source: internal/controller/sparkapplication/controller.go:1258, internal/controller/sparkconnect/reconciler.go:120]
- **controller**: Reconciler —watches-reference→ admissionregistration/v1/MutatingWebhookConfiguration; admissionregistration/v1/MutatingWebhookConfiguration [source: internal/controller/mutatingwebhookconfiguration/controller.go:68, internal/controller/mutatingwebhookconfiguration/controller.go:89]
- **controller**: Reconciler —watches-reference→ admissionregistration/v1/ValidatingWebhookConfiguration; admissionregistration/v1/ValidatingWebhookConfiguration [source: internal/controller/validatingwebhookconfiguration/controller.go:68, internal/controller/validatingwebhookconfiguration/controller.go:90]
- **controller**: Reconciler —watches-reference→ api/v1alpha1/SparkConnect; api/v1alpha1/SparkConnect [source: internal/controller/sparkconnect/reconciler.go:111, internal/controller/sparkconnect/reconciler.go:198]
- **controller**: Reconciler —watches-reference→ api/v1beta2/ScheduledSparkApplication; api/v1beta2/ScheduledSparkApplication [source: internal/controller/scheduledsparkapplication/controller.go:250, internal/controller/scheduledsparkapplication/controller.go:260]
- **controller**: Reconciler —watches-reference→ api/v1beta2/SparkApplication; api/v1beta2/SparkApplication [source: internal/controller/scheduledsparkapplication/controller.go:291, internal/controller/sparkapplication/controller.go:284]
- **controller**: Reconciler —watches-reference→ policy/v1/PodDisruptionBudget; policy/v1/PodDisruptionBudget [source: internal/controller/sparkapplication/controller.go:293, internal/controller/sparkapplication/driver_pdb.go:106]
- **controller**: SparkOperatorModuleReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/sparkapplication/monitoring_config.go:50, spark-operator-module/pkg/sparkoperatormodule/setup.go:22]
- **controller**: SparkOperatorModuleReconciler —watches-reference→ /v1/Service; /v1/Service [source: internal/controller/sparkapplication/controller.go:1258, spark-operator-module/pkg/sparkoperatormodule/setup.go:23]
- **controller**: SparkOperatorModuleReconciler —watches-reference→ admissionregistration/v1/MutatingWebhookConfiguration; admissionregistration/v1/MutatingWebhookConfiguration [source: internal/controller/mutatingwebhookconfiguration/controller.go:89, spark-operator-module/pkg/sparkoperatormodule/setup.go:31]
- **controller**: SparkOperatorModuleReconciler —watches-reference→ admissionregistration/v1/ValidatingWebhookConfiguration; admissionregistration/v1/ValidatingWebhookConfiguration [source: internal/controller/validatingwebhookconfiguration/controller.go:90, spark-operator-module/pkg/sparkoperatormodule/setup.go:32]
- **controller**: SparkOperatorModuleReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: spark-operator-module/pkg/sparkoperatormodule/resource_manager.go:107, spark-operator-module/pkg/sparkoperatormodule/setup.go:25]
- **webhook**: mutate-pod.sparkoperator.k8s.io —served-by→ spark-operator-webhook-svc; admission webhook declares an explicit service reference [source: config/webhook/mutatingwebhookconfiguration.yaml:7, config/webhook/service.yaml:3]
- **webhook**: mutate-scheduledsparkapplication.sparkoperator.k8s.io —served-by→ spark-operator-webhook-svc; admission webhook declares an explicit service reference [source: config/webhook/mutatingwebhookconfiguration.yaml:7, config/webhook/service.yaml:3]
- **webhook**: mutate-sparkapplication.sparkoperator.k8s.io —served-by→ spark-operator-webhook-svc; admission webhook declares an explicit service reference [source: config/webhook/mutatingwebhookconfiguration.yaml:7, config/webhook/service.yaml:3]
- **webhook**: validate-scheduledsparkapplication.sparkoperator.k8s.io —served-by→ spark-operator-webhook-svc; admission webhook declares an explicit service reference [source: config/webhook/service.yaml:3, config/webhook/validatingwebhookconfiguration.yaml:8]
- **webhook**: validate-sparkapplication.sparkoperator.k8s.io —served-by→ spark-operator-webhook-svc; admission webhook declares an explicit service reference [source: config/webhook/service.yaml:3, config/webhook/validatingwebhookconfiguration.yaml:8]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/operator/controller/start.go`:429 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/webhook/role.yaml`:1 (Named Secret access (spark-operator-webhook-certs), RBAC with resourceNames restriction)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `config/webhook/webhook-validating-selector-patch.yaml`:9 (Kubernetes admission, Operator webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/rbac/clusterrolebinding.yaml`:1 (spark-operator-controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/leader-election-role.yaml`:1 (spark-operator-controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/role.yaml`:2 (spark-operator-controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/scheduledsparkapplication_editor_role.yaml`:3 (spark-operator-scheduledsparkapplication-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/scheduledsparkapplication_viewer_role.yaml`:3 (spark-operator-scheduledsparkapplication-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/sparkapplication_editor_role.yaml`:3 (spark-operator-sparkapplication-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/rbac/sparkapplication_viewer_role.yaml`:3 (spark-operator-sparkapplication-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/webhook/clusterrole.yaml`:1 (spark-operator-webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `config/webhook/clusterrolebinding.yaml`:1 (spark-operator-webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/webhook/role.yaml`:1 (spark-operator-webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `spark-operator-module/config/rbac/leader_election_role.yaml`:1 (spark-operator-module-leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `spark-operator-module/config/rbac/role.yaml`:2 (spark-operator-module-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:60 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:95 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/operator/main.go`:44 (operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile.kubectl`:39 (docker/Dockerfile.kubectl:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/openshift/Dockerfile.odh`:127 (examples/openshift/Dockerfile.odh:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `spark-docker/Dockerfile`:44 (spark-docker/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `spark-operator-module/cmd/spark-operator-module/main.go`:33 (spark-operator-module)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `cmd/operator/controller/start.go`:352 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `spark-operator-module/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/operator/controller/start.go`:429 (/healthz, GET, cmd/operator/controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/operator/webhook/start.go`:336 (/healthz, GET, cmd/operator/webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `spark-operator-module/cmd/spark-operator-module/main.go`:89 (/healthz, GET, cmd/spark-operator-module)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `spark-operator-module/config/rbac/role.yaml`:2 (Certificate CR, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `cmd/operator/webhook/start.go`:403 (APIServer resource read, OpenShift Cluster Configuration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/mutatingwebhookconfiguration/controller.go`:89 (admissionregistration/v1/MutatingWebhookConfiguration, get operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/sparkapplication/controller.go`:1162 (/v1/Pod, create, delete, get, list, update operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/sparkapplication/monitoring_config.go`:50 (/v1/ConfigMap, create, get, update operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/sparkconnect/reconciler.go`:198 (api/v1alpha1/SparkConnect, get, update operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/validatingwebhookconfiguration/controller.go`:90 (admissionregistration/v1/ValidatingWebhookConfiguration, get operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/webhook/sparkapplication_validator.go`:189 (/v1/ResourceQuota, list operations by SparkApplicationValidator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/certificate/certificate.go`:94 (/v1/Secret, create, get, update operations by Provider)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/util/namespace.go`:120 (/v1/Namespace, get operations by NamespaceMatcher)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `spark-operator-module/config/rbac/role.yaml`:2 (CRD CRUD, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `spark-operator-module/go.mod` (Go Library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `spark-operator-module/pkg/apis/v1alpha1/types.go`:7 (Go library, odh-platform-utilities)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/mutatingwebhookconfiguration/controller.go`:89 (admissionregistration/v1/MutatingWebhookConfiguration, get operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/mutatingwebhookconfiguration/controller.go`:68 (Reconciler, admissionregistration/v1/MutatingWebhookConfiguration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/scheduledsparkapplication/controller.go`:250 (Reconciler, api/v1beta2/ScheduledSparkApplication)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/sparkapplication/controller.go`:1162 (/v1/Pod, create, delete, get, list, update operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/sparkapplication/controller.go`:279 (/v1/Pod, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/controller/sparkapplication/monitoring_config.go`:50 (/v1/ConfigMap, create, get, update operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/sparkconnect/reconciler.go`:112 (/v1/ConfigMap, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/validatingwebhookconfiguration/controller.go`:68 (Reconciler, admissionregistration/v1/ValidatingWebhookConfiguration)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `internal/webhook/sparkapplication_validator.go`:189 (/v1/ResourceQuota, list operations by SparkApplicationValidator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/certificate/certificate.go`:94 (/v1/Secret, create, get, update operations by Provider)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/util/namespace.go`:120 (/v1/Namespace, get operations by NamespaceMatcher)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `spark-operator-module/pkg/sparkoperatormodule/setup.go`:22 (/v1/ConfigMap, SparkOperatorModuleReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/manager/manager.yaml`:10 (spark-operator-controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `config/webhook/deployment.yaml`:1 (spark-operator-webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `config/webhook/service.yaml`:3 (spark-operator-webhook, spark-operator-webhook-svc)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_scheduledsparkapplications.yaml`:3 (/convert, scheduledsparkapplications.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_sparkapplications.yaml`:3 (/convert, scheduledsparkapplications.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/crd/patches/webhook_in_sparkconnects.yaml`:3 (/convert, scheduledsparkapplications.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/webhook-objectselector-patch.yaml`:1 (/mutate--v1-pod, mutate-pod.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/webhook-validating-selector-patch.yaml`:9 (/validate-sparkoperator-k8s-io-v1beta2-scheduledsparkapplication, validate-scheduledsparkapplication.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/scheduledsparkapplication_defaulter.go`:28 (/mutate-sparkoperator-k8s-io-v1beta2-scheduledsparkapplication, mutate-scheduledsparkapplication.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/scheduledsparkapplication_validator.go`:34 (/validate-sparkoperator-k8s-io-v1beta2-scheduledsparkapplication, validate-scheduledsparkapplication.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/sparkapplication_defaulter.go`:30 (/mutate-sparkoperator-k8s-io-v1beta2-sparkapplication, mutate-sparkapplication.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/sparkapplication_validator.go`:37 (/validate-sparkoperator-k8s-io-v1beta2-sparkapplication, validate-sparkapplication.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/sparkconnect_defaulter.go`:29 (/mutate-sparkoperator-k8s-io-v1alpha1-sparkconnect, mutate-sparkconnect.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/sparkconnect_validator.go`:35 (/validate-sparkoperator-k8s-io-v1alpha1-sparkconnect, validate-sparkconnect.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/sparkpod_defaulter.go`:43 (/mutate--v1-pod, mutate-pod.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/operator/controller/start.go:429]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/operator/controller/start.go:434]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via spark-operator-controller ClusterRole; SA spark-operator-controller [source: cmd/operator/controller/start.go:352]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via spark-operator-webhook ClusterRole; SA spark-operator-webhook [source: cmd/operator/controller/start.go:352]
- Named Secret access (spark-operator-webhook-certs) methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=spark-operator-webhook restricts secret access to spark-operator-webhook-certs only [source: config/webhook/role.yaml:1]
- Named Secret access (spark-operator-webhook-certs) methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=spark-operator-webhook restricts secret access to spark-operator-webhook-certs only [source: config/webhook/role.yaml:1]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: config/webhook/webhook-validating-selector-patch.yaml:9]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/operator/controller [source: cmd/operator/controller/start.go:429]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/operator/webhook [source: cmd/operator/webhook/start.go:336]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/spark-operator-module [source: spark-operator-module/cmd/spark-operator-module/main.go:89]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/operator/controller [source: cmd/operator/controller/start.go:434]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/operator/webhook [source: cmd/operator/webhook/start.go:341]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/spark-operator-module [source: spark-operator-module/cmd/spark-operator-module/main.go:93]
### integrations

- cert-manager interaction=Certificate CR role=unknown protocol=HTTPS purpose=Manage TLS certificates through cert-manager CRDs [source: spark-operator-module/config/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: spark-operator-module/config/rbac/role.yaml:2]
### internal_dependencies

- OpenShift Cluster Configuration interaction=APIServer resource read role=runtime-integration purpose=Read cluster-wide API server configuration [source: cmd/operator/webhook/start.go:403]
- cert-manager interaction=CRD CRUD role=unknown purpose=Manage TLS certificates through cert-manager CRDs [source: spark-operator-module/config/rbac/role.yaml:2]
- odh-platform-utilities interaction=Go Library role=runtime-library purpose=Platform detection, manifest rendering, and deployment helpers [source: spark-operator-module/go.mod]
- odh-platform-utilities interaction=Go library role=runtime-library purpose=Use runtime packages from github.com/opendatahub-io/odh-platform-utilities [source: spark-operator-module/pkg/apis/v1alpha1/types.go:7]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: spark-operator-module/config/rbac/role.yaml:2]
### services

- spark-operator-webhook-svc port=443 target=webhook protocol=TCP encryption= auth= [source: config/webhook/service.yaml:3]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload spark-operator-controller uses service account spark-operator-controller and 1 container(s) [source: config/manager/manager.yaml:10]
- **observed**: Deployment workload spark-operator-webhook uses service account spark-operator-webhook and 1 container(s) [source: config/webhook/deployment.yaml:1]
- **observed**: Service spark-operator-webhook-svc targets spark-operator-webhook with 1 port(s) [source: config/webhook/service.yaml:3]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd/operator/controller [source: cmd/operator/controller/start.go:429]
- **observed**: HTTP GET /healthz is owned by cmd/operator/webhook [source: cmd/operator/webhook/start.go:336]
- **observed**: HTTP GET /healthz is owned by cmd/spark-operator-module [source: spark-operator-module/cmd/spark-operator-module/main.go:89]
- **observed**: HTTP GET /readyz is owned by cmd/operator/controller [source: cmd/operator/controller/start.go:434]
- **observed**: HTTP GET /readyz is owned by cmd/operator/webhook [source: cmd/operator/webhook/start.go:341]
- **observed**: HTTP GET /readyz is owned by cmd/spark-operator-module [source: spark-operator-module/cmd/spark-operator-module/main.go:93]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: config/webhook/webhook-validating-selector-patch.yaml:9]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/operator/controller/start.go:429]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/operator/controller/start.go:434]
- **observed**: Kubernetes API Named Secret access (spark-operator-webhook-certs) uses RBAC with resourceNames restriction at kube-apiserver; policy=spark-operator-webhook restricts secret access to spark-operator-webhook-certs only [source: config/webhook/role.yaml:1]
- **observed**: RBAC role spark-operator-controller grants 12 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role spark-operator-controller grants 3 rule(s) [source: config/rbac/leader-election-role.yaml:1]
- **observed**: RBAC role spark-operator-module-leader-election-role grants 2 rule(s) [source: spark-operator-module/config/rbac/leader_election_role.yaml:1]
- **observed**: RBAC role spark-operator-module-manager-role grants 18 rule(s) [source: spark-operator-module/config/rbac/role.yaml:2]
- **observed**: RBAC role spark-operator-scheduledsparkapplication-editor-role grants 2 rule(s) [source: config/rbac/scheduledsparkapplication_editor_role.yaml:3]
- **observed**: RBAC role spark-operator-scheduledsparkapplication-viewer-role grants 2 rule(s) [source: config/rbac/scheduledsparkapplication_viewer_role.yaml:3]
- **observed**: RBAC role spark-operator-sparkapplication-editor-role grants 2 rule(s) [source: config/rbac/sparkapplication_editor_role.yaml:3]
- **observed**: RBAC role spark-operator-sparkapplication-viewer-role grants 2 rule(s) [source: config/rbac/sparkapplication_viewer_role.yaml:3]
- **observed**: RBAC role spark-operator-webhook grants 5 rule(s) [source: config/webhook/clusterrole.yaml:1]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via spark-operator-controller ClusterRole; SA spark-operator-controller [source: cmd/operator/controller/start.go:352]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via spark-operator-webhook ClusterRole; SA spark-operator-webhook [source: cmd/operator/controller/start.go:352]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/operator/webhook/start.go, internal/controller/sparkapplication/rest_submission.go, pkg/certificate/certificate.go, pkg/tls/tls.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

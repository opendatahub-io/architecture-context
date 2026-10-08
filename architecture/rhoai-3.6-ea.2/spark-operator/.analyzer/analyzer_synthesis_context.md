# Analyzer Synthesis Context: spark-operator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 4 crds facts extracted [source: config/crd/patches/webhook_in_scheduledsparkapplications.yaml:2, config/crd/patches/webhook_in_sparkapplications.yaml:2, config/crd/patches/webhook_in_sparkconnects.yaml:2, spark-operator-module/pkg/apis/v1alpha1/types.go:26]
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 6 http_endpoints facts extracted [source: cmd/operator/controller/start.go:459, cmd/operator/controller/start.go:464, cmd/operator/webhook/start.go:335, cmd/operator/webhook/start.go:340, spark-operator-module/cmd/spark-operator-module/main.go:89, spark-operator-module/cmd/spark-operator-module/main.go:93]
- **services (observed)**: 1 services facts extracted [source: config/webhook/service.yaml:3]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 15 webhooks facts extracted [source: config/crd/patches/webhook_in_scheduledsparkapplications.yaml:3, config/crd/patches/webhook_in_sparkapplications.yaml:3, config/crd/patches/webhook_in_sparkconnects.yaml:3, config/webhook/webhook-objectselector-patch.yaml:1, config/webhook/webhook-validating-selector-patch.yaml:9, internal/webhook/scheduledsparkapplication_defaulter.go:28, internal/webhook/scheduledsparkapplication_validator.go:35, internal/webhook/sparkapplication_defaulter.go:30, internal/webhook/sparkapplication_validator.go:38, internal/webhook/sparkconnect_defaulter.go:29, internal/webhook/sparkconnect_validator.go:37, internal/webhook/sparkpod_defaulter.go:44]

## Deterministic Cross-References

- **controller**: Reconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/sparkapplication/monitoring_config.go:50, internal/controller/sparkconnect/reconciler.go:117]
- **controller**: Reconciler —watches-reference→ /v1/Pod; /v1/Pod [source: internal/controller/sparkapplication/controller.go:1187, internal/controller/sparkapplication/controller.go:289]
- **controller**: Reconciler —watches-reference→ /v1/Service; /v1/Service [source: internal/controller/sparkapplication/controller.go:1283, internal/controller/sparkconnect/reconciler.go:125]
- **controller**: Reconciler —watches-reference→ admissionregistration/v1/MutatingWebhookConfiguration; admissionregistration/v1/MutatingWebhookConfiguration [source: internal/controller/mutatingwebhookconfiguration/controller.go:68, internal/controller/mutatingwebhookconfiguration/controller.go:89]
- **controller**: Reconciler —watches-reference→ admissionregistration/v1/ValidatingWebhookConfiguration; admissionregistration/v1/ValidatingWebhookConfiguration [source: internal/controller/validatingwebhookconfiguration/controller.go:68, internal/controller/validatingwebhookconfiguration/controller.go:90]
- **controller**: Reconciler —watches-reference→ api/v1alpha1/SparkConnect; api/v1alpha1/SparkConnect [source: internal/controller/sparkconnect/reconciler.go:116, internal/controller/sparkconnect/reconciler.go:203]
- **controller**: Reconciler —watches-reference→ api/v1beta2/ScheduledSparkApplication; api/v1beta2/ScheduledSparkApplication [source: internal/controller/scheduledsparkapplication/controller.go:250, internal/controller/scheduledsparkapplication/controller.go:260]
- **controller**: Reconciler —watches-reference→ api/v1beta2/SparkApplication; api/v1beta2/SparkApplication [source: internal/controller/scheduledsparkapplication/controller.go:291, internal/controller/sparkapplication/controller.go:294]
- **controller**: Reconciler —watches-reference→ policy/v1/PodDisruptionBudget; policy/v1/PodDisruptionBudget [source: internal/controller/sparkapplication/controller.go:303, internal/controller/sparkapplication/driver_pdb.go:106]
- **controller**: SparkOperatorModuleReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: internal/controller/sparkapplication/monitoring_config.go:50, spark-operator-module/pkg/sparkoperatormodule/setup.go:22]
- **controller**: SparkOperatorModuleReconciler —watches-reference→ /v1/Service; /v1/Service [source: internal/controller/sparkapplication/controller.go:1283, spark-operator-module/pkg/sparkoperatormodule/setup.go:23]
- **controller**: SparkOperatorModuleReconciler —watches-reference→ admissionregistration/v1/MutatingWebhookConfiguration; admissionregistration/v1/MutatingWebhookConfiguration [source: internal/controller/mutatingwebhookconfiguration/controller.go:89, spark-operator-module/pkg/sparkoperatormodule/setup.go:31]
- **controller**: SparkOperatorModuleReconciler —watches-reference→ admissionregistration/v1/ValidatingWebhookConfiguration; admissionregistration/v1/ValidatingWebhookConfiguration [source: internal/controller/validatingwebhookconfiguration/controller.go:90, spark-operator-module/pkg/sparkoperatormodule/setup.go:32]
- **controller**: SparkOperatorModuleReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: spark-operator-module/pkg/sparkoperatormodule/resource_manager.go:107, spark-operator-module/pkg/sparkoperatormodule/setup.go:25]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: cmd/operator/controller/start.go:349-353]
- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: cmd/operator/webhook/start.go:202-206]
- **named-watch-predicate (unresolved)** internal/controller/mutatingwebhookconfiguration.Reconciler: admissionregistration/v1/MutatingWebhookConfiguration; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/mutatingwebhookconfiguration/controller.go:68-74]
- **named-watch-predicate (unresolved)** internal/controller/scheduledsparkapplication.Reconciler: sparkoperator.k8s.io/v1beta2/ScheduledSparkApplication; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/scheduledsparkapplication/controller.go:250-253]
- **named-watch-predicate (unresolved)** internal/controller/sparkapplication.Reconciler: /v1/Pod; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/sparkapplication/controller.go:289-293]
- **named-watch-predicate (unresolved)** internal/controller/sparkapplication.Reconciler: sparkoperator.k8s.io/v1beta2/SparkApplication; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/sparkapplication/controller.go:294-298]
- **named-watch-predicate (unresolved)** internal/controller/sparkconnect.Reconciler: /v1/Pod; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/sparkconnect/reconciler.go:133-186]
- **named-watch-predicate (unresolved)** internal/controller/validatingwebhookconfiguration.Reconciler: admissionregistration/v1/ValidatingWebhookConfiguration; literal names=; limitations=Watch predicates use a dynamic value or unsupported wrapper; named-resource filtering is unresolved [source: internal/controller/validatingwebhookconfiguration/controller.go:68-74]

## Gap Evidence Index

### authentication

- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `cmd/operator/controller/start.go`:349-353 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/operator/controller/start.go`:382 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/operator/controller/start.go`:459 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `cmd/operator/controller/start.go`:464 (:8081/readyz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `cmd/operator/webhook/start.go`:202-206 (controller-runtime metrics, controller-runtime metrics serving surface)
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
  **Candidate:** `config/rbac/tls-clusterrole.yaml`:1 (spark-operator-tls-profile)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `config/webhook/clusterrole.yaml`:1 (spark-operator-webhook)
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
  **Candidate:** `Dockerfile`:78 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:95 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.module-controller`:46 (Dockerfile.konflux.module-controller:ENTRYPOINT)
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
  **Candidate:** `cmd/operator/controller/start.go`:382 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `spark-operator-module/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/operator/controller/start.go`:459 (/healthz, GET, cmd/operator/controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/operator/controller/start.go`:464 (/readyz, GET, cmd/operator/controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/operator/webhook/start.go`:335 (/healthz, GET, cmd/operator/webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `cmd/operator/webhook/start.go`:340 (/readyz, GET, cmd/operator/webhook)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `spark-operator-module/cmd/spark-operator-module/main.go`:89 (/healthz, GET, cmd/spark-operator-module)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `spark-operator-module/cmd/spark-operator-module/main.go`:93 (/readyz, GET, cmd/spark-operator-module)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `spark-operator-module/config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `spark-operator-module/config/rbac/role.yaml`:2 (Certificate CR, cert-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/mutatingwebhookconfiguration/controller.go`:89 (admissionregistration/v1/MutatingWebhookConfiguration, get operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/sparkapplication/controller.go`:1187 (/v1/Pod, create, delete, get, list, update operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/sparkapplication/controller.go`:1283 (/v1/Service, create, delete, get, update operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/sparkapplication/monitoring_config.go`:50 (/v1/ConfigMap, create, get, update operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/controller/validatingwebhookconfiguration/controller.go`:90 (admissionregistration/v1/ValidatingWebhookConfiguration, get operations by Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `internal/webhook/sparkapplication_validator.go`:194 (/v1/ResourceQuota, list operations by SparkApplicationValidator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/certificate/certificate.go`:93 (/v1/Secret, create, get, update operations by Provider)
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
  **Candidate:** `spark-operator-module/config/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
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

- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/mutatingwebhookconfiguration/controller.go`:68-74 (admissionregistration/v1/MutatingWebhookConfiguration, internal/controller/mutatingwebhookconfiguration.Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/scheduledsparkapplication/controller.go`:250-253 (internal/controller/scheduledsparkapplication.Reconciler, sparkoperator.k8s.io/v1beta2/ScheduledSparkApplication)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/sparkapplication/controller.go`:289-293 (/v1/Pod, internal/controller/sparkapplication.Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/sparkapplication/controller.go`:294-298 (internal/controller/sparkapplication.Reconciler, sparkoperator.k8s.io/v1beta2/SparkApplication)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/sparkconnect/reconciler.go`:117 (/v1/ConfigMap, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `internal/controller/sparkconnect/reconciler.go`:125 (/v1/Service, Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/sparkconnect/reconciler.go`:133-186 (/v1/Pod, internal/controller/sparkconnect.Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which literal resource names constrain this controller watch, and where are matching events routed?
  **Expected signal:** a supported literal named-resource predicate and any explicit event-handler target
  **Candidate:** `internal/controller/validatingwebhookconfiguration/controller.go`:68-74 (admissionregistration/v1/ValidatingWebhookConfiguration, internal/controller/validatingwebhookconfiguration.Reconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `spark-operator-module/pkg/sparkoperatormodule/setup.go`:22 (/v1/ConfigMap, SparkOperatorModuleReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `spark-operator-module/pkg/sparkoperatormodule/setup.go`:23 (/v1/Service, SparkOperatorModuleReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `spark-operator-module/pkg/sparkoperatormodule/setup.go`:24 (/v1/ServiceAccount, SparkOperatorModuleReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `spark-operator-module/pkg/sparkoperatormodule/setup.go`:31 (SparkOperatorModuleReconciler, admissionregistration/v1/MutatingWebhookConfiguration)
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
  **Candidate:** `config/webhook/webhook-objectselector-patch.yaml`:1 (/mutate--v1-pod, mutate-pod.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/webhook-objectselector-patch.yaml`:1 (/mutate-sparkoperator-k8s-io-v1alpha1-sparkconnect, mutate-sparkconnect.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/webhook-objectselector-patch.yaml`:1 (/mutate-sparkoperator-k8s-io-v1beta2-scheduledsparkapplication, mutate-scheduledsparkapplication.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/webhook-objectselector-patch.yaml`:1 (/mutate-sparkoperator-k8s-io-v1beta2-sparkapplication, mutate-sparkapplication.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/webhook-validating-selector-patch.yaml`:9 (/validate-sparkoperator-k8s-io-v1beta2-scheduledsparkapplication, validate-scheduledsparkapplication.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `config/webhook/webhook-validating-selector-patch.yaml`:9 (/validate-sparkoperator-k8s-io-v1beta2-sparkapplication, validate-sparkapplication.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/scheduledsparkapplication_defaulter.go`:28 (/mutate-sparkoperator-k8s-io-v1beta2-scheduledsparkapplication, mutate-scheduledsparkapplication.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/scheduledsparkapplication_validator.go`:35 (/validate-sparkoperator-k8s-io-v1beta2-scheduledsparkapplication, validate-scheduledsparkapplication.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/sparkapplication_defaulter.go`:30 (/mutate-sparkoperator-k8s-io-v1beta2-sparkapplication, mutate-sparkapplication.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/sparkapplication_validator.go`:38 (/validate-sparkoperator-k8s-io-v1beta2-sparkapplication, validate-sparkapplication.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/sparkconnect_defaulter.go`:29 (/mutate-sparkoperator-k8s-io-v1alpha1-sparkconnect, mutate-sparkconnect.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `internal/webhook/sparkpod_defaulter.go`:44 (/mutate--v1-pod, mutate-pod.sparkoperator.k8s.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: cmd/operator/controller/start.go:459]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/operator/controller/start.go:464]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via spark-operator-controller ClusterRole; SA spark-operator-controller [source: cmd/operator/controller/start.go:382]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via spark-operator-tls-profile ClusterRole; SA spark-operator-webhook [source: cmd/operator/controller/start.go:382]
- Named Secret access (spark-operator-webhook-certs) methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=spark-operator-webhook restricts secret access to spark-operator-webhook-certs only [source: config/webhook/role.yaml:1]
- Named Secret access (spark-operator-webhook-certs) methods=Kubernetes API mechanism=RBAC with resourceNames restriction enforcement=kube-apiserver policy=spark-operator-webhook restricts secret access to spark-operator-webhook-certs only [source: config/webhook/role.yaml:1]
- Operator webhook methods=CREATE mechanism=Kubernetes admission enforcement=ValidatingWebhookConfiguration policy=Admission validation [source: config/webhook/webhook-validating-selector-patch.yaml:9]
### http_endpoints

- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/operator/controller [source: cmd/operator/controller/start.go:459]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/operator/webhook [source: cmd/operator/webhook/start.go:335]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/spark-operator-module [source: spark-operator-module/cmd/spark-operator-module/main.go:89]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/operator/controller [source: cmd/operator/controller/start.go:464]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/operator/webhook [source: cmd/operator/webhook/start.go:340]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd/spark-operator-module [source: spark-operator-module/cmd/spark-operator-module/main.go:93]
### integrations

- cert-manager interaction=Certificate CR role=unknown protocol=HTTPS purpose=Manage TLS certificates through cert-manager CRDs [source: spark-operator-module/config/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: spark-operator-module/config/rbac/role.yaml:2]
### internal_dependencies

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

- **observed**: HTTP GET /healthz is owned by cmd/operator/controller [source: cmd/operator/controller/start.go:459]
- **observed**: HTTP GET /healthz is owned by cmd/operator/webhook [source: cmd/operator/webhook/start.go:335]
- **observed**: HTTP GET /healthz is owned by cmd/spark-operator-module [source: spark-operator-module/cmd/spark-operator-module/main.go:89]
- **observed**: HTTP GET /readyz is owned by cmd/operator/controller [source: cmd/operator/controller/start.go:464]
- **observed**: HTTP GET /readyz is owned by cmd/operator/webhook [source: cmd/operator/webhook/start.go:340]
- **observed**: HTTP GET /readyz is owned by cmd/spark-operator-module [source: spark-operator-module/cmd/spark-operator-module/main.go:93]
### security

- **observed**: CREATE Operator webhook uses Kubernetes admission at ValidatingWebhookConfiguration; policy=Admission validation [source: config/webhook/webhook-validating-selector-patch.yaml:9]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: cmd/operator/controller/start.go:459]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: cmd/operator/controller/start.go:464]
- **observed**: Kubernetes API Named Secret access (spark-operator-webhook-certs) uses RBAC with resourceNames restriction at kube-apiserver; policy=spark-operator-webhook restricts secret access to spark-operator-webhook-certs only [source: config/webhook/role.yaml:1]
- **observed**: RBAC role spark-operator-controller grants 10 rule(s) [source: config/rbac/role.yaml:2]
- **observed**: RBAC role spark-operator-controller grants 3 rule(s) [source: config/rbac/leader-election-role.yaml:1]
- **observed**: RBAC role spark-operator-module-leader-election-role grants 2 rule(s) [source: spark-operator-module/config/rbac/leader_election_role.yaml:1]
- **observed**: RBAC role spark-operator-module-manager-role grants 18 rule(s) [source: spark-operator-module/config/rbac/role.yaml:2]
- **observed**: RBAC role spark-operator-scheduledsparkapplication-editor-role grants 2 rule(s) [source: config/rbac/scheduledsparkapplication_editor_role.yaml:3]
- **observed**: RBAC role spark-operator-scheduledsparkapplication-viewer-role grants 2 rule(s) [source: config/rbac/scheduledsparkapplication_viewer_role.yaml:3]
- **observed**: RBAC role spark-operator-sparkapplication-editor-role grants 2 rule(s) [source: config/rbac/sparkapplication_editor_role.yaml:3]
- **observed**: RBAC role spark-operator-sparkapplication-viewer-role grants 2 rule(s) [source: config/rbac/sparkapplication_viewer_role.yaml:3]
- **observed**: RBAC role spark-operator-tls-profile grants 2 rule(s) [source: config/rbac/tls-clusterrole.yaml:1]
- **observed**: RBAC role spark-operator-webhook grants 5 rule(s) [source: config/webhook/clusterrole.yaml:1]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via spark-operator-controller ClusterRole; SA spark-operator-controller [source: cmd/operator/controller/start.go:382]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via spark-operator-tls-profile ClusterRole; SA spark-operator-webhook [source: cmd/operator/controller/start.go:382]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: cmd/operator/controller/start.go, cmd/operator/webhook/start.go, internal/controller/sparkapplication/rest_submission.go, pkg/tls/profile.go, pkg/tls/tls.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

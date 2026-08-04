# Analyzer Synthesis Context: feast

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 2 crds facts extracted [source: infra/feast-operator/api/v1alpha1/featurestore_types.go:706, infra/feast-operator/config/crd/bases/feast.dev_featurestores.yaml:2]
- **grpc_services (observed)**: 70 grpc_services facts extracted [source: go/main.go:194, go/main.go:196, protos/feast/registry/RegistryServer.proto:100, protos/feast/registry/RegistryServer.proto:103, protos/feast/registry/RegistryServer.proto:104, protos/feast/registry/RegistryServer.proto:107, protos/feast/registry/RegistryServer.proto:108, protos/feast/registry/RegistryServer.proto:25, protos/feast/registry/RegistryServer.proto:26, protos/feast/registry/RegistryServer.proto:27, protos/feast/registry/RegistryServer.proto:28, protos/feast/registry/RegistryServer.proto:31, protos/feast/registry/RegistryServer.proto:32, protos/feast/registry/RegistryServer.proto:33, protos/feast/registry/RegistryServer.proto:34, protos/feast/registry/RegistryServer.proto:37, protos/feast/registry/RegistryServer.proto:38, protos/feast/registry/RegistryServer.proto:39, protos/feast/registry/RegistryServer.proto:40, protos/feast/registry/RegistryServer.proto:43, protos/feast/registry/RegistryServer.proto:44, protos/feast/registry/RegistryServer.proto:47, protos/feast/registry/RegistryServer.proto:48, protos/feast/registry/RegistryServer.proto:51, protos/feast/registry/RegistryServer.proto:52, protos/feast/registry/RegistryServer.proto:55, protos/feast/registry/RegistryServer.proto:56, protos/feast/registry/RegistryServer.proto:59, protos/feast/registry/RegistryServer.proto:60, protos/feast/registry/RegistryServer.proto:61, protos/feast/registry/RegistryServer.proto:62, protos/feast/registry/RegistryServer.proto:65, protos/feast/registry/RegistryServer.proto:66, protos/feast/registry/RegistryServer.proto:67, protos/feast/registry/RegistryServer.proto:68, protos/feast/registry/RegistryServer.proto:71, protos/feast/registry/RegistryServer.proto:72, protos/feast/registry/RegistryServer.proto:73, protos/feast/registry/RegistryServer.proto:74, protos/feast/registry/RegistryServer.proto:77, protos/feast/registry/RegistryServer.proto:78, protos/feast/registry/RegistryServer.proto:79, protos/feast/registry/RegistryServer.proto:80, protos/feast/registry/RegistryServer.proto:83, protos/feast/registry/RegistryServer.proto:84, protos/feast/registry/RegistryServer.proto:85, protos/feast/registry/RegistryServer.proto:86, protos/feast/registry/RegistryServer.proto:89, protos/feast/registry/RegistryServer.proto:90, protos/feast/registry/RegistryServer.proto:91, protos/feast/registry/RegistryServer.proto:92, protos/feast/registry/RegistryServer.proto:93, protos/feast/registry/RegistryServer.proto:95, protos/feast/registry/RegistryServer.proto:96, protos/feast/registry/RegistryServer.proto:97, protos/feast/registry/RegistryServer.proto:98, protos/feast/registry/RegistryServer.proto:99, protos/feast/serving/Connector.proto:22, protos/feast/serving/GrpcServer.proto:33, protos/feast/serving/GrpcServer.proto:35, protos/feast/serving/GrpcServer.proto:36, protos/feast/serving/ServingService.proto:30, protos/feast/serving/ServingService.proto:32, protos/feast/serving/TransformationService.proto:25, protos/feast/serving/TransformationService.proto:27, protos/feast/third_party/grpc/health/v1/HealthService.proto:22, sdk/python/feast/infra/contrib/grpc_server.py:177, sdk/python/feast/registry_server.py:1742, sdk/python/feast/registry_server.py:1747, sdk/python/feast/transformation_server.py:70]
- **http_endpoints (observed)**: 107 http_endpoints facts extracted [source: go/internal/feast/server/http_server.go:388, go/internal/feast/server/http_server.go:389, go/internal/feast/server/http_server.go:402, go/internal/feast/server/http_server.go:403, go/main.go:204, go/main.go:264, infra/feast-operator/cmd/main.go:341, infra/feast-operator/cmd/main.go:345, sdk/python/feast/api/registry/rest/compute_engines.py:127, sdk/python/feast/api/registry/rest/compute_engines.py:170, sdk/python/feast/api/registry/rest/compute_engines.py:222, sdk/python/feast/api/registry/rest/data_sources.py:117, sdk/python/feast/api/registry/rest/data_sources.py:142, sdk/python/feast/api/registry/rest/data_sources.py:211, sdk/python/feast/api/registry/rest/data_sources.py:262, sdk/python/feast/api/registry/rest/data_sources.py:83, sdk/python/feast/api/registry/rest/entities.py:154, sdk/python/feast/api/registry/rest/entities.py:180, sdk/python/feast/api/registry/rest/entities.py:39, sdk/python/feast/api/registry/rest/entities.py:71, sdk/python/feast/api/registry/rest/entities.py:96, sdk/python/feast/api/registry/rest/feature_services.py:23, sdk/python/feast/api/registry/rest/feature_services.py:61, sdk/python/feast/api/registry/rest/feature_services.py:86, sdk/python/feast/api/registry/rest/feature_views.py:142, sdk/python/feast/api/registry/rest/feature_views.py:256, sdk/python/feast/api/registry/rest/feature_views.py:334, sdk/python/feast/api/registry/rest/feature_views.py:386, sdk/python/feast/api/registry/rest/feature_views.py:86, sdk/python/feast/api/registry/rest/features.py:106, sdk/python/feast/api/registry/rest/features.py:136, sdk/python/feast/api/registry/rest/features.py:174, sdk/python/feast/api/registry/rest/features.py:22, sdk/python/feast/api/registry/rest/features.py:59, sdk/python/feast/api/registry/rest/label_views.py:112, sdk/python/feast/api/registry/rest/label_views.py:20, sdk/python/feast/api/registry/rest/label_views.py:57, sdk/python/feast/api/registry/rest/lineage.py:107, sdk/python/feast/api/registry/rest/lineage.py:196, sdk/python/feast/api/registry/rest/lineage.py:232, sdk/python/feast/api/registry/rest/lineage.py:24, sdk/python/feast/api/registry/rest/lineage.py:62, sdk/python/feast/api/registry/rest/metrics.py:268, sdk/python/feast/api/registry/rest/metrics.py:417, sdk/python/feast/api/registry/rest/metrics.py:64, sdk/python/feast/api/registry/rest/monitoring.py:147, sdk/python/feast/api/registry/rest/monitoring.py:175, sdk/python/feast/api/registry/rest/monitoring.py:209, sdk/python/feast/api/registry/rest/monitoring.py:229, sdk/python/feast/api/registry/rest/monitoring.py:241, sdk/python/feast/api/registry/rest/monitoring.py:269, sdk/python/feast/api/registry/rest/monitoring.py:299, sdk/python/feast/api/registry/rest/monitoring.py:327, sdk/python/feast/api/registry/rest/monitoring.py:353, sdk/python/feast/api/registry/rest/monitoring.py:375, sdk/python/feast/api/registry/rest/monitoring.py:90, sdk/python/feast/api/registry/rest/permissions.py:122, sdk/python/feast/api/registry/rest/permissions.py:148, sdk/python/feast/api/registry/rest/permissions.py:180, sdk/python/feast/api/registry/rest/permissions.py:215, sdk/python/feast/api/registry/rest/projects.py:15, sdk/python/feast/api/registry/rest/projects.py:28, sdk/python/feast/api/registry/rest/rest_utils.py:262, sdk/python/feast/api/registry/rest/saved_datasets.py:138, sdk/python/feast/api/registry/rest/saved_datasets.py:152, sdk/python/feast/api/registry/rest/saved_datasets.py:178, sdk/python/feast/api/registry/rest/saved_datasets.py:228, sdk/python/feast/api/registry/rest/saved_datasets.py:262, sdk/python/feast/api/registry/rest/saved_datasets.py:367, sdk/python/feast/api/registry/rest/saved_datasets.py:380, sdk/python/feast/api/registry/rest/saved_datasets.py:71, sdk/python/feast/api/registry/rest/saved_datasets.py:96, sdk/python/feast/api/registry/rest/search.py:33, sdk/python/feast/feature_server.py:412, sdk/python/feast/feature_server.py:459, sdk/python/feast/feature_server.py:498, sdk/python/feast/feature_server.py:606, sdk/python/feast/feature_server.py:621, sdk/python/feast/feature_server.py:629, sdk/python/feast/feature_server.py:635, sdk/python/feast/feature_server.py:644, sdk/python/feast/feature_server.py:685, sdk/python/feast/feature_server.py:749, sdk/python/feast/openlineage/consumer.py:133, sdk/python/feast/openlineage/consumer.py:171, sdk/python/feast/openlineage/consumer.py:196, sdk/python/feast/openlineage/consumer.py:214, sdk/python/feast/openlineage/consumer.py:221, sdk/python/feast/openlineage/consumer.py:228, sdk/python/feast/openlineage/consumer.py:260, sdk/python/feast/openlineage/consumer.py:313, sdk/python/feast/openlineage/consumer.py:329, sdk/python/feast/openlineage/consumer.py:89, sdk/python/feast/ui_server.py:1097, sdk/python/feast/ui_server.py:1175, sdk/python/feast/ui_server.py:1179, sdk/python/feast/ui_server.py:199, sdk/python/feast/ui_server.py:246, sdk/python/feast/ui_server.py:350, sdk/python/feast/ui_server.py:502, sdk/python/feast/ui_server.py:669, sdk/python/feast/ui_server.py:699, sdk/python/feast/ui_server.py:730, sdk/python/feast/ui_server.py:769, sdk/python/feast/ui_server.py:812, sdk/python/feast/ui_server.py:896, sdk/python/feast/ui_server.py:997]
- **services (observed)**: 2 services facts extracted [source: infra/feast-operator/config/default/metrics_service.yaml:1, sdk/python/feast/ui_server.py:1175]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **controller**: FeatureStoreReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: infra/feast-operator/internal/controller/featurestore_controller.go:198, infra/feast-operator/internal/controller/featurestore_controller.go:367]
- **controller**: FeatureStoreReconciler —watches-reference→ /v1/ServiceAccount; /v1/ServiceAccount [source: infra/feast-operator/internal/controller/featurestore_controller.go:371, infra/feast-operator/internal/controller/services/batch_engine_rbac.go:225]
- **controller**: FeatureStoreReconciler —watches-reference→ api/v1/FeatureStore; api/v1/FeatureStore [source: infra/feast-operator/internal/controller/featurestore_controller.go:366, infra/feast-operator/internal/controller/featurestore_controller.go:96]
- **controller**: FeatureStoreReconciler —watches-reference→ apps/v1/Deployment; apps/v1/Deployment [source: infra/feast-operator/internal/controller/featurestore_controller.go:368, infra/feast-operator/internal/controller/services/services.go:1151]
- **controller**: FeatureStoreReconciler —watches-reference→ autoscaling/v2/HorizontalPodAutoscaler; autoscaling/v2/HorizontalPodAutoscaler [source: infra/feast-operator/internal/controller/featurestore_controller.go:375, infra/feast-operator/internal/controller/services/scaling.go:82]
- **controller**: FeatureStoreReconciler —watches-reference→ policy/v1/PodDisruptionBudget; policy/v1/PodDisruptionBudget [source: infra/feast-operator/internal/controller/featurestore_controller.go:376, infra/feast-operator/internal/controller/services/scaling.go:205]
- **controller**: FeatureStoreReconciler —watches-reference→ rbac.authorization.k8s.io/v1/Role; rbac.authorization.k8s.io/v1/Role [source: infra/feast-operator/internal/controller/access/rbac.go:183, infra/feast-operator/internal/controller/featurestore_controller.go:373]
- **controller**: FeatureStoreReconciler —watches-reference→ rbac.authorization.k8s.io/v1/RoleBinding; rbac.authorization.k8s.io/v1/RoleBinding [source: infra/feast-operator/internal/controller/access/rbac.go:113, infra/feast-operator/internal/controller/featurestore_controller.go:372]
- **controller**: NotebookConfigMapReconciler —watches-reference→ /v1/ConfigMap; /v1/ConfigMap [source: infra/feast-operator/internal/controller/featurestore_controller.go:198, infra/feast-operator/internal/controller/notebook_configmap_controller.go:496]
- **controller**: NotebookConfigMapReconciler —watches-reference→ api/v1/FeatureStore; api/v1/FeatureStore [source: infra/feast-operator/internal/controller/featurestore_controller.go:96, infra/feast-operator/internal/controller/notebook_configmap_controller.go:503]

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `go/embedded/online_features.go`:322 (None, gRPC services (Go))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `go/internal/feast/server/http_server.go`:388 (/get-online-features (Go HTTP), None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `infra/feast-operator/api/v1alpha1/featurestore_types.go`:613 (Configurable: Kubernetes RBAC or OIDC, Feast services (CRD-configured))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this runtime security control wired to the serving surface?
  **Expected signal:** flag/default, certificate, middleware, or enforcement point
  **Candidate:** `infra/feast-operator/cmd/main.go`:207 (controller-runtime metrics, controller-runtime metrics authn/authz filter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `infra/feast-operator/cmd/main.go`:341 (:8081/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `infra/feast-operator/internal/controller/services/util.go`:391 (Kubernetes API, ServiceAccount token (in-cluster))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `sdk/python/feast/ui_server.py`:1175 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `infra/feast-operator/config/rbac/featurestore_editor_role.yaml`:2 (feast-operator-featurestore-editor-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `infra/feast-operator/config/rbac/featurestore_viewer_role.yaml`:2 (feast-operator-featurestore-viewer-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `infra/feast-operator/config/rbac/leader_election_role.yaml`:2 (feast-operator-leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `infra/feast-operator/config/rbac/leader_election_role_binding.yaml`:1 (feast-operator-leader-election-role, feast-operator-leader-election-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `infra/feast-operator/config/rbac/metrics_auth_role.yaml`:1 (feast-operator-metrics-auth-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `infra/feast-operator/config/rbac/metrics_auth_role_binding.yaml`:1 (feast-operator-metrics-auth-role, feast-operator-metrics-auth-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `infra/feast-operator/config/rbac/metrics_reader_role.yaml`:1 (feast-operator-metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `infra/feast-operator/config/rbac/role.yaml`:2 (feast-operator-manager-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `infra/feast-operator/config/rbac/role_binding.yaml`:1 (feast-operator-manager-role, feast-operator-manager-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfiles/Dockerfile.feast-operator.konflux`:30 (Dockerfiles/Dockerfile.feast-operator.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `go/infra/docker/feature-server/Dockerfile`:32 (go/infra/docker/feature-server/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `go/main.go`:68 (go)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `infra/feast-operator/Dockerfile`:31 (infra/feast-operator/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `infra/feast-operator/cmd/main.go`:107 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `java/infra/docker/feature-server/Dockerfile`:37 (java/infra/docker/feature-server/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `java/infra/docker/feature-server/Dockerfile.dev`:11 (java/infra/docker/feature-server/Dockerfile.dev:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `java/serving/src/test/resources/docker-compose/feast10/Dockerfile`:16 (java/serving/src/test/resources/docker-compose/feast10/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:2 (feast)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `sdk/python/feast/infra/compute_engines/aws_lambda/Dockerfile`:25 (sdk/python/feast/infra/compute_engines/aws_lambda/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `sdk/python/feast/infra/transformation_servers/Dockerfile`:21 (sdk/python/feast/infra/transformation_servers/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `ui/docker/Dockerfile`:22 (ui/docker/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `go/internal/feast/onlinestore/postgresonlinestore.go`:35 (PostgreSQL, pgx connection pool)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `go/internal/feast/onlinestore/redisonlinestore.go`:118 (Redis/Valkey, go-redis client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `go/internal/feast/registry/gcs.go`:47 (GCS storage client, Google Cloud Storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `go/internal/feast/registry/s3.go`:43 (AWS SDK S3 client, S3-compatible storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `infra/feast-operator/go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `infra/feast-operator/internal/controller/services/util.go`:391 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### grpc_services

- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `go/main.go`:196 (Health, go/embedded)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `protos/feast/registry/RegistryServer.proto`:31 (feast.registry.RegistryServer/ApplyDataSource)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `protos/feast/serving/Connector.proto`:22 (grpc.connector.OnlineStore/OnlineRead)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `protos/feast/serving/GrpcServer.proto`:36 (GrpcFeatureServer/GetOnlineFeatures)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `protos/feast/serving/ServingService.proto`:30 (feast.serving.ServingService/GetFeastServingInfo)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `protos/feast/serving/TransformationService.proto`:25 (feast.serving.TransformationService/GetTransformationServiceInfo)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `protos/feast/third_party/grpc/health/v1/HealthService.proto`:22 (grpc.health.v1.Health/Check)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `sdk/python/feast/infra/contrib/grpc_server.py`:177 (GrpcFeatureServer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `sdk/python/feast/registry_server.py`:1742 (RegistryServer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `sdk/python/feast/transformation_server.py`:70 (TransformationService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `go/internal/feast/server/http_server.go`:388 (/get-online-features, Unknown, go/internal/feast/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `go/main.go`:204 (/metrics, Unknown, go)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `infra/feast-operator/cmd/main.go`:341 (/healthz, GET, cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `sdk/python/feast/api/registry/rest/compute_engines.py`:170 (/compute_engines/all, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `sdk/python/feast/api/registry/rest/data_sources.py`:117 (/data_sources/all, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `sdk/python/feast/api/registry/rest/entities.py`:71 (/entities/all, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `sdk/python/feast/api/registry/rest/feature_services.py`:61 (/feature_services/all, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `sdk/python/feast/api/registry/rest/feature_views.py`:86 (/feature_views/all, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `sdk/python/feast/api/registry/rest/features.py`:106 (/features/all, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `sdk/python/feast/api/registry/rest/rest_utils.py`:262 (/items, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `sdk/python/feast/feature_server.py`:635 (/chat, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `sdk/python/feast/ui_server.py`:1175 (/, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `go/internal/feast/onlinestore/postgresonlinestore.go`:35 (Database client, PostgreSQL)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `go/internal/feast/onlinestore/redisonlinestore.go`:118 (Exchange client, Redis/Valkey)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `go/internal/feast/registry/gcs.go`:47 (File storage client, Google Cloud Storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `go/internal/feast/registry/s3.go`:43 (File storage client, S3-compatible storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `infra/feast-operator/config/rbac/role.yaml`:2 (CRD Watch, Feast FeatureStore CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `infra/scripts/cleanup_ci.py`:1 (AWS (S3-compatible storage), Python SDK client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `sdk/python/feast/infra/offline_stores/bigquery.py`:77 (Google Cloud Storage, Python SDK client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `infra/feast-operator/config/rbac/role.yaml`:2 (CRD Watch, Feast (feast.dev))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `infra/feast-operator/internal/controller/access/access.go`:38 (/v1/Namespace, get, update operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `infra/feast-operator/internal/controller/access/rbac.go`:141 (create, delete, get, update operations by FeastAuthorization, rbac.authorization.k8s.io/v1/ClusterRole)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `infra/feast-operator/internal/controller/featurestore_controller.go`:198 (/v1/ConfigMap, create, delete, get, list, update operations by FeastServices, FeatureStoreReconciler, NotebookConfigMapReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `infra/feast-operator/internal/controller/services/batch_engine_rbac.go`:225 (/v1/ServiceAccount, create, update operations by FeastServices)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `infra/feast-operator/internal/controller/services/scaling.go`:82 (autoscaling/v2/HorizontalPodAutoscaler, patch operations by FeastServices)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `infra/feast-operator/internal/controller/services/services.go`:1560 (/v1/Pod, list operations by FeastServices)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `infra/feast-operator/internal/controller/services/util.go`:292 (/v1/Secret, get operations by FeastServices)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `sdk/python/feast/errors.py`:10 (Python library, gRPC framework)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `sdk/python/feast/infra/compute_engines/kubernetes/k8s_engine.py`:8 (Kubernetes API, Python client library)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `sdk/python/feast/infra/ray_initializer.py`:27 (Python client library, Ray)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `infra/feast-operator/internal/controller/access/access.go`:38 (/v1/Namespace, get, update operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `infra/feast-operator/internal/controller/access/rbac.go`:141 (create, delete, get, update operations by FeastAuthorization, rbac.authorization.k8s.io/v1/ClusterRole)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `infra/feast-operator/internal/controller/featurestore_controller.go`:198 (/v1/ConfigMap, create, delete, get, list, update operations by FeastServices, FeatureStoreReconciler, NotebookConfigMapReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `infra/feast-operator/internal/controller/featurestore_controller.go`:367 (/v1/ConfigMap, FeatureStoreReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `infra/feast-operator/internal/controller/notebook_configmap_controller.go`:496 (/v1/ConfigMap, NotebookConfigMapReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `infra/feast-operator/internal/controller/services/batch_engine_rbac.go`:225 (/v1/ServiceAccount, create, update operations by FeastServices)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `infra/feast-operator/internal/controller/services/scaling.go`:82 (autoscaling/v2/HorizontalPodAutoscaler, patch operations by FeastServices)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `infra/feast-operator/internal/controller/services/services.go`:1560 (/v1/Pod, list operations by FeastServices)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `infra/feast-operator/internal/controller/services/util.go`:292 (/v1/Secret, get operations by FeastServices)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `infra/feast-operator/config/default/manager_metrics_patch.yaml`:1 (feast-operator-controller-manager)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `infra/feast-operator/config/default/metrics_service.yaml`:1 (feast-operator-controller-manager, feast-operator-controller-manager-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `sdk/python/feast/ui_server.py`:1175 (feast)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- /get-online-features (Go HTTP) methods=POST mechanism=None enforcement=N/A policy=Bounded net/http handler chain has no authentication enforcement; pass-through middleware: metricsMiddleware, recoverMiddleware [source: go/internal/feast/server/http_server.go:388]
- /health (Go HTTP) methods=GET mechanism=None enforcement=N/A policy=Bounded net/http handler chain has no authentication enforcement; pass-through middleware: metricsMiddleware [source: go/internal/feast/server/http_server.go:389]
- :8081/healthz methods=GET mechanism=None enforcement=N/A policy=Kubernetes health probe; unauthenticated by design [source: infra/feast-operator/cmd/main.go:341]
- :8081/readyz methods=GET mechanism=None enforcement=N/A policy=Kubernetes readiness probe; unauthenticated by design [source: infra/feast-operator/cmd/main.go:345]
- :8443/metrics methods=GET mechanism=TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) enforcement=controller-runtime metrics authn/authz filter policy=RBAC via feast-operator-metrics-auth-role; exposed by Service feast-operator-controller-manager-metrics-service; controller-runtime generated self-signed TLS certificate [source: infra/feast-operator/cmd/main.go:207]
- Feast services (CRD-configured) methods=ALL mechanism=Configurable: Kubernetes RBAC or OIDC enforcement=CRD-selected service authorization policy=Exactly one of Kubernetes RBAC roles or an OIDC Secret reference is required [source: infra/feast-operator/api/v1alpha1/featurestore_types.go:613]
- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: sdk/python/feast/ui_server.py:1175]
- Kubernetes API methods=REST mechanism=ServiceAccount token (in-cluster) enforcement=kube-apiserver policy=RBAC enforced via feast-operator-manager-role ClusterRole; SA feast-operator-controller-manager [source: infra/feast-operator/internal/controller/services/util.go:391]
- gRPC services (Go) methods=ALL mechanism=None enforcement=N/A policy=Bounded grpc.NewServer option set contains only observability interceptors; no authentication interceptor configured [source: go/embedded/online_features.go:322]
### http_endpoints

- DELETE /data_sources/{name} on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/data_sources.py:262]
- DELETE /entities/{name} on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/entities.py:180]
- DELETE /feature_views/{name} on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/feature_views.py:386]
- GET / on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/ui_server.py:1175]
- GET /annotation-config/{label_view_name} on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/ui_server.py:812]
- GET /api/mlflow-feature-models on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/ui_server.py:1097]
- GET /api/mlflow-feature-usage on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/ui_server.py:997]
- GET /api/mlflow-runs on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/ui_server.py:896]
- GET /chat on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/feature_server.py:635]
- GET /compute_engines on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/compute_engines.py:127]
- GET /compute_engines/all on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/compute_engines.py:170]
- GET /data_sources on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/data_sources.py:83]
- GET /data_sources/all on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/data_sources.py:117]
- GET /data_sources/{name} on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/data_sources.py:142]
- GET /entities on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/entities.py:39]
- GET /entities/all on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/entities.py:71]
- GET /entities/{name} on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/entities.py:96]
- GET /feature_services on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/feature_services.py:23]
- GET /feature_services/all on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/feature_services.py:61]
- GET /feature_services/{name} on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/feature_services.py:86]
- GET /feature_views on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/feature_views.py:256]
- GET /feature_views/all on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/feature_views.py:86]
- GET /feature_views/{name} on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/feature_views.py:142]
- GET /features on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/features.py:22]
- GET /features/all on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/features.py:106]
- GET /features/{feature_view}/{name} on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/features.py:59]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: infra/feast-operator/cmd/main.go:341]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=cmd [source: infra/feast-operator/cmd/main.go:345]
- POST /active-learning/candidates on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/ui_server.py:502]
- POST /batch-push on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/ui_server.py:669]
- POST /chat on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/feature_server.py:629]
- POST /data_sources on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/data_sources.py:211]
- POST /entities on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/entities.py:154]
- POST /feature_views on port 6566/TCP; transport= encryption=Configurable auth=Unknown owner= [source: sdk/python/feast/api/registry/rest/feature_views.py:334]
- Unknown /get-online-features on port ; transport=HTTP/1.1 encryption= auth= owner=go/internal/feast/server [source: go/internal/feast/server/http_server.go:388]
- Unknown /get-online-features on port ; transport=HTTP/1.1 encryption= auth= owner=go/internal/feast/server [source: go/internal/feast/server/http_server.go:402]
- Unknown /health on port ; transport=HTTP/1.1 encryption= auth= owner=go/internal/feast/server [source: go/internal/feast/server/http_server.go:403]
- Unknown /health on port ; transport=HTTP/1.1 encryption= auth= owner=go/internal/feast/server [source: go/internal/feast/server/http_server.go:389]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=go [source: go/main.go:264]
- Unknown /metrics on port ; transport=HTTP/1.1 encryption= auth= owner=go [source: go/main.go:204]
### integrations

- AWS (S3-compatible storage) interaction=Python SDK client role=runtime-integration protocol=HTTPS purpose=AWS service operations via boto3 [source: infra/scripts/cleanup_ci.py:1]
- Feast FeatureStore CR interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read feature store instances [source: infra/feast-operator/config/rbac/role.yaml:2]
- Google Cloud Storage interaction=File storage client role=runtime-integration protocol=HTTP/HTTPS purpose=Runtime object storage [source: go/internal/feast/registry/gcs.go:47]
- Google Cloud Storage interaction=Python SDK client role=runtime-integration protocol=HTTPS purpose=GCS operations via Python SDK [source: sdk/python/feast/infra/offline_stores/bigquery.py:77]
- Kubeflow Notebooks interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Create and manage notebook workbenches [source: infra/feast-operator/config/rbac/role.yaml:2]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: infra/feast-operator/config/rbac/role.yaml:2]
- PostgreSQL interaction=Database client role=runtime-integration protocol=TCP purpose=Runtime relational data store [source: go/internal/feast/onlinestore/postgresonlinestore.go:35]
- Redis/Valkey interaction=Exchange client role=runtime-integration protocol=TCP purpose=Runtime queue and key-value data store [source: go/internal/feast/onlinestore/redisonlinestore.go:118]
- S3-compatible storage interaction=File storage client role=runtime-integration protocol=HTTP/HTTPS purpose=Runtime object storage [source: go/internal/feast/registry/s3.go:43]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: infra/feast-operator/config/rbac/role.yaml:2]
### internal_dependencies

- Feast (feast.dev) interaction=CRD Watch role=runtime-integration purpose=Read feature store instances [source: infra/feast-operator/config/rbac/role.yaml:2]
- Kubeflow Notebooks (kubeflow.org) interaction=CRD CRUD role=unknown purpose=Create and manage notebook workbenches [source: infra/feast-operator/config/rbac/role.yaml:2]
- Kubernetes API interaction=Python client library role=runtime-integration purpose=Kubernetes resource operations via Python SDK [source: sdk/python/feast/infra/compute_engines/kubernetes/k8s_engine.py:8]
- Ray interaction=Python client library role=runtime-integration purpose=Distributed compute orchestration via Ray SDK [source: sdk/python/feast/infra/ray_initializer.py:27]
- gRPC framework interaction=Python library role=runtime-library purpose=gRPC transport for service communication [source: sdk/python/feast/errors.py:10]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: infra/feast-operator/config/rbac/role.yaml:2]
### services

- feast port=6566 target=6566 protocol=TCP encryption= auth= [source: sdk/python/feast/ui_server.py:1175]
- feast-operator-controller-manager-metrics-service port=8443 target=8443 protocol=TCP encryption= auth= [source: infra/feast-operator/config/default/metrics_service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload feast-operator-controller-manager uses service account feast-operator-controller-manager and 1 container(s) [source: infra/feast-operator/config/default/manager_metrics_patch.yaml:1]
- **observed**: Service feast targets  with 1 port(s) [source: sdk/python/feast/ui_server.py:1175]
- **observed**: Service feast-operator-controller-manager-metrics-service targets feast-operator-controller-manager with 1 port(s) [source: infra/feast-operator/config/default/metrics_service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP GET /healthz is owned by cmd [source: infra/feast-operator/cmd/main.go:341]
- **observed**: HTTP GET /readyz is owned by cmd [source: infra/feast-operator/cmd/main.go:345]
- **observed**: HTTP Unknown /get-online-features is owned by go/internal/feast/server [source: go/internal/feast/server/http_server.go:388]
- **observed**: HTTP Unknown /health is owned by go/internal/feast/server [source: go/internal/feast/server/http_server.go:389]
- **observed**: HTTP Unknown /metrics is owned by go [source: go/main.go:204]
### security

- **observed**: ALL Feast services (CRD-configured) uses Configurable: Kubernetes RBAC or OIDC at CRD-selected service authorization; policy=Exactly one of Kubernetes RBAC roles or an OIDC Secret reference is required [source: infra/feast-operator/api/v1alpha1/featurestore_types.go:613]
- **observed**: ALL gRPC services (Go) uses None at N/A; policy=Bounded grpc.NewServer option set contains only observability interceptors; no authentication interceptor configured [source: go/embedded/online_features.go:322]
- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: sdk/python/feast/ui_server.py:1175]
- **observed**: GET /health (Go HTTP) uses None at N/A; policy=Bounded net/http handler chain has no authentication enforcement; pass-through middleware: metricsMiddleware [source: go/internal/feast/server/http_server.go:389]
- **observed**: GET :8081/healthz uses None at N/A; policy=Kubernetes health probe; unauthenticated by design [source: infra/feast-operator/cmd/main.go:341]
- **observed**: GET :8081/readyz uses None at N/A; policy=Kubernetes readiness probe; unauthenticated by design [source: infra/feast-operator/cmd/main.go:345]
- **observed**: GET :8443/metrics uses TokenReview + SubjectAccessReview (controller-runtime authn/authz filter) at controller-runtime metrics authn/authz filter; policy=RBAC via feast-operator-metrics-auth-role; exposed by Service feast-operator-controller-manager-metrics-service; controller-runtime generated self-signed TLS certificate [source: infra/feast-operator/cmd/main.go:207]
- **observed**: POST /get-online-features (Go HTTP) uses None at N/A; policy=Bounded net/http handler chain has no authentication enforcement; pass-through middleware: metricsMiddleware, recoverMiddleware [source: go/internal/feast/server/http_server.go:388]
- **observed**: RBAC role feast-operator-featurestore-editor-role grants 2 rule(s) [source: infra/feast-operator/config/rbac/featurestore_editor_role.yaml:2]
- **observed**: RBAC role feast-operator-featurestore-viewer-role grants 2 rule(s) [source: infra/feast-operator/config/rbac/featurestore_viewer_role.yaml:2]
- **observed**: RBAC role feast-operator-leader-election-role grants 3 rule(s) [source: infra/feast-operator/config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role feast-operator-manager-role grants 23 rule(s) [source: infra/feast-operator/config/rbac/role.yaml:2]
- **observed**: RBAC role feast-operator-metrics-auth-role grants 2 rule(s) [source: infra/feast-operator/config/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role feast-operator-metrics-reader grants 1 rule(s) [source: infra/feast-operator/config/rbac/metrics_reader_role.yaml:1]
- **observed**: RBAC role featurestore-editor-role grants 2 rule(s) [source: infra/feast-operator/config/rbac/featurestore_editor_role.yaml:2]
- **observed**: RBAC role featurestore-viewer-role grants 2 rule(s) [source: infra/feast-operator/config/rbac/featurestore_viewer_role.yaml:2]
- **observed**: RBAC role leader-election-role grants 3 rule(s) [source: infra/feast-operator/config/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role manager-role grants 23 rule(s) [source: infra/feast-operator/config/rbac/role.yaml:2]
- **observed**: RBAC role metrics-auth-role grants 2 rule(s) [source: infra/feast-operator/config/rbac/metrics_auth_role.yaml:1]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: infra/feast-operator/config/rbac/metrics_reader_role.yaml:1]
- **observed**: REST Kubernetes API uses ServiceAccount token (in-cluster) at kube-apiserver; policy=RBAC enforced via feast-operator-manager-role ClusterRole; SA feast-operator-controller-manager [source: infra/feast-operator/internal/controller/services/util.go:391]
- **dependency-signal**: auth-middleware targets pyjwt: JWT/OAuth authentication library dependency [source: pyproject.toml:46]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: pyproject.toml:92]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: go/internal/feast/onlinestore/redisonlinestore.go, go/internal/feast/server/http_server.go, infra/feast-operator/cmd/main.go, infra/feast-operator/internal/controller/registry/client.go]
- **dependency-signal**: tls-config targets cryptography: TLS/cryptography library dependency [source: pyproject.toml:162]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

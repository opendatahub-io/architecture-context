# Analyzer Synthesis Context: gateway-api-inference-extension

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (observed)**: 5 crds facts extracted [source: apix/config/v1alpha1/endpointpickerconfig_types.go:33, config/crd/bases/inference.networking.k8s.io_inferencepools.yaml:1, config/crd/bases/inference.networking.x-k8s.io_inferencemodelrewrites.yaml:1, config/crd/bases/inference.networking.x-k8s.io_inferenceobjectives.yaml:1, config/crd/bases/inference.networking.x-k8s.io_inferencepoolimports.yaml:1]
- **grpc_services (observed)**: 2 grpc_services facts extracted [source: pkg/bbr/server/runserver.go:73, pkg/epp/server/runserver.go:187]
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (observed)**: 5 services facts extracted [source: conformance/resources/base.yaml:215, conformance/resources/base.yaml:313, conformance/resources/base.yaml:411, conformance/resources/base.yaml:509, conformance/resources/base.yaml:718]
- **ingress (observed)**: 20 ingress facts extracted [source: conformance/resources/base.yaml:23, conformance/resources/base.yaml:41, conformance/tests/epp_unavailable_fail_open.yaml:1, conformance/tests/gateway_destination_endpoint_served.yaml:1, conformance/tests/gateway_following_epp_routing_dp.yaml:1, conformance/tests/gateway_weighted_two_pools.yaml:1, conformance/tests/httproute_invalid_inferencepool_ref.yaml:1, conformance/tests/httproute_multiple_gateways_different_pools.yaml:2, conformance/tests/httproute_multiple_gateways_different_pools.yaml:24, conformance/tests/inferencepool_accepted.yaml:2, conformance/tests/inferencepool_appprotocol.yaml:1, conformance/tests/inferencepool_appprotocol.yaml:25, conformance/tests/inferencepool_appprotocol.yaml:49, conformance/tests/inferencepool_httproute_port_validation.yaml:29, conformance/tests/inferencepool_httproute_port_validation.yaml:3, conformance/tests/inferencepool_httproute_port_validation.yaml:55, conformance/tests/inferencepool_invalid_epp_service.yaml:18, conformance/tests/inferencepool_multiple_rules_different_pools.yaml:2, conformance/tests/inferencepool_resolvedrefs_condition.yaml:32, conformance/tests/inferencepool_resolvedrefs_condition.yaml:7]
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References

- **controller**: InferencePoolReconciler —watches-reference→ inference.networking.k8s.io/v1/InferencePool; inference.networking.k8s.io/v1/InferencePool [source: pkg/epp/controller/inferencepool_reconciler.go:50, pkg/epp/controller/inferencepool_reconciler.go:76]
- **controller**: PodReconciler —watches-reference→ /v1/Pod; /v1/Pod [source: pkg/epp/controller/pod_reconciler.go:52, pkg/epp/controller/pod_reconciler.go:85]

## Behavioral Evidence

- **conditional-metrics-enforcement (unresolved)** controller-runtime metrics: controller-runtime metrics serving surface; limitations=The controller-runtime manager Metrics binding does not use one direct lexical options object with a stable SecureServing condition [source: cmd/bbr/runner/runner.go:157-157]

## Gap Evidence Index

### authentication

- **Question:** Under which configuration branch does the metrics serving surface install authentication and authorization?
  **Expected signal:** a direct SecureServing condition and controller-runtime authn/authz FilterProvider assignment
  **Candidate:** `cmd/bbr/runner/runner.go`:157-157 (controller-runtime metrics, controller-runtime metrics serving surface)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/bbr/server/runserver.go`:73 (External Processor gRPC, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `pkg/epp/server/runserver.go`:187 (Health gRPC, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `conformance/resources/base.yaml`:815 (inference-model-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `conformance/resources/base.yaml`:831 (epp-to-inference-model-reader, inference-model-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:37 (Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/bbr/main.go`:27 (bbr)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `cmd/epp/main.go`:27 (epp)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `hack/mkdocs/image/Dockerfile`:26 (hack/mkdocs/image/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pkg/generator/main.go`:35 (generator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `sidecars/latencypredictorasync/tests/Dockerfile`:23 (sidecars/latencypredictorasync/tests/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `conformance/conformance.go`:98 (Kubernetes API, client-go typed clientset)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/epp/backend/metrics/metrics.go`:117 (HTTP metrics data source, Model-serving endpoints)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pkg/epp/server/controller_config.go`:43 (Kubernetes API, client-go discovery client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### grpc_services

- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `pkg/bbr/server/runserver.go`:73 (ExternalProcessor, pkg/bbr/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `pkg/epp/server/runserver.go`:187 (Health, cmd/bbr/runner)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `conformance/tests/epp_unavailable_fail_open.yaml`:1 (Gateway API (data-science-gateway), HTTPRoute)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `conformance/tests/epp_unavailable_fail_open.yaml`:1 (Gateway API (data-science-gateway), HTTPRoute)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `conformance/utils/kubernetes/helpers.go`:317 (/v1/Service, get, update operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `conformance/utils/kubernetes/helpers.go`:362 (discovery/v1/EndpointSlice, list operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/bbr/plugins/basemodelextractor/configmap_reconciler.go`:63 (/v1/ConfigMap, get operations by ConfigMapReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/bbr/server/runserver.go`:73 (Envoy proxy, gRPC ExtProc callout)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `pkg/epp/backend/metrics/metrics.go`:117 (HTTP metrics scrape, Model-serving endpoints)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/epp/controller/inferencepool_reconciler.go`:50 (get operations by InferencePoolReconciler, inference.networking.k8s.io/v1/InferencePool)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What source-backed runtime behavior uses this component reference?
  **Expected signal:** client, API, watch, or configuration handoff
  **Candidate:** `pkg/epp/controller/pod_reconciler.go`:52 (/v1/Pod, get, list operations by PodReconciler, datastore)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### kubernetes_relationships

- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `conformance/utils/kubernetes/helpers.go`:317 (/v1/Service, get, update operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `conformance/utils/kubernetes/helpers.go`:362 (discovery/v1/EndpointSlice, list operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/bbr/plugins/basemodelextractor/base_model_to_header.go`:66 (/v1/ConfigMap)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/bbr/plugins/basemodelextractor/configmap_reconciler.go`:63 (/v1/ConfigMap, get operations by ConfigMapReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/epp/controller/inferencemodelrewrite_reconciler.go`:78 (InferenceModelRewriteReconciler, inference.networking.x-k8s.io/v1alpha2/InferenceModelRewrite)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/epp/controller/inferenceobjective_reconciler.go`:73 (InferenceObjectiveReconciler, inference.networking.x-k8s.io/v1alpha2/InferenceObjective)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/epp/controller/inferencepool_reconciler.go`:50 (get operations by InferencePoolReconciler, inference.networking.k8s.io/v1/InferencePool)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/epp/controller/inferencepool_reconciler.go`:76 (InferencePoolReconciler, inference.networking.k8s.io/v1/InferencePool)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** How is this Kubernetes or platform resource reference used at runtime?
  **Expected signal:** typed client, CRUD operation, watch, or configuration projection
  **Candidate:** `pkg/epp/controller/pod_reconciler.go`:52 (/v1/Pod, get, list operations by PodReconciler, datastore)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which client/resource relationship implements this controller watch, and under what condition?
  **Expected signal:** watch registration, GVK, resource operations, or conditional branch
  **Candidate:** `pkg/epp/controller/pod_reconciler.go`:85 (/v1/Pod, PodReconciler)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `conformance/resources/base.yaml`:105 (secondary-inference-model-server-deployment)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `conformance/resources/base.yaml`:149 (appprotocol-inference-model-server-deployment)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `conformance/resources/base.yaml`:215 (primary-app-endpoint-picker, primary-endpoint-picker-svc)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `conformance/resources/base.yaml`:231 (primary-app-endpoint-picker)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `conformance/resources/base.yaml`:313 (secondary-app-endpoint-picker, secondary-endpoint-picker-svc)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `conformance/resources/base.yaml`:329 (secondary-app-endpoint-picker)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `conformance/resources/base.yaml`:411 (appprotocol-http-app-endpoint-picker, appprotocol-http-endpoint-picker-svc)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `conformance/resources/base.yaml`:427 (appprotocol-http-app-endpoint-picker)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `conformance/resources/base.yaml`:509 (appprotocol-h2c-app-endpoint-picker, appprotocol-h2c-endpoint-picker-svc)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `conformance/resources/base.yaml`:525 (appprotocol-h2c-app-endpoint-picker)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `conformance/resources/base.yaml`:61 (primary-inference-model-server-deployment)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `conformance/resources/base.yaml`:718 (dp-app-endpoint-picker, dp-endpoint-picker-svc)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- External Processor gRPC methods=gRPC mechanism=None enforcement=N/A policy=Transport TLS is configuration-dependent; no application authentication interceptor is configured [source: pkg/bbr/server/runserver.go:73]
- Health gRPC methods=gRPC mechanism=None enforcement=N/A policy=Transport TLS is configuration-dependent; no application authentication interceptor is configured [source: pkg/epp/server/runserver.go:187]
### integrations

- Gateway API (data-science-gateway) interaction=HTTPRoute role=runtime-transport protocol=HTTPS purpose=External dashboard ingress [source: conformance/tests/epp_unavailable_fail_open.yaml:1]
### internal_dependencies

- Envoy proxy interaction=gRPC ExtProc callout role=runtime-transport purpose=Receive per-request processing callouts through the Envoy External Processing API [source: pkg/bbr/server/runserver.go:73]
- Gateway API (data-science-gateway) interaction=HTTPRoute role=runtime-transport purpose=Platform ingress through Gateway API [source: conformance/tests/epp_unavailable_fail_open.yaml:1]
- Model-serving endpoints interaction=HTTP metrics scrape role=runtime-transport purpose=Scrape configured metrics from discovered model-serving endpoints [source: pkg/epp/backend/metrics/metrics.go:117]
### services

- appprotocol-h2c-endpoint-picker-svc port=9002 target=9002 protocol=TCP encryption= auth= [source: conformance/resources/base.yaml:509]
- appprotocol-http-endpoint-picker-svc port=9002 target=9002 protocol=TCP encryption= auth= [source: conformance/resources/base.yaml:411]
- dp-endpoint-picker-svc port=9002 target=9002 protocol=TCP encryption= auth= [source: conformance/resources/base.yaml:718]
- primary-endpoint-picker-svc port=9002 target=9002 protocol=TCP encryption= auth= [source: conformance/resources/base.yaml:215]
- secondary-endpoint-picker-svc port=9002 target=9002 protocol=TCP encryption= auth= [source: conformance/resources/base.yaml:313]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Controller-created Deployment workload appprotocol-h2c-app-endpoint-picker uses service account  and 1 container(s) [source: conformance/resources/base.yaml:525]
- **observed**: Controller-created Deployment workload appprotocol-http-app-endpoint-picker uses service account  and 1 container(s) [source: conformance/resources/base.yaml:427]
- **observed**: Controller-created Deployment workload appprotocol-inference-model-server-deployment uses service account  and 1 container(s) [source: conformance/resources/base.yaml:149]
- **observed**: Controller-created Deployment workload dp-app-endpoint-picker uses service account  and 1 container(s) [source: conformance/resources/base.yaml:734]
- **observed**: Controller-created Deployment workload dp-inference-model-server-deployment uses service account  and 3 container(s) [source: conformance/resources/base.yaml:589]
- **observed**: Controller-created Deployment workload primary-app-endpoint-picker uses service account  and 1 container(s) [source: conformance/resources/base.yaml:231]
- **observed**: Controller-created Deployment workload primary-inference-model-server-deployment uses service account  and 1 container(s) [source: conformance/resources/base.yaml:61]
- **observed**: Controller-created Deployment workload secondary-app-endpoint-picker uses service account  and 1 container(s) [source: conformance/resources/base.yaml:329]
- **observed**: Controller-created Deployment workload secondary-inference-model-server-deployment uses service account  and 1 container(s) [source: conformance/resources/base.yaml:105]
- **observed**: Service appprotocol-h2c-endpoint-picker-svc targets appprotocol-h2c-app-endpoint-picker with 1 port(s) [source: conformance/resources/base.yaml:509]
- **observed**: Service appprotocol-http-endpoint-picker-svc targets appprotocol-http-app-endpoint-picker with 1 port(s) [source: conformance/resources/base.yaml:411]
- **observed**: Service dp-endpoint-picker-svc targets dp-app-endpoint-picker with 1 port(s) [source: conformance/resources/base.yaml:718]
- **observed**: Service primary-endpoint-picker-svc targets primary-app-endpoint-picker with 1 port(s) [source: conformance/resources/base.yaml:215]
- **observed**: Service secondary-endpoint-picker-svc targets secondary-app-endpoint-picker with 1 port(s) [source: conformance/resources/base.yaml:313]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: Gateway conformance-primary serves host  via plaintext; backend=; transport=Unknown [source: conformance/resources/base.yaml:23]
- **observed**: Gateway conformance-secondary serves host secondary.example.com via plaintext; backend=; transport=Unknown [source: conformance/resources/base.yaml:41]
- **observed**: HTTPRoute httproute-for-destination-endpoint-served serves host primary.example.com via plaintext; backend=primary-inference-pool; transport=Unknown [source: conformance/tests/gateway_destination_endpoint_served.yaml:1]
- **observed**: HTTPRoute httproute-for-failopen-pool-gw serves host secondary.example.com via plaintext; backend=secondary-inference-pool; transport=Unknown [source: conformance/tests/epp_unavailable_fail_open.yaml:1]
- **observed**: HTTPRoute httproute-for-inferencepool-accepted serves host  via plaintext; backend=primary-inference-pool; transport=Unknown [source: conformance/tests/inferencepool_accepted.yaml:2]
- **observed**: HTTPRoute httproute-for-inferencepool-appprotocol-default serves host appprotocol-default.example.com via plaintext; backend=primary-inference-pool; transport=Unknown [source: conformance/tests/inferencepool_appprotocol.yaml:49]
- **observed**: HTTPRoute httproute-for-inferencepool-appprotocol-h2c serves host appprotocol-h2c.example.com via plaintext; backend=appprotocol-h2c-inference-pool; transport=Unknown [source: conformance/tests/inferencepool_appprotocol.yaml:1]
- **observed**: HTTPRoute httproute-for-inferencepool-appprotocol-http serves host appprotocol-http.example.com via plaintext; backend=appprotocol-http-inference-pool; transport=Unknown [source: conformance/tests/inferencepool_appprotocol.yaml:25]
- **observed**: HTTPRoute httproute-for-invalid-epp-pool serves host  via plaintext; backend=pool-with-invalid-epp; transport=Unknown [source: conformance/tests/inferencepool_invalid_epp_service.yaml:18]
- **observed**: HTTPRoute httproute-for-primary-gw serves host primary.example.com via plaintext; backend=primary-inference-pool; transport=Unknown [source: conformance/tests/inferencepool_resolvedrefs_condition.yaml:7]
- **observed**: HTTPRoute httproute-for-primary-gw-dp serves host primary.example.com via plaintext; backend=dp-inference-pool; transport=Unknown [source: conformance/tests/gateway_following_epp_routing_dp.yaml:1]
- **observed**: HTTPRoute httproute-for-secondary-gw serves host secondary.example.com via plaintext; backend=primary-inference-pool; transport=Unknown [source: conformance/tests/inferencepool_resolvedrefs_condition.yaml:32]
- **observed**: HTTPRoute httproute-multiple-rules-different-pools serves host  via plaintext; backend=primary-inference-pool; transport=Unknown [source: conformance/tests/inferencepool_multiple_rules_different_pools.yaml:2]
- **observed**: HTTPRoute httproute-pool-port-matching serves host port-matching.example.com via plaintext; backend=primary-inference-pool; transport=Unknown [source: conformance/tests/inferencepool_httproute_port_validation.yaml:29]
- **observed**: HTTPRoute httproute-pool-port-non-matching serves host port-non-matching.example.com via plaintext; backend=primary-inference-pool; transport=Unknown [source: conformance/tests/inferencepool_httproute_port_validation.yaml:55]
- **observed**: HTTPRoute httproute-pool-port-unspecified serves host port-unspecified.example.com via plaintext; backend=primary-inference-pool; transport=Unknown [source: conformance/tests/inferencepool_httproute_port_validation.yaml:3]
- **observed**: HTTPRoute httproute-to-non-existent-pool serves host  via plaintext; backend=non-existent-inference-pool; transport=Unknown [source: conformance/tests/httproute_invalid_inferencepool_ref.yaml:1]
- **observed**: HTTPRoute httproute-weighted-two-pools serves host primary.example.com via plaintext; backend=primary-inference-pool; transport=Unknown [source: conformance/tests/gateway_weighted_two_pools.yaml:1]
- **observed**: HTTPRoute route-for-primary-gateway serves host primary.example.com via plaintext; backend=primary-inference-pool; transport=Unknown [source: conformance/tests/httproute_multiple_gateways_different_pools.yaml:2]
- **observed**: HTTPRoute route-for-secondary-gateway serves host secondary.example.com via plaintext; backend=secondary-inference-pool; transport=Unknown [source: conformance/tests/httproute_multiple_gateways_different_pools.yaml:24]
### security

- **observed**: RBAC role inference-model-reader grants 3 rule(s) [source: conformance/resources/base.yaml:815]
- **observed**: gRPC External Processor gRPC uses None at N/A; policy=Transport TLS is configuration-dependent; no application authentication interceptor is configured [source: pkg/bbr/server/runserver.go:73]
- **observed**: gRPC Health gRPC uses None at N/A; policy=Transport TLS is configuration-dependent; no application authentication interceptor is configured [source: pkg/epp/server/runserver.go:187]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: internal/tls/tls.go, pkg/bbr/server/runserver.go, pkg/common/certs.go, pkg/epp/backend/metrics/metrics.go, pkg/epp/framework/plugins/datalayer/source/http/datasource.go, pkg/epp/server/runserver.go]
- **dependency-signal**: tls-config targets google.golang.org/grpc/credentials: TLS configuration import [source: pkg/bbr/server/runserver.go, pkg/epp/server/runserver.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

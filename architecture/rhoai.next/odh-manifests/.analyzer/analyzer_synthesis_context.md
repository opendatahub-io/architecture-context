# Analyzer Synthesis Context: odh-manifests

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (observed)**: 1 services facts extracted [source: odh-model-controller/rbac/auth_proxy_service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (observed)**: 1 webhooks facts extracted [source: kserve/kserve-built/kserve-built.yaml:514, model-mesh/odh-modelmesh-controller/crd/patches/webhook_in_predictors.yaml:17, model-mesh/odh-modelmesh-controller/crd/patches/webhook_in_servingruntimes.yaml:17, odh-notebook-controller/kf-notebook-controller/crd/patches/webhook_in_notebooks.yaml:4, trustyai-service-operator/crd/patches/webhook_in_trustyaiservices.yaml:2]

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `odh-model-controller/rbac/auth_proxy_client_clusterrole.yaml`:1 (metrics-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `odh-model-controller/rbac/auth_proxy_role.yaml`:1 (proxy-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `odh-model-controller/rbac/auth_proxy_role_binding.yaml`:1 (proxy-role, proxy-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `odh-model-controller/rbac/kserve_prometheus_clusterrole.yaml`:1 (kserve-prometheus-k8s)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `odh-model-controller/rbac/leader_election_role.yaml`:2 (leader-election-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `odh-model-controller/rbac/leader_election_role_binding.yaml`:1 (leader-election-role, leader-election-rolebinding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `odh-model-controller/rbac/role.yaml`:2 (odh-model-controller-role)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `odh-model-controller/rbac/role_binding.yaml`:1 (odh-model-controller-role, odh-model-controller-rolebinding-$(mesh-namespace))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `tests/Dockerfile`:68 (tests/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `odh-model-controller/rbac/role.yaml`:2 (CRD CRUD, ServingRuntime CR)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `odh-model-controller/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `odh-model-controller/rbac/role.yaml`:2 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `odh-model-controller/rbac/role.yaml`:2 (CRD Watch, OpenShift Routes)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `odh-model-controller/rbac/role.yaml`:2 (CRD CRUD, prometheus-operator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `odh-model-controller/rbac/role.yaml`:2 (CRD Watch, KServe InferenceService)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `odh-model-controller/manager/manager.yaml`:1 (odh-model-controller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `odh-model-controller/rbac/auth_proxy_service.yaml`:1 (odh-model-controller, odh-model-controller-metrics-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### webhooks

- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `kserve/kserve-built/kserve-built.yaml`:514 (/convert, inferenceservices.serving.kserve.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `model-mesh/odh-modelmesh-controller/crd/patches/webhook_in_predictors.yaml`:17 (/convert, inferenceservices.serving.kserve.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `model-mesh/odh-modelmesh-controller/crd/patches/webhook_in_servingruntimes.yaml`:17 (/convert, inferenceservices.serving.kserve.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `odh-notebook-controller/kf-notebook-controller/crd/patches/webhook_in_notebooks.yaml`:4 (/convert, inferenceservices.serving.kserve.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which handler implements this webhook and what admission/resource semantics does it enforce?
  **Expected signal:** handler registration, rules, failure policy, or service binding
  **Candidate:** `trustyai-service-operator/crd/patches/webhook_in_trustyaiservices.yaml`:2 (/convert, inferenceservices.serving.kserve.io)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### integrations

- KServe InferenceService interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Read model serving state [source: odh-model-controller/rbac/role.yaml:2]
- OpenShift Routes interaction=CRD Watch role=runtime-integration protocol=HTTPS purpose=Dashboard route status [source: odh-model-controller/rbac/role.yaml:2]
- ServingRuntime CR interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage serving runtime templates [source: odh-model-controller/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown protocol=HTTPS purpose=Manage Prometheus monitoring resources [source: odh-model-controller/rbac/role.yaml:2]
### internal_dependencies

- KServe InferenceService interaction=CRD Watch role=runtime-integration purpose=Read model serving state [source: odh-model-controller/rbac/role.yaml:2]
- prometheus-operator interaction=CRD CRUD role=unknown purpose=Manage Prometheus monitoring resources [source: odh-model-controller/rbac/role.yaml:2]
### services

- odh-model-controller-metrics-service port=8080 target=8080 protocol=TCP encryption= auth= [source: odh-model-controller/rbac/auth_proxy_service.yaml:1]
### serving_runtime_definitions

- ClusterServingRuntime mlserver-0.x formats=lightgbm:3 (autoSelect), sklearn:0 (autoSelect), xgboost:1 (autoSelect) images=mlserver=mlserver-0:replace builtInAdapter=mlserver [source: model-mesh/odh-modelmesh-controller/runtimes/mlserver-0.x.yaml:14]
- ClusterServingRuntime ovms-1.x formats=onnx:1, openvino_ir:opset1 (autoSelect) images=ovms=$(odh-openvino) builtInAdapter=ovms [source: model-mesh/odh-modelmesh-controller/runtimes/ovms-1.x.yaml:14]
- ClusterServingRuntime torchserve-0.x formats=pytorch-mar:0 (autoSelect) images=torchserve=torchserve-0:replace builtInAdapter=torchserve [source: model-mesh/odh-modelmesh-controller/runtimes/torchserve-0.x.yaml:14]
- ClusterServingRuntime triton-2.x formats=keras:2 (autoSelect), onnx:1 (autoSelect), pytorch:1 (autoSelect), tensorflow:1 (autoSelect), tensorflow:2 (autoSelect), tensorrt:7 (autoSelect) images=triton=tritonserver-2:replace builtInAdapter=triton [source: model-mesh/odh-modelmesh-controller/runtimes/triton-2.x.yaml:14]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload odh-model-controller uses service account odh-model-controller and 1 container(s) [source: odh-model-controller/manager/manager.yaml:1]
- **observed**: Service odh-model-controller-metrics-service targets odh-model-controller with 1 port(s) [source: odh-model-controller/rbac/auth_proxy_service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: RBAC role kserve-prometheus-k8s grants 1 rule(s) [source: odh-model-controller/rbac/kserve_prometheus_clusterrole.yaml:1]
- **observed**: RBAC role leader-election-role grants 3 rule(s) [source: odh-model-controller/rbac/leader_election_role.yaml:2]
- **observed**: RBAC role metrics-reader grants 1 rule(s) [source: odh-model-controller/rbac/auth_proxy_client_clusterrole.yaml:1]
- **observed**: RBAC role odh-model-controller-role grants 17 rule(s) [source: odh-model-controller/rbac/role.yaml:2]
- **observed**: RBAC role proxy-role grants 2 rule(s) [source: odh-model-controller/rbac/auth_proxy_role.yaml:1]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

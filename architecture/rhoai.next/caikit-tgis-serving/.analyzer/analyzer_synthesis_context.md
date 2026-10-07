# Analyzer Synthesis Context: caikit-tgis-serving

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (observed)**: 3 services facts extracted [source: demo/kserve/custom-manifests/metrics/caikit-metrics-service.yaml:1, demo/kserve/custom-manifests/minio/minio.yaml:1, demo/kserve/custom-manifests/serverless/gateways.yaml:1]
- **ingress (observed)**: 2 ingress facts extracted [source: demo/kserve/custom-manifests/serverless/gateways.yaml:18, demo/kserve/custom-manifests/serverless/gateways.yaml:37]
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `demo/kserve/custom-manifests/metrics/kserve-prometheus-k8s.yaml`:1 (kserve-prometheus-k8s)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:42 (Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:42 (Dockerfile.konflux:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `utils/convert.py`:2 (Caikit Runtime, Python library)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `demo/kserve/custom-manifests/metrics/caikit-metrics-service.yaml`:1 (caikit-example-isvc-predictor-default-sm)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `demo/kserve/custom-manifests/minio/minio.yaml`:1 (minio)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `demo/kserve/custom-manifests/serverless/gateways.yaml`:1 (knative-local-gateway)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### internal_dependencies

- Caikit Runtime interaction=Python library role=runtime-library purpose=Caikit NLP runtime module [source: utils/convert.py:2]
### services

- caikit-example-isvc-predictor-default-sm port=8086 target=8086 protocol=TCP encryption= auth= [source: demo/kserve/custom-manifests/metrics/caikit-metrics-service.yaml:1]
- knative-local-gateway port=80 target=8081 protocol=TCP encryption= auth= [source: demo/kserve/custom-manifests/serverless/gateways.yaml:1]
- minio port=9000 target=9000 protocol=TCP encryption= auth= [source: demo/kserve/custom-manifests/minio/minio.yaml:1]
### serving_runtime_definitions

- ServingRuntime caikit-runtime formats=caikit (autoSelect) images=kserve-container=quay.io/opendatahub/text-generation-inference:stable-bafd218, transformer-container=quay.io/opendatahub/caikit-tgis-serving:fast builtInAdapter= [source: demo/kserve/custom-manifests/caikit/caikit-standalone/working/working.yaml:37]
- ServingRuntime caikit-standalone-runtime formats=caikit (autoSelect) images=kserve-container=quay.io/opendatahub/caikit-nlp:fast builtInAdapter= [source: demo/kserve/custom-manifests/caikit/caikit-standalone/caikit-standalone-servingruntime.yaml:1]
- ServingRuntime caikit-standalone-runtime-grpc formats=caikit (autoSelect) images=kserve-container=quay.io/opendatahub/caikit-nlp:stable builtInAdapter= [source: demo/kserve/custom-manifests/caikit/caikit-standalone/caikit-standalone-servingruntime-grpc.yaml:1]
- ServingRuntime caikit-tgis-runtime formats=caikit (autoSelect) images=kserve-container=quay.io/opendatahub/text-generation-inference:fast, transformer-container=quay.io/opendatahub/caikit-tgis-serving:fast builtInAdapter= [source: test/kserve/caikit-tgis-serving.yaml:17]
- ServingRuntime caikit-tgis-runtime-grpc formats=caikit (autoSelect) images=kserve-container=quay.io/opendatahub/text-generation-inference:stable, transformer-container=quay.io/opendatahub/caikit-tgis-serving:stable builtInAdapter= [source: demo/kserve/custom-manifests/caikit/caikit-tgis/caikit-tgis-servingruntime-grpc.yaml:1]
- ServingRuntime tgis-runtime formats=pytorch (autoSelect) images=kserve-container=quay.io/opendatahub/text-generation-inference:stable builtInAdapter= [source: demo/kserve/custom-manifests/tgis/tgis-servingruntime.yaml:1]
- ServingRuntime tgis-runtime-grpc formats=pytorch (autoSelect) images=kserve-container=quay.io/opendatahub/text-generation-inference:stable builtInAdapter= [source: demo/kserve/custom-manifests/tgis/tgis-servingruntime-grpc.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service caikit-example-isvc-predictor-default-sm targets  with 1 port(s) [source: demo/kserve/custom-manifests/metrics/caikit-metrics-service.yaml:1]
- **observed**: Service knative-local-gateway targets  with 1 port(s) [source: demo/kserve/custom-manifests/serverless/gateways.yaml:1]
- **observed**: Service minio targets  with 1 port(s) [source: demo/kserve/custom-manifests/minio/minio.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: Gateway knative-ingress-gateway serves host  via plaintext; backend=; transport=Unknown [source: demo/kserve/custom-manifests/serverless/gateways.yaml:18]
- **observed**: Gateway knative-local-gateway serves host  via plaintext; backend=; transport=Unknown [source: demo/kserve/custom-manifests/serverless/gateways.yaml:37]
### security

- **observed**: RBAC role kserve-prometheus-k8s grants 1 rule(s) [source: demo/kserve/custom-manifests/metrics/kserve-prometheus-k8s.yaml:1]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

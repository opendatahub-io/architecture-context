# Analyzer Synthesis Context: trustyai-service

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 87 http_endpoints facts extracted [source: src/endpoints/consumer/consumer_endpoint.py:443, src/endpoints/consumer/consumer_endpoint.py:66, src/endpoints/data/data_upload.py:44, src/endpoints/explainers/global_explainer.py:28, src/endpoints/explainers/global_explainer.py:40, src/endpoints/explainers/local_explainer.py:115, src/endpoints/explainers/local_explainer.py:150, src/endpoints/explainers/local_explainer.py:190, src/endpoints/explainers/local_explainer.py:60, src/endpoints/metadata.py:221, src/endpoints/metadata.py:233, src/endpoints/metadata.py:358, src/endpoints/metadata.py:416, src/endpoints/metadata.py:464, src/endpoints/metadata.py:473, src/endpoints/metadata.py:80, src/endpoints/metrics/batch_mean.py:136, src/endpoints/metrics/batch_mean.py:190, src/endpoints/metrics/batch_mean.py:202, src/endpoints/metrics/batch_mean.py:214, src/endpoints/metrics/batch_mean.py:227, src/endpoints/metrics/batch_mean.py:250, src/endpoints/metrics/batch_mean.py:288, src/endpoints/metrics/batch_mean.py:295, src/endpoints/metrics/batch_mean.py:302, src/endpoints/metrics/batch_mean.py:309, src/endpoints/metrics/batch_mean.py:316, src/endpoints/metrics/batch_mean.py:323, src/endpoints/metrics/drift/approx_ks_test.py:45, src/endpoints/metrics/drift/approx_ks_test.py:55, src/endpoints/metrics/drift/approx_ks_test.py:64, src/endpoints/metrics/drift/approx_ks_test.py:76, src/endpoints/metrics/drift/approx_ks_test.py:86, src/endpoints/metrics/drift/compare_means.py:213, src/endpoints/metrics/drift/compare_means.py:231, src/endpoints/metrics/drift/compare_means.py:296, src/endpoints/metrics/drift/compare_means.py:341, src/endpoints/metrics/drift/compare_means.py:421, src/endpoints/metrics/drift/compare_means.py:439, src/endpoints/metrics/drift/compare_means.py:450, src/endpoints/metrics/drift/compare_means.py:466, src/endpoints/metrics/drift/compare_means.py:477, src/endpoints/metrics/drift/compare_means.py:93, src/endpoints/metrics/drift/fourier_mmd.py:101, src/endpoints/metrics/drift/fourier_mmd.py:60, src/endpoints/metrics/drift/fourier_mmd.py:70, src/endpoints/metrics/drift/fourier_mmd.py:79, src/endpoints/metrics/drift/fourier_mmd.py:91, src/endpoints/metrics/drift/jensen_shannon.py:203, src/endpoints/metrics/drift/jensen_shannon.py:223, src/endpoints/metrics/drift/jensen_shannon.py:271, src/endpoints/metrics/drift/jensen_shannon.py:316, src/endpoints/metrics/drift/jensen_shannon.py:96, src/endpoints/metrics/drift/kolmogorov_smirnov.py:169, src/endpoints/metrics/drift/kolmogorov_smirnov.py:186, src/endpoints/metrics/drift/kolmogorov_smirnov.py:221, src/endpoints/metrics/drift/kolmogorov_smirnov.py:266, src/endpoints/metrics/drift/kolmogorov_smirnov.py:73, src/endpoints/metrics/fairness/group/dir.py:107, src/endpoints/metrics/fairness/group/dir.py:175, src/endpoints/metrics/fairness/group/dir.py:185, src/endpoints/metrics/fairness/group/dir.py:195, src/endpoints/metrics/fairness/group/dir.py:228, src/endpoints/metrics/fairness/group/dir.py:272, src/endpoints/metrics/fairness/group/dir.py:330, src/endpoints/metrics/fairness/group/dir.py:343, src/endpoints/metrics/fairness/group/dir.py:353, src/endpoints/metrics/fairness/group/dir.py:365, src/endpoints/metrics/fairness/group/dir.py:375, src/endpoints/metrics/fairness/group/dir.py:385, src/endpoints/metrics/fairness/group/spd.py:111, src/endpoints/metrics/fairness/group/spd.py:171, src/endpoints/metrics/fairness/group/spd.py:182, src/endpoints/metrics/fairness/group/spd.py:192, src/endpoints/metrics/fairness/group/spd.py:225, src/endpoints/metrics/fairness/group/spd.py:269, src/endpoints/metrics/fairness/group/spd.py:327, src/endpoints/metrics/fairness/group/spd.py:340, src/endpoints/metrics/fairness/group/spd.py:350, src/endpoints/metrics/fairness/group/spd.py:362, src/endpoints/metrics/fairness/group/spd.py:372, src/endpoints/metrics/fairness/group/spd.py:382, src/endpoints/metrics/metrics_info.py:13, src/main.py:189, src/main.py:198, src/main.py:209, src/main.py:219]
- **services (observed)**: 1 services facts extracted [source: src/main.py:189]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `src/main.py`:189 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:130 (Dockerfile.konflux:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:20 (hypercorn)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/endpoints/consumer/consumer_endpoint.py`:443 (/, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/endpoints/data/data_upload.py`:44 (/data/upload, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/endpoints/explainers/global_explainer.py`:28 (/explainers/global/lime, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/endpoints/explainers/local_explainer.py`:150 (/explainers/local/cf, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/endpoints/metadata.py`:221 (/info/inference/ids/{model}, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/endpoints/metrics/batch_mean.py`:190 (/metrics/batchmean/definition, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/endpoints/metrics/drift/approx_ks_test.py`:55 (/metrics/drift/approxkstest/definition, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/endpoints/metrics/drift/compare_means.py`:213 (/metrics/drift/comparemeans/definition, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/endpoints/metrics/drift/fourier_mmd.py`:70 (/metrics/drift/fouriermmd/definition, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/endpoints/metrics/fairness/group/dir.py`:343 (/dir/definition, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/endpoints/metrics/metrics_info.py`:13 (/metrics/all/requests, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/main.py`:189 (/, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `src/main.py`:189 (trustyai-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: src/main.py:189]
### http_endpoints

- DELETE /dir/request on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/fairness/group/dir.py:375]
- DELETE /info/names on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metadata.py:416]
- DELETE /metrics/batchmean/request on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/batch_mean.py:227]
- DELETE /metrics/drift/approxkstest/request on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/drift/approx_ks_test.py:76]
- DELETE /metrics/drift/comparemeans/request on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/drift/compare_means.py:296]
- GET / on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/main.py:189]
- GET /dir/definition on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/fairness/group/dir.py:343]
- GET /dir/requests on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/fairness/group/dir.py:385]
- GET /info on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metadata.py:80]
- GET /info/inference/ids/{model} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metadata.py:221]
- GET /info/names on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metadata.py:233]
- GET /info/tags on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metadata.py:464]
- GET /metrics/all/requests on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/metrics_info.py:13]
- GET /metrics/batchmean/definition on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/batch_mean.py:190]
- GET /metrics/batchmean/requests on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/batch_mean.py:250]
- GET /metrics/drift/approxkstest/definition on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/drift/approx_ks_test.py:55]
- GET /metrics/drift/approxkstest/requests on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/drift/approx_ks_test.py:86]
- GET /metrics/drift/comparemeans/definition on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/drift/compare_means.py:213]
- GET /metrics/drift/comparemeans/requests on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/drift/compare_means.py:341]
- POST / on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/consumer/consumer_endpoint.py:443]
- POST /consumer/kserve/v2 on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/consumer/consumer_endpoint.py:66]
- POST /data/upload on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/data/data_upload.py:44]
- POST /dir on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/fairness/group/dir.py:330]
- POST /dir/definition on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/fairness/group/dir.py:353]
- POST /dir/request on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/fairness/group/dir.py:365]
- POST /explainers/global/lime on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/explainers/global_explainer.py:28]
- POST /explainers/global/pdp on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/explainers/global_explainer.py:40]
- POST /explainers/local/cf on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/explainers/local_explainer.py:150]
- POST /explainers/local/lime on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/explainers/local_explainer.py:60]
- POST /explainers/local/shap on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/explainers/local_explainer.py:115]
- POST /explainers/local/tssaliency on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/explainers/local_explainer.py:190]
- POST /info/names on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metadata.py:358]
- POST /info/tags on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metadata.py:473]
- POST /metrics/batchmean on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/batch_mean.py:136]
- POST /metrics/batchmean/definition on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/batch_mean.py:202]
- POST /metrics/batchmean/request on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/batch_mean.py:214]
- POST /metrics/drift/approxkstest on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/drift/approx_ks_test.py:45]
- POST /metrics/drift/approxkstest/request on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/drift/approx_ks_test.py:64]
- POST /metrics/drift/comparemeans on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/drift/compare_means.py:93]
- POST /metrics/drift/comparemeans/request on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/endpoints/metrics/drift/compare_means.py:231]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service trustyai-service targets  with 0 port(s) [source: src/main.py:189]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: src/main.py:189]
- **dependency-signal**: tls-config targets cryptography: TLS/cryptography library dependency [source: pyproject.toml:22]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

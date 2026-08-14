# Analyzer Synthesis Context: notebooks

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (observed)**: 1 http_endpoints facts extracted [source: ci/cached-builds/make_test.py:183]
- **services (observed)**: 1 services facts extracted [source: ci/cached-builds/make_test.py:183]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `ci/cached-builds/make_test.py`:183 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `codeserver-baseline/ubi9-python-3.12/Dockerfile.konflux.cpu`:342 (codeserver-baseline/ubi9-python-3.12/Dockerfile.konflux.cpu:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `codeserver/ubi9-python-3.12/Dockerfile.konflux.cpu`:367 (codeserver/ubi9-python-3.12/Dockerfile.konflux.cpu:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `examples/jupyterlab-with-elyra/Dockerfile`:35 (examples/jupyterlab-with-elyra/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `jupyter/baseline/ubi9-python-3.12/Dockerfile.konflux.cpu`:111 (jupyter/baseline/ubi9-python-3.12/Dockerfile.konflux.cpu:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `jupyter/datascience/ubi9-python-3.12/Dockerfile.konflux.cpu`:100 (jupyter/datascience/ubi9-python-3.12/Dockerfile.konflux.cpu:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `jupyter/minimal/ubi9-python-3.12/Dockerfile.konflux.cpu`:115 (jupyter/minimal/ubi9-python-3.12/Dockerfile.konflux.cpu:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `jupyter/minimal/ubi9-python-3.12/Dockerfile.konflux.cuda`:114 (jupyter/minimal/ubi9-python-3.12/Dockerfile.konflux.cuda:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `jupyter/minimal/ubi9-python-3.12/Dockerfile.konflux.rocm`:119 (jupyter/minimal/ubi9-python-3.12/Dockerfile.konflux.rocm:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `jupyter/pytorch+llmcompressor/ubi9-python-3.12/Dockerfile.konflux.cuda`:101 (jupyter/pytorch+llmcompressor/ubi9-python-3.12/Dockerfile.konflux.cuda:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `jupyter/pytorch/ubi9-python-3.12/Dockerfile.konflux.cuda`:90 (jupyter/pytorch/ubi9-python-3.12/Dockerfile.konflux.cuda:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `jupyter/rocm/pytorch/ubi9-python-3.12/Dockerfile.konflux.rocm`:91 (jupyter/rocm/pytorch/ubi9-python-3.12/Dockerfile.konflux.rocm:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `jupyter/rocm/tensorflow/ubi9-python-3.12/Dockerfile.konflux.rocm`:101 (jupyter/rocm/tensorflow/ubi9-python-3.12/Dockerfile.konflux.rocm:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `ci/cached-builds/make_test.py`:183 (PATCH, time.sleep)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `ci/cached-builds/make_test.py`:183 (notebooks)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: ci/cached-builds/make_test.py:183]
### http_endpoints

- PATCH time.sleep on port ; transport= encryption=Configurable auth=Unknown owner= [source: ci/cached-builds/make_test.py:183]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service notebooks targets  with 0 port(s) [source: ci/cached-builds/make_test.py:183]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: ci/cached-builds/make_test.py:183]
- **dependency-signal**: auth-middleware targets pyjwt: JWT/OAuth authentication library dependency [source: codeserver/ubi9-python-3.12/requirements.cpu.txt:456]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: codeserver/ubi9-python-3.12/requirements.cpu.txt:266]
- **dependency-signal**: tls-config targets cryptography: TLS/cryptography library dependency [source: codeserver/ubi9-python-3.12/requirements.cpu.txt:92]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

# Analyzer Synthesis Context: llama-stack-provider-trustyai-garak

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Gap Evidence Index

### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `requirements.txt`:700 (uvicorn)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `src/llama_stack_provider_trustyai_garak/evalhub/s3_utils.py`:30 (AWS (S3-compatible storage), Python SDK client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `src/llama_stack_provider_trustyai_garak/evalhub/garak_adapter.py`:759 (Kubeflow Pipelines SDK, Python client library)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### integrations

- AWS (S3-compatible storage) interaction=Python SDK client role=runtime-integration protocol=HTTPS purpose=AWS service operations via boto3 [source: src/llama_stack_provider_trustyai_garak/evalhub/s3_utils.py:30]
### internal_dependencies

- Kubeflow Pipelines SDK interaction=Python client library role=runtime-integration purpose=Pipeline definition and execution [source: src/llama_stack_provider_trustyai_garak/evalhub/garak_adapter.py:759]

## Cross-Cutting Evidence

### deployment_topology

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:deployment_topology]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **dependency-signal**: auth-middleware targets pyjwt: JWT/OAuth authentication library dependency [source: requirements.txt:486]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: requirements.txt:284]
- **dependency-signal**: tls-config targets cryptography: TLS/cryptography library dependency [source: requirements.txt:85]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

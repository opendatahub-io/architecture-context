# Analyzer Synthesis Context: praxis-extproc

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (observed)**: 1 services facts extracted [source: deploy/base/instance/service.yaml:1]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:58 (Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux`:59 (Dockerfile.konflux:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deploy/base/instance/deployment.yaml`:1 (payload-processing)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/base/instance/service.yaml`:1 (payload-processing)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### services

- payload-processing port=9004 target=9004 protocol=TCP encryption= auth= [source: deploy/base/instance/service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload payload-processing uses service account  and 1 container(s) [source: deploy/base/instance/deployment.yaml:1]
- **observed**: Service payload-processing targets payload-processing with 1 port(s) [source: deploy/base/instance/service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **dependency-signal**: crypto-build-signal targets OpenSSL: Build file references OpenSSL; presence does not establish that application TLS uses a FIPS-validated provider [source: Containerfile, Dockerfile.konflux]
- **dependency-signal**: crypto-provider targets aws-lc-rs: Cargo.lock selects this cryptographic provider; FIPS validation depends on build and runtime configuration [source: Cargo.lock:220]
- **dependency-signal**: crypto-provider targets openssl: Cargo.lock selects this cryptographic provider; FIPS validation depends on build and runtime configuration [source: Cargo.lock:2375]
- **dependency-signal**: crypto-provider targets ring: Cargo.lock selects ring as a cryptographic provider; ring is not a FIPS-validated provider [source: Cargo.lock:3445]
- **not-extracted**: fips-posture targets FIPS validation: FIPS validation and runtime provider selection are not fully determined by static dependency/build signals [source: Cargo.lock:3445]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

# Analyzer Synthesis Context: llm-d-deployer

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (observed)**: 1 ingress facts extracted [source: quickstart/grafana/instance-w-prom-ds/route.yaml:1]
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authorization

- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `quickstart/grafana/instance-w-prom-ds/rbac.yaml`:2 (view, view-grafana)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `quickstart/grafana/instance-w-prom-ds/rbac.yaml`:21 (cluster-monitoring-view, cluster-monitoring-view-grafana)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `quickstart/grafana/instance-w-prom-ds/rbac.yaml`:39 (openshift-cluster-monitoring-view, openshift-cluster-monitoring-view-grafana)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `quickstart/grafana/instance-w-prom-ds/rbac.yaml`:55 (grafana-prometheus-reader)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `quickstart/grafana/instance-w-prom-ds/rbac.yaml`:69 (grafana-prometheus-reader, grafana-prometheus-reader-binding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence


## Cross-Cutting Evidence

### deployment_topology

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:deployment_topology]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: Route grafana-route serves host  via TLS; backend=grafana-service; transport=HTTPS [source: quickstart/grafana/instance-w-prom-ds/route.yaml:1]
### security

- **observed**: RBAC role grafana-prometheus-reader grants 1 rule(s) [source: quickstart/grafana/instance-w-prom-ds/rbac.yaml:55]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

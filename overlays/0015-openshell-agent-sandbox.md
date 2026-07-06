---
id: "0015"
title: OpenShell is the agent security platform for RHOAI, replacing Kagenti
status: active
created: 2026-07-06
affects:
  - platform
  - openshell
release:
  - "3.5"
  - "3.6"
  - "next"
provenance:
  - https://github.com/NVIDIA/OpenShell
  - https://redhat.atlassian.net/browse/RHAISTRAT-2114
  - https://redhat.atlassian.net/browse/RHAIRFE-2500
author: Roland Huss
superseded_by: null
---

## Fact

**OpenShell** is the agent security runtime for RHOAI, replacing Kagenti. The upstream project lives in `NVIDIA/OpenShell` with contributions from NVIDIA, Red Hat, Docker, GitHub, SAP, Google, Dell, and Canonical. Midstream forks will live in `opendatahub-io`. The upstream-first policy applies: changes go upstream before being pulled into midstream.

OpenShell provides kernel-level agent sandboxing, OPA-based policy enforcement, OCSF security event generation, inference routing with credential injection, and SPIFFE-based workload identity. It operates at the OS/kernel layer using Landlock LSM, seccomp filters, and network namespace isolation to constrain agent execution environments.

### Sandbox Model

Users create and manage sandboxes through the OpenShell CLI and SDK. The CLI provides imperative commands for sandbox lifecycle management (create, start, stop, destroy). The SDK enables programmatic integration into agent frameworks.

For RHOAI, the Kubernetes provider is the target runtime backend. Sandboxes run as pods with kernel-level isolation enforced within the container through Landlock and seccomp profiles. No separate VMs or nested containers are required. This approach works within OpenShift's existing security model (SCCs, pod security standards) without requiring privileged node access.

The sandbox specification defines the isolation boundary: allowed filesystem paths, permitted network destinations, system call allowlist, resource limits, and environment variable injection.

### OPA Policy Enforcement

OpenShell's OPA policy engine enforces network access control at L4 (TCP connection-level, allow/deny by destination IP/port) and L7 (HTTP request-level, allow/deny by URL path, method, headers). Policies are defined in Rego and loaded at sandbox creation time. Hot-reload support allows policy updates without restarting the sandbox.

### OCSF Security Events

OpenShell generates security events conforming to OCSF v1.7 for four event categories: network activity, HTTP activity, process activity, and filesystem activity. Events are designed for consumption by enterprise SIEM systems (Splunk, QRadar, Sentinel).

### Workload Identity (SPIFFE)

OpenShell supports SPIFFE-based workload identity at the core level. The token exchange mechanism (consuming SPIFFE SVIDs for outbound authentication) is implemented in the core runtime. Identity provisioning (who gives the sandbox its SPIFFE identity) is driver-specific:

- **Kubernetes driver**: SPIRE integration for X.509 SVID provisioning
- **Docker driver**: Gateway-issued JWTs or local certificate generation
- **VM driver**: Cloud attestation mechanisms

### Inference Routing

OpenShell includes inference routing with provider profiles. Provider profiles define endpoint URLs, authentication credentials, rate limits, and model selections. Credential injection mounts provider API keys or tokens into the sandbox environment without exposing them to agent code.

### OpenShell Operator (3.6 Target)

An OpenShell operator for Kubernetes lifecycle management is targeted for RHOAI 3.6 (Tech Preview). CRD design is under active discussion in the community. The operator will manage sandbox lifecycle declaratively. For 3.5 Dev Preview, CLI/SDK is the primary interface.

### Relationship to Former Kagenti Components

Kagenti (operator, AgentRuntime CRD, AuthBridge sidecar) has been consolidated into OpenShell. The capabilities that Kagenti provided are now delivered through OpenShell's architecture:

- **Sidecar-based auth (AuthBridge)** is replaced by OpenShell's supervisor-based approach with integrated credential injection and SPIFFE identity
- **AgentRuntime CRD** is replaced by OpenShell sandbox specifications (CLI/SDK for 3.5, operator CRDs for 3.6)
- **OPA policy enforcement (AuthBridge bundle-service)** is replaced by OpenShell's integrated OPA engine operating at both network and kernel layers

## Impact on Strategies

- **Agent platform strategies MUST target OpenShell**, not Kagenti. There is no AgentRuntime CRD, AuthBridge sidecar, or kagenti-operator to reference. These are deprecated.
- **Sandbox isolation strategies** reference OpenShell CLI/SDK for Dev Preview (3.5), OpenShell operator for Tech Preview/GA (3.6+).
- **Identity strategies** reference OpenShell's SPIFFE token exchange at the core level. Driver-specific identity provisioning (SPIRE on K8s, certgen on Docker) is handled by the respective OpenShell driver, not by an external operator.
- **Policy enforcement strategies** reference OpenShell's integrated OPA engine. There is no separate bundle-service or policy CRD controller. Policies are loaded per-sandbox via Rego files.
- **Build/release strategies** reference the NVIDIA/OpenShell upstream repo and opendatahub-io midstream fork. Konflux pipelines produce signed UBI9-based container images.
- **DSC integration**: OpenShell will be enabled as a component in the DataScienceCluster CR, following the standard RHOAI component controller pattern.
- **Do NOT reference overlay 0014** (Kagenti). It is superseded by this overlay.

## Context

Kagenti was the agent platform for RHOAI through the 3.5 early access period. The consolidation into OpenShell (tracked via RHAISTRAT-1599, now closed) moved all agent security capabilities into the upstream OpenShell project. This overlay replaces overlay 0014 and provides the current architectural context for strategy generation.

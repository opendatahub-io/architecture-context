---
id: "0014"
title: Kagenti agent operator manages agent workloads on RHOAI via AgentRuntime CRD
status: active
created: 2026-06-15
affects:
  - platform
  - kagenti-operator
release:
  - "3.5"
  - "next"
provenance:
  - https://github.com/kagenti/kagenti-operator
  - https://github.com/kagenti/kagenti
  - https://github.com/kagenti/kagenti-extensions
  - https://github.com/opendatahub-io/kagenti-operator
author: Roland Huss
superseded_by: null
---

## Fact

**Kagenti** is the agent platform for RHOAI. The two repositories relevant for midstream/downstream strategies are: **kagenti-operator** (Go, controller-runtime) and **kagenti-extensions** (AuthBridge sidecar proxy). The upstream **kagenti** repo (FastAPI backend, React UI, Helm charts) is used for upstream development and demos but is not directly part of the midstream/downstream product. The operator manages agent workloads through the **AgentRuntime** custom resource (`agent.kagenti.dev/v1alpha1`). There is no separate "agent lifecycle controller" or "AIAgent" CRD. AgentRuntime is the single CRD that handles agent registration, discovery, sidecar injection, and lifecycle management.

Upstream repos live in the `kagenti` GitHub organization. Midstream forks live in `opendatahub-io` (e.g., `opendatahub-io/kagenti-operator`). The upstream-first policy means significant changes go upstream before being pulled into midstream.

### AgentRuntime CRD

The AgentRuntime CR references an existing Deployment or StatefulSet via `spec.targetRef`. Key spec fields:

- `type`: agent or tool
- `targetRef`: reference to the workload (Deployment, StatefulSet)
- `authBridgeMode`: proxy-sidecar (default), envoy-sidecar, lite, or waypoint
- `mtlsMode`: disabled, permissive, or strict
- `skills`: list of OCI image references for skill injection
- `identity.spiffe.trustDomain`: SPIFFE trust domain for workload identity

The operator watches AgentRuntime CRs and applies the `kagenti.io/type: agent` label to the target workload, triggering sidecar injection via the mutating webhook.

### Webhook and sidecar injection

The operator includes a **mutating admission webhook** (`/mutate-workloads-authbridge`) that intercepts Pod creation for workloads labeled `kagenti.io/type: agent`. The webhook injects:

- **AuthBridge proxy sidecar**: transparent HTTP proxy handling JWT validation, RFC 8693 token exchange, and protocol-aware parsing (A2A, MCP, inference). Three variants: authbridge-proxy (full), authbridge-envoy (Envoy + ext_proc), authbridge-lite (auth-only).
- **SPIFFE helper**: fetches X.509 SVIDs from the SPIRE agent for workload identity and mTLS.
- **proxy-init** (envoy mode only): init container that configures iptables for transparent traffic interception.
- **Keycloak credentials**: mounts operator-managed OAuth2 client credentials Secret at `/shared/`.

The webhook is idempotent and supports reinvocation. Sidecar mode is resolved from: AgentRuntime CR, namespace-level ConfigMap (`authbridge-runtime-config`), then cluster defaults.

### Controllers

The operator runs six controllers:

1. **AgentRuntimeReconciler**: applies labels to target workload, computes config hash, triggers rolling updates on config change.
2. **AgentCardSyncReconciler**: auto-creates AgentCard CRs for labeled workloads that expose protocol labels (`protocol.kagenti.io/a2a`). Card discovery is enabled by default.
3. **AgentCardReconciler**: fetches agent metadata from the workload's `/.well-known/agent.json` endpoint via mTLS (verified fetch enabled by default). The AgentCard flow is evolving: JWS signature verification is being deprecated in favor of mTLS-based transport security (see kagenti/kagenti-operator#408).
4. **AgentCardNetworkPolicyReconciler**: creates permissive NetworkPolicies for verified agents, restrictive policies otherwise.
5. **MLflowReconciler**: auto-discovers MLflow instances, creates per-agent experiments, injects tracking env vars.
6. **ClientRegistrationController**: manages OAuth2 client registration with Keycloak for sidecar credentials.

### AuthBridge (kagenti-extensions)

AuthBridge is a Go-based sidecar proxy providing zero-trust authentication for agent workloads without application code changes. Core capabilities:

- Inbound JWT validation (JWKS-based, issuer/audience checks)
- Outbound RFC 8693 token exchange (workload credentials to target-scoped tokens)
- SPIFFE/SPIRE integration for workload identity
- Transparent operation via HTTP_PROXY env vars (proxy-sidecar mode) or iptables (envoy-sidecar mode)

AuthBridge is NOT part of rhods-operator. It is built and maintained in `kagenti/kagenti-extensions`.

### Backend and UI

The upstream kagenti repo contains a stateless FastAPI backend and a React UI for development and demos. These are NOT part of the midstream/downstream product. For RHOAI, agent discovery and management views are being built by the RHOAI dashboard team as part of the existing ODH Dashboard (AAA page), not as a separate kagenti UI.

### Namespace conventions

- `kagenti-system`: platform control plane (UI, backend, operator, gateways)
- `team1`, `team2`, ...: per-team agent workload namespaces
- `keycloak`: identity provider
- The operator watches all namespaces for AgentRuntime CRs.

### Agent Runtime Contract (ARC)

The ARC is a planned extension to the operator (RHAIRFE-2389) that formalizes the bidirectional contract between platform and agent. The platform injects capabilities (identity, proxy, MCP endpoints, model access, tracing, skills, credentials) into agent Pods via environment variables and mounted files. Agents must route traffic through `HTTP_PROXY` and forward bearer tokens for On-Behalf-Of flows. The contract materializes as an AGENTS.md file (conforming to the [AGENTS.md open standard](https://agents.md/)) and a companion `mcpServers.json` discovery file mounted at `/arc/`.

## Impact on Strategies

- **Agent lifecycle strategies MUST target kagenti-operator**, not rhods-operator. The kagenti-operator already manages agent registration, discovery, sidecar injection, and lifecycle via the AgentRuntime CRD. Do NOT propose new CRDs (e.g., "AIAgent") or new controllers for agent lifecycle.
- **AgentRuntime is the single CRD** for agent workload management. It references existing Deployments/StatefulSets via `spec.targetRef`. Strategies should not propose alternative registration mechanisms.
- **Sidecar injection is handled by the operator's mutating webhook**, not by a separate init container or volume projection pattern. The webhook fires on Pod creation for workloads labeled `kagenti.io/type: agent`.
- **AuthBridge is the mTLS proxy sidecar**, built in kagenti-extensions. It is NOT part of rhods-operator or kube-rbac-proxy. Strategies involving agent authentication should reference AuthBridge, not kube-rbac-proxy.
- **The upstream kagenti backend/UI is not part of the midstream product**. For RHOAI, agent views are built into the ODH Dashboard by the dashboard team. Strategies should not reference the kagenti React UI or FastAPI backend as RHOAI components.
- **Upstream-first policy**: changes go to `kagenti/*` repos first, then are pulled into `opendatahub-io/*` midstream forks.
- **DSC integration**: kagenti-operator is enabled as a component in the DataScienceCluster CR, following the standard RHOAI component controller pattern.
- **Agent Runtime Contract (ARC)**: strategies involving agent configuration injection (env vars, mount paths, credentials, MCP discovery) should reference the ARC spec and the kagenti-operator as the implementation target, not rhods-operator.
- **Metadata extraction**: agent capability metadata is fetched from the workload's `/.well-known/agent.json` endpoint by the AgentCardReconciler in kagenti-operator.
- **OGX is unrelated to agent workloads**: OGX (formerly Llama Stack) is an inference API server with pluggable providers. It is NOT an agent framework, agent operator, or agent runtime. OGX components (`ogx-k8s-operator`, `ogx-distribution`, etc.) manage model serving deployments, not agent workloads. Agent-related strategies MUST NOT reference OGX components, load OGX architecture context files, or include OGX in affected components, out-of-scope sections, or supporting documentation. If overlay 0003 (OGX rename) matches during context loading, exclude OGX component files from agent-scoped strategies.

## Context

The generated architecture context (all releases through 3.5-ea.1) contains zero references to Kagenti, AgentRuntime, AuthBridge, or any agent-related components. The `platforms.yaml` component registry does not include kagenti repos. This caused the strat-creator pipeline to generate strategies for agent-related RFEs (RHAISTRAT-1952, 1955, 1956) that propose new CRDs and controllers for functionality that already exists in the Kagenti ecosystem. This overlay provides the missing architectural context until Kagenti is added to the platform's component discovery via `platforms.yaml`.

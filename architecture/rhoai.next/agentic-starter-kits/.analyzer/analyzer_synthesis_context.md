# Analyzer Synthesis Context: agentic-starter-kits

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 9 http_endpoints facts extracted [source: agents/autogen/templates/mcp_agent/main.py:312, agents/autogen/templates/mcp_agent/main.py:425, agents/autogen/templates/mcp_agent/main.py:454, agents/autogen/templates/mcp_agent/main.py:460, agents/crewai/templates/websearch_agent/main.py:395, agents/crewai/templates/websearch_agent/main.py:400, agents/crewai/templates/websearch_agent/playground/app.py:40, agents/crewai/templates/websearch_agent/playground/app.py:50, agents/langgraph/templates/react_agent/main.py:267]
- **services (observed)**: 2 services facts extracted [source: agents/autogen/templates/mcp_agent/main.py:454, agents/openclaw/deployment/manifests/05-service.yaml:1]
- **ingress (observed)**: 1 ingress facts extracted [source: agents/openclaw/deployment/manifests/06-route.yaml:1]
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `agents/langgraph/templates/agentic_rag/main.py`:193 (Bearer token, HTTP API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `agents/openclaw/deployment/manifests/04-deployment.yaml`:1 (:18789/, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `agents/a2a/templates/langgraph_crewai_agent/Dockerfile`:46 (agents/a2a/templates/langgraph_crewai_agent/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `agents/autogen/templates/mcp_agent/Dockerfile`:49 (agents/autogen/templates/mcp_agent/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `agents/autogen/templates/mcp_agent/mcp_automl_template/Dockerfile`:43 (agents/autogen/templates/mcp_agent/mcp_automl_template/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `agents/crewai/templates/websearch_agent/Dockerfile`:52 (agents/crewai/templates/websearch_agent/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `agents/google/templates/adk/Dockerfile`:43 (agents/google/templates/adk/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `agents/langgraph/examples/ci_failure_summarizer/Dockerfile`:43 (agents/langgraph/examples/ci_failure_summarizer/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `agents/langgraph/examples/guardrailed_agent/Dockerfile`:49 (agents/langgraph/examples/guardrailed_agent/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `agents/langgraph/templates/agentic_rag/Dockerfile`:50 (agents/langgraph/templates/agentic_rag/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `agents/langgraph/templates/human_in_the_loop/Dockerfile`:45 (agents/langgraph/templates/human_in_the_loop/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `agents/langgraph/templates/react_agent/Dockerfile`:47 (agents/langgraph/templates/react_agent/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `agents/langgraph/templates/react_with_database_memory/Dockerfile`:45 (agents/langgraph/templates/react_with_database_memory/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `agents/llamaindex/templates/websearch_agent/Dockerfile`:43 (agents/llamaindex/templates/websearch_agent/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `agents/autogen/templates/mcp_agent/main.py`:312 (/chat/completions, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `agents/autogen/templates/mcp_agent/main.py`:425 (/health, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `agents/autogen/templates/mcp_agent/main.py`:454 (/, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `agents/autogen/templates/mcp_agent/main.py`:460 (/images/{filename:path}, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `agents/crewai/templates/websearch_agent/main.py`:395 (/api/health, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `agents/crewai/templates/websearch_agent/main.py`:400 (/api/chat, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `agents/crewai/templates/websearch_agent/playground/app.py`:40 (/images/<path:filename>, Unknown)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `agents/crewai/templates/websearch_agent/playground/app.py`:50 (/, Unknown)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `agents/langgraph/templates/react_agent/main.py`:267 (/v1/chat/completions, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `agents/autogen/templates/mcp_agent/main.py`:454 (agent-auth)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `agents/openclaw/deployment/manifests/04-deployment.yaml`:1 (openclaw)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `agents/openclaw/deployment/manifests/05-service.yaml`:1 (openclaw)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :18789/ methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: agents/openclaw/deployment/manifests/04-deployment.yaml:1]
- HTTP API methods=All mechanism=Bearer token enforcement=ASGI middleware (SATokenAuthMiddleware) policy=Source-defined authentication [source: agents/langgraph/templates/agentic_rag/main.py:193]
### http_endpoints

- GET / on port ; transport= encryption=Configurable auth=Unknown owner= [source: agents/autogen/templates/mcp_agent/main.py:454]
- GET /api/health on port ; transport= encryption=Configurable auth=Unknown owner= [source: agents/crewai/templates/websearch_agent/main.py:395]
- GET /health on port ; transport= encryption=Configurable auth=Unknown owner= [source: agents/autogen/templates/mcp_agent/main.py:425]
- GET /images/{filename:path} on port ; transport= encryption=Configurable auth=Unknown owner= [source: agents/autogen/templates/mcp_agent/main.py:460]
- POST /api/chat on port ; transport= encryption=Configurable auth=Unknown owner= [source: agents/crewai/templates/websearch_agent/main.py:400]
- POST /chat/completions on port ; transport= encryption=Configurable auth=Unknown owner= [source: agents/autogen/templates/mcp_agent/main.py:312]
- POST /v1/chat/completions on port ; transport= encryption=Configurable auth=Unknown owner= [source: agents/langgraph/templates/react_agent/main.py:267]
- Unknown / on port ; transport= encryption=Configurable auth=Unknown owner= [source: agents/crewai/templates/websearch_agent/playground/app.py:50]
- Unknown /images/<path:filename> on port ; transport= encryption=Configurable auth=Unknown owner= [source: agents/crewai/templates/websearch_agent/playground/app.py:40]
### services

- openclaw port=18789 target=18789 protocol=TCP encryption= auth= [source: agents/openclaw/deployment/manifests/05-service.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload openclaw uses service account  and 1 container(s) [source: agents/openclaw/deployment/manifests/04-deployment.yaml:1]
- **observed**: Service agent-auth targets  with 0 port(s) [source: agents/autogen/templates/mcp_agent/main.py:454]
- **observed**: Service openclaw targets openclaw with 1 port(s) [source: agents/openclaw/deployment/manifests/05-service.yaml:1]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: Route openclaw serves host  via TLS; backend=openclaw; transport=HTTPS [source: agents/openclaw/deployment/manifests/06-route.yaml:1]
### security

- **observed**: All HTTP API uses Bearer token at ASGI middleware (SATokenAuthMiddleware); policy=Source-defined authentication [source: agents/langgraph/templates/agentic_rag/main.py:193]
- **observed**: GET :18789/ uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: agents/openclaw/deployment/manifests/04-deployment.yaml:1]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: components/auth/pyproject.toml:7]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

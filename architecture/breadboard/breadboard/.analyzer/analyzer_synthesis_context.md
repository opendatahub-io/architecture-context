# Analyzer Synthesis Context: breadboard

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 44 http_endpoints facts extracted [source: deploy/golang-reverse-proxy/main.go:232, deploy/golang-reverse-proxy/main.go:233, src/dashboard/webapp.py:1077, src/dashboard/webapp.py:1152, src/dashboard/webapp.py:1173, src/dashboard/webapp.py:1196, src/dashboard/webapp.py:1219, src/dashboard/webapp.py:1242, src/dashboard/webapp.py:1277, src/dashboard/webapp.py:1339, src/dashboard/webapp.py:1379, src/dashboard/webapp.py:1403, src/dashboard/webapp.py:1458, src/dashboard/webapp.py:1532, src/dashboard/webapp.py:309, src/dashboard/webapp.py:313, src/dashboard/webapp.py:562, src/dashboard/webapp.py:589, src/dashboard/webapp.py:596, src/dashboard/webapp.py:603, src/dashboard/webapp.py:607, src/dashboard/webapp.py:611, src/dashboard/webapp.py:615, src/dashboard/webapp.py:623, src/dashboard/webapp.py:627, src/dashboard/webapp.py:631, src/dashboard/webapp.py:636, src/dashboard/webapp.py:661, src/dashboard/webapp.py:665, src/dashboard/webapp.py:669, src/dashboard/webapp.py:684, src/dashboard/webapp.py:700, src/dashboard/webapp.py:710, src/dashboard/webapp.py:725, src/dashboard/webapp.py:729, src/dashboard/webapp.py:733, src/dashboard/webapp.py:745, src/dashboard/webapp.py:778, src/dashboard/webapp.py:821, src/dashboard/webapp.py:849, src/dashboard/webapp.py:931, src/fullsend-dashboard/app.py:285, src/fullsend-dashboard/app.py:289, src/fullsend-dashboard/app.py:293]
- **services (observed)**: 22 services facts extracted [source: deploy/claude-agent/deployment.yaml:3, deploy/golang-reverse-proxy/deployment.yaml:3, deploy/k8s/04-traefik-ingress.yaml:43, deploy/k8s/06-backend-services.yaml:21, deploy/k8s/06-backend-services.yaml:38, deploy/k8s/06-backend-services.yaml:4, deploy/k8s/13-mlflow.yaml:3, deploy/k8s/15-markovd.yaml:166, deploy/k8s/15-markovd.yaml:67, deploy/k8s/18-observatory.yaml:33, deploy/k8s/19-gitlab-emulator.yaml:22, deploy/k8s/24-fullsend-mint-dev.yaml:117, deploy/k8s/26-fullsend-dashboard.yaml:36, deploy/k8s/28-org-pulse.yaml:157, deploy/k8s/28-org-pulse.yaml:269, deploy/k8s/28-org-pulse.yaml:375, deploy/k8s/29-model-relay.yaml:46, deploy/k8s/29-model-relay.yaml:65, deploy/k8s/test-clusterip-services.yaml:25, deploy/k8s/test-clusterip-services.yaml:4, deploy/k8s/test-clusterip-services.yaml:50, src/fullsend-dashboard/app.py:285]
- **ingress (observed)**: 15 ingress facts extracted [source: deploy/k8s/05-ingress-routes.yaml:32, deploy/k8s/05-ingress-routes.yaml:4, deploy/k8s/05-ingress-routes.yaml:60, deploy/k8s/05-ingress-routes.yaml:87, deploy/k8s/08-ingress-https.yaml:125, deploy/k8s/08-ingress-https.yaml:163, deploy/k8s/08-ingress-https.yaml:201, deploy/k8s/08-ingress-https.yaml:239, deploy/k8s/08-ingress-https.yaml:278, deploy/k8s/08-ingress-https.yaml:3, deploy/k8s/08-ingress-https.yaml:45, deploy/k8s/08-ingress-https.yaml:87, deploy/k8s/15-markovd.yaml:29, deploy/k8s/test-simple-ingress.yaml:22, deploy/k8s/test-simple-ingress.yaml:3]
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `deploy/golang-reverse-proxy/deployment.yaml`:25 (:80/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `deploy/k8s/18-observatory.yaml`:67 (:8000/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `deploy/k8s/20-pipeline-dashboard.yaml`:21 (:5000/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `deploy/k8s/28-org-pulse.yaml`:288 (:3001/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `deploy/k8s/28-org-pulse.yaml`:394 (:8080/healthz, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `src/fullsend-dashboard/app.py`:285 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### authorization

- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deploy/k8s/04-traefik-ingress.yaml`:15 (traefik)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `deploy/k8s/04-traefik-ingress.yaml`:30 (traefik)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deploy/k8s/16-pipeline-rbac.yaml`:17 (pipeline-orchestrator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `deploy/k8s/16-pipeline-rbac.yaml`:51 (pipeline-orchestrator, pipeline-orchestrator-binding)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deploy/k8s/21-gitlab-runner.yaml`:17 (gitlab-runner)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `deploy/k8s/21-gitlab-runner.yaml`:27 (gitlab-runner)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `deploy/k8s/26-fullsend-dashboard.yaml`:23 (fullsend-dashboard-readonly)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which controller, handler, or service account exercises this RBAC policy?
  **Expected signal:** role rules, binding subject, handler, or controller identity
  **Candidate:** `deploy/k8s/26-fullsend-dashboard.yaml`:8 (fullsend-dashboard-readonly)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `deploy/k8s/openshell-gateway-sandbox-rbac.yaml`:4 (openshell-gateway-sandbox, openshell-sandbox)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/claude-agent/Dockerfile`:37 (deploy/claude-agent/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/claude-agent/Dockerfile`:40 (deploy/claude-agent/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/dashboard/Dockerfile`:50 (deploy/dashboard/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/fullsend-dashboard/Dockerfile`:13 (deploy/fullsend-dashboard/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/fullsend-mint-dev/Dockerfile`:11 (deploy/fullsend-mint-dev/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/golang-reverse-proxy/Dockerfile`:31 (deploy/golang-reverse-proxy/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/golang-reverse-proxy/main.go`:228 (reverse-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/pipeline-agent/Dockerfile`:106 (deploy/pipeline-agent/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `var/demos/fullsend-entrypoint-poc/openshell-smoke/register-runner.py`:4 (Literal outbound HTTP endpoint, gitlab.local)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `var/demos/fullsend-entrypoint-poc/podman-smoke/register-runner.py`:4 (127.0.0.1, Literal outbound HTTP endpoint)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `deploy/golang-reverse-proxy/main.go`:232 (/healthz, Unknown, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `deploy/golang-reverse-proxy/main.go`:233 (/, Unknown, main)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/dashboard/webapp.py`:1277 (/api/evals/submit, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/dashboard/webapp.py`:1339 (/api/evals, Unknown)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/dashboard/webapp.py`:1403 (/api/files/list, Unknown)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/dashboard/webapp.py`:1458 (/api/files/read, Unknown)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/dashboard/webapp.py`:1532 (/api/files/raw, Unknown)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/dashboard/webapp.py`:313 (/, Unknown)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/dashboard/webapp.py`:611 (/admin, Unknown)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/dashboard/webapp.py`:733 (/api/events/push, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/dashboard/webapp.py`:745 (/api/events, Unknown)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/fullsend-dashboard/app.py`:285 (/, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `var/demos/fullsend-entrypoint-poc/openshell-smoke/register-runner.py`:4 (HTTP client, gitlab.local)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `var/demos/fullsend-entrypoint-poc/podman-smoke/register-runner.py`:4 (127.0.0.1, HTTP client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### internal_dependencies

- **Question:** Where is this internal dependency invoked and what is the interaction boundary?
  **Expected signal:** import, client call, queue, or controller handoff
  **Candidate:** `src/dashboard/fullsend_onboarding.py`:520 (Kubernetes API, Python client library)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/claude-agent/deployment.yaml`:3 (claude-agent)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/golang-reverse-proxy/deployment.yaml`:3 (ingress-proxy)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/k8s/04-traefik-ingress.yaml`:43 (traefik)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/k8s/06-backend-services.yaml`:21 (gitlab-emulator, gitlab-emulator-backend)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/k8s/06-backend-services.yaml`:38 (jira-emulator, jira-emulator-backend)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/k8s/06-backend-services.yaml`:4 (github-emulator, github-emulator-backend)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/k8s/13-mlflow.yaml`:3 (mlflow)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/k8s/15-markovd.yaml`:166 (markovd-postgres)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/k8s/15-markovd.yaml`:67 (markovd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/k8s/18-observatory.yaml`:33 (observatory)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/k8s/test-clusterip-services.yaml`:25 (jira-emulator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/k8s/test-clusterip-services.yaml`:4 (github-emulator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- :3001/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/k8s/28-org-pulse.yaml:288]
- :5000/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/k8s/20-pipeline-dashboard.yaml:21]
- :80/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/golang-reverse-proxy/deployment.yaml:25]
- :8000/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/k8s/18-observatory.yaml:67]
- :8080/healthz methods=GET mechanism=None enforcement=N/A policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/k8s/28-org-pulse.yaml:394]
- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: src/fullsend-dashboard/app.py:285]
### http_endpoints

- DELETE /api/jobs/<job_name> on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:1219]
- DELETE /api/jobs/all on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:1242]
- GET / on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/fullsend-dashboard/app.py:285]
- GET /api/state on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/fullsend-dashboard/app.py:293]
- GET /healthz on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/fullsend-dashboard/app.py:289]
- POST /api/evals/submit on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:1277]
- POST /api/events/push on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:733]
- POST /api/fullsend/onboard on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:778]
- POST /api/jobs/<job_name>/stop on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:1196]
- POST /api/jobs/submit on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:931]
- POST /api/mlflow/clear on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:700]
- POST /api/mlflow/hard-clear on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:710]
- POST /api/observatory/clear on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:1379]
- POST /api/volumes/clear on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:849]
- POST /api/workspace/reset on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:821]
- Unknown / on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:313]
- Unknown / on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: deploy/golang-reverse-proxy/main.go:233]
- Unknown /admin on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:611]
- Unknown /api/evals on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:1339]
- Unknown /api/events on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:745]
- Unknown /api/files/list on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:1403]
- Unknown /api/files/raw on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:1532]
- Unknown /api/files/read on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:1458]
- Unknown /api/issues on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:631]
- Unknown /api/jobs on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:1077]
- Unknown /api/jobs/<job_name> on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:1152]
- Unknown /api/jobs/<job_name>/logs on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:1173]
- Unknown /api/mlflow/runs on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:669]
- Unknown /api/mlflow/traces on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:684]
- Unknown /api/pipeline/queue on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:729]
- Unknown /api/pipeline/status on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:725]
- Unknown /api/rfes on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:661]
- Unknown /api/strategies on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:665]
- Unknown /api/tickets on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:636]
- Unknown /evals on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:623]
- Unknown /files on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:627]
- Unknown /healthz on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:309]
- Unknown /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=main [source: deploy/golang-reverse-proxy/main.go:232]
- Unknown /issue/<key> on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:562]
- Unknown /jobs on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/dashboard/webapp.py:615]
### integrations

- 127.0.0.1 interaction=HTTP client role=runtime-integration protocol=HTTP purpose=Literal outbound HTTP endpoint [source: var/demos/fullsend-entrypoint-poc/podman-smoke/register-runner.py:4]
- gitlab.local interaction=HTTP client role=runtime-integration protocol=HTTPS purpose=Literal outbound HTTP endpoint [source: var/demos/fullsend-entrypoint-poc/openshell-smoke/register-runner.py:4]
### internal_dependencies

- Kubernetes API interaction=Python client library role=runtime-integration purpose=Kubernetes resource operations via Python SDK [source: src/dashboard/fullsend_onboarding.py:520]
### services

- claude-agent port=8080 target=8080 protocol=TCP encryption= auth= [source: deploy/claude-agent/deployment.yaml:3]
- fullsend-dashboard port=5000 target=5000 protocol=TCP encryption= auth= [source: deploy/k8s/26-fullsend-dashboard.yaml:36]
- fullsend-mint-dev port=8080 target=http protocol=TCP encryption= auth= [source: deploy/k8s/24-fullsend-mint-dev.yaml:117]
- github-emulator port=443 target=443 protocol=TCP encryption= auth= [source: deploy/k8s/test-clusterip-services.yaml:4]
- github-emulator port=80 target=80 protocol=TCP encryption= auth= [source: deploy/k8s/test-clusterip-services.yaml:4]
- github-emulator-backend port=8000 target=8000 protocol=TCP encryption= auth= [source: deploy/k8s/06-backend-services.yaml:4]
- gitlab-emulator port=443 target=443 protocol=TCP encryption= auth= [source: deploy/k8s/19-gitlab-emulator.yaml:22]
- gitlab-emulator port=80 target=80 protocol=TCP encryption= auth= [source: deploy/k8s/19-gitlab-emulator.yaml:22]
- gitlab-emulator-backend port=8000 target=8000 protocol=TCP encryption= auth= [source: deploy/k8s/06-backend-services.yaml:21]
- ingress-proxy port=443 target=443 protocol=TCP encryption= auth= [source: deploy/golang-reverse-proxy/deployment.yaml:3]
- ingress-proxy port=80 target=80 protocol=TCP encryption= auth= [source: deploy/golang-reverse-proxy/deployment.yaml:3]
- jira-emulator port=443 target=443 protocol=TCP encryption= auth= [source: deploy/k8s/test-clusterip-services.yaml:25]
- jira-emulator port=80 target=80 protocol=TCP encryption= auth= [source: deploy/k8s/test-clusterip-services.yaml:25]
- jira-emulator port=8081 target=8081 protocol=TCP encryption= auth= [source: deploy/k8s/test-clusterip-services.yaml:25]
- jira-emulator-backend port=8080 target=8080 protocol=TCP encryption= auth= [source: deploy/k8s/06-backend-services.yaml:38]
- jira-emulator-backend port=8081 target=8081 protocol=TCP encryption= auth= [source: deploy/k8s/06-backend-services.yaml:38]
- markovd port=8080 target=8081 protocol=TCP encryption= auth= [source: deploy/k8s/15-markovd.yaml:67]
- markovd-postgres port=5432 target=5432 protocol=TCP encryption= auth= [source: deploy/k8s/15-markovd.yaml:166]
- mlflow port=5000 target=5000 protocol=TCP encryption= auth= [source: deploy/k8s/13-mlflow.yaml:3]
- model-relay port=8080 target=8080 protocol=TCP encryption= auth= [source: deploy/k8s/29-model-relay.yaml:46]
- model-relay port=8082 target=8082 protocol=TCP encryption= auth= [source: deploy/k8s/29-model-relay.yaml:46]
- model-relay-admin port=8081 target=8081 protocol=TCP encryption= auth= [source: deploy/k8s/29-model-relay.yaml:65]
- observatory port=8000 target=8000 protocol=TCP encryption= auth= [source: deploy/k8s/18-observatory.yaml:33]
- org-pulse-backend port=3001 target=3001 protocol=TCP encryption= auth= [source: deploy/k8s/28-org-pulse.yaml:269]
- org-pulse-frontend port=8080 target=8080 protocol=TCP encryption= auth= [source: deploy/k8s/28-org-pulse.yaml:375]
- org-pulse-mongodb port=27017 target=27017 protocol=TCP encryption= auth= [source: deploy/k8s/28-org-pulse.yaml:157]
- pipeline-dashboard port=5000 target=5000 protocol=TCP encryption= auth= [source: deploy/k8s/test-clusterip-services.yaml:50]
- traefik port=443 target=443 protocol=TCP encryption= auth= [source: deploy/k8s/04-traefik-ingress.yaml:43]
- traefik port=80 target=80 protocol=TCP encryption= auth= [source: deploy/k8s/04-traefik-ingress.yaml:43]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload claude-agent uses service account  and 1 container(s) [source: deploy/claude-agent/deployment.yaml:21]
- **observed**: Deployment workload fullsend-dashboard uses service account fullsend-dashboard and 1 container(s) [source: deploy/k8s/26-fullsend-dashboard.yaml:51]
- **observed**: Deployment workload fullsend-mint-dev uses service account  and 1 container(s) [source: deploy/k8s/24-fullsend-mint-dev.yaml:1]
- **observed**: Deployment workload github-actions-runner uses service account  and 1 container(s) [source: deploy/k8s/23-github-actions-runner.yaml:1]
- **observed**: Deployment workload github-actions-site-runner uses service account  and 1 container(s) [source: deploy/k8s/23c-github-actions-site-runner.yaml:10]
- **observed**: Deployment workload github-emulator uses service account  and 1 container(s) [source: deploy/k8s/10-github-emulator.yaml:25]
- **observed**: Deployment workload gitlab-emulator uses service account  and 1 container(s) [source: deploy/k8s/19-gitlab-emulator.yaml:60]
- **observed**: Deployment workload ingress-proxy uses service account  and 1 container(s) [source: deploy/golang-reverse-proxy/deployment.yaml:25]
- **observed**: Deployment workload jira-emulator uses service account  and 1 container(s) [source: deploy/k8s/12-jira-emulator.yaml:29]
- **observed**: Deployment workload markovd uses service account markovd and 2 container(s) [source: deploy/k8s/15-markovd.yaml:214]
- **observed**: Deployment workload markovd-postgres uses service account  and 1 container(s) [source: deploy/k8s/15-markovd.yaml:115]
- **observed**: Deployment workload mlflow uses service account  and 1 container(s) [source: deploy/k8s/13-mlflow.yaml:35]
- **observed**: Deployment workload model-relay uses service account  and 1 container(s) [source: deploy/k8s/29-model-relay.yaml:80]
- **observed**: Deployment workload observatory uses service account  and 1 container(s) [source: deploy/k8s/18-observatory.yaml:67]
- **observed**: Deployment workload openshell-m2-gitlab-runner uses service account gitlab-runner and 1 container(s) [source: var/demos/fullsend-entrypoint-poc/openshell-smoke/gitlab-runner-template.yaml:39]
- **observed**: Deployment workload org-pulse-backend uses service account  and 1 container(s) [source: deploy/k8s/28-org-pulse.yaml:288]
- **observed**: Deployment workload org-pulse-frontend uses service account  and 1 container(s) [source: deploy/k8s/28-org-pulse.yaml:394]
- **observed**: Deployment workload org-pulse-mongodb uses service account  and 1 container(s) [source: deploy/k8s/28-org-pulse.yaml:176]
- **observed**: Deployment workload pipeline-dashboard uses service account pipeline-dashboard and 1 container(s) [source: deploy/k8s/20-pipeline-dashboard.yaml:21]
- **observed**: Deployment workload podman-m1-gitlab-runner uses service account gitlab-runner and 1 container(s) [source: var/demos/fullsend-entrypoint-poc/podman-smoke/gitlab-runner-template.yaml:31]
- **observed**: Deployment workload traefik uses service account traefik and 1 container(s) [source: deploy/k8s/07-traefik-config.yaml:18]
- **observed**: Service claude-agent targets claude-agent with 1 port(s) [source: deploy/claude-agent/deployment.yaml:3]
- **observed**: Service github-emulator targets github-emulator with 2 port(s) [source: deploy/k8s/test-clusterip-services.yaml:4]
- **observed**: Service github-emulator-backend targets github-emulator with 1 port(s) [source: deploy/k8s/06-backend-services.yaml:4]
- **observed**: Service gitlab-emulator-backend targets gitlab-emulator with 1 port(s) [source: deploy/k8s/06-backend-services.yaml:21]
- **observed**: Service ingress-proxy targets ingress-proxy with 2 port(s) [source: deploy/golang-reverse-proxy/deployment.yaml:3]
- **observed**: Service jira-emulator targets jira-emulator with 3 port(s) [source: deploy/k8s/test-clusterip-services.yaml:25]
- **observed**: Service jira-emulator-backend targets jira-emulator with 2 port(s) [source: deploy/k8s/06-backend-services.yaml:38]
- **observed**: Service markovd targets markovd with 1 port(s) [source: deploy/k8s/15-markovd.yaml:67]
- **observed**: Service markovd-postgres targets markovd-postgres with 1 port(s) [source: deploy/k8s/15-markovd.yaml:166]
- **observed**: Service mlflow targets mlflow with 1 port(s) [source: deploy/k8s/13-mlflow.yaml:3]
- **observed**: Service traefik targets traefik with 2 port(s) [source: deploy/k8s/04-traefik-ingress.yaml:43]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP Unknown / is owned by main [source: deploy/golang-reverse-proxy/main.go:233]
- **observed**: HTTP Unknown /healthz is owned by main [source: deploy/golang-reverse-proxy/main.go:232]
- **observed**: Ingress dashboard-https serves host dashboard.ai-pipeline.svc.cluster.local via TLS; backend=pipeline-dashboard; transport=HTTPS [source: deploy/k8s/08-ingress-https.yaml:87]
- **observed**: Ingress fullsend-dashboard-https serves host fullsend-dashboard.ai-pipeline.svc.cluster.local via TLS; backend=fullsend-dashboard; transport=HTTPS [source: deploy/k8s/08-ingress-https.yaml:125]
- **observed**: Ingress github-emulator serves host github-emulator.ai-pipeline.svc.cluster.local via TLS; backend=github-emulator-backend; transport=HTTPS [source: deploy/k8s/05-ingress-routes.yaml:4]
- **observed**: Ingress github-emulator-https serves host github-emulator.ai-pipeline.svc.cluster.local via TLS; backend=github-emulator; transport=HTTPS [source: deploy/k8s/08-ingress-https.yaml:3]
- **observed**: Ingress github-simple serves host github.local via plaintext; backend=github-emulator; transport=HTTP [source: deploy/k8s/test-simple-ingress.yaml:22]
- **observed**: Ingress gitlab-emulator serves host gitlab-emulator.ai-pipeline.svc.cluster.local via TLS; backend=gitlab-emulator-backend; transport=HTTPS [source: deploy/k8s/05-ingress-routes.yaml:32]
- **observed**: Ingress jira-emulator serves host jira-emulator.ai-pipeline.svc.cluster.local via TLS; backend=jira-emulator-backend; transport=HTTPS [source: deploy/k8s/05-ingress-routes.yaml:60]
- **observed**: Ingress jira-emulator-https serves host jira-emulator.ai-pipeline.svc.cluster.local via TLS; backend=jira-emulator; transport=HTTPS [source: deploy/k8s/08-ingress-https.yaml:45]
- **observed**: Ingress jira-simple serves host jira.local via plaintext; backend=jira-emulator; transport=HTTP [source: deploy/k8s/test-simple-ingress.yaml:3]
- **observed**: Ingress markovd serves host markovd.ai-pipeline.svc.cluster.local via TLS; backend=markovd; transport=HTTPS [source: deploy/k8s/15-markovd.yaml:29]
- **observed**: Ingress markovd-https serves host markovd.ai-pipeline.svc.cluster.local via TLS; backend=markovd; transport=HTTPS [source: deploy/k8s/08-ingress-https.yaml:163]
- **observed**: Ingress model-relay-https serves host model-relay.ai-pipeline.svc.cluster.local via TLS; backend=model-relay; transport=HTTPS [source: deploy/k8s/08-ingress-https.yaml:278]
- **observed**: Ingress observatory-https serves host observatory.ai-pipeline.svc.cluster.local via TLS; backend=observatory; transport=HTTPS [source: deploy/k8s/08-ingress-https.yaml:201]
- **observed**: Ingress org-pulse-https serves host org-pulse-frontend.ai-pipeline.svc.cluster.local via TLS; backend=org-pulse-frontend; transport=HTTPS [source: deploy/k8s/08-ingress-https.yaml:239]
- **observed**: Ingress pipeline-dashboard serves host dashboard.ai-pipeline.svc.cluster.local via TLS; backend=pipeline-dashboard; transport=HTTPS [source: deploy/k8s/05-ingress-routes.yaml:87]
### security

- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: src/fullsend-dashboard/app.py:285]
- **observed**: GET :3001/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/k8s/28-org-pulse.yaml:288]
- **observed**: GET :5000/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/k8s/20-pipeline-dashboard.yaml:21]
- **observed**: GET :80/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/golang-reverse-proxy/deployment.yaml:25]
- **observed**: GET :8000/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/k8s/18-observatory.yaml:67]
- **observed**: GET :8080/healthz uses None at N/A; policy=Unauthenticated Kubernetes liveness probe endpoint [source: deploy/k8s/28-org-pulse.yaml:394]
- **observed**: RBAC role fullsend-dashboard-readonly grants 3 rule(s) [source: deploy/k8s/26-fullsend-dashboard.yaml:8]
- **observed**: RBAC role gitlab-runner grants 1 rule(s) [source: deploy/k8s/21-gitlab-runner.yaml:17]
- **observed**: RBAC role pipeline-orchestrator grants 7 rule(s) [source: deploy/k8s/16-pipeline-rbac.yaml:17]
- **observed**: RBAC role traefik grants 3 rule(s) [source: deploy/k8s/04-traefik-ingress.yaml:15]
- **dependency-signal**: auth-middleware targets pyjwt: JWT/OAuth authentication library dependency [source: pyproject.toml:17]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: pyproject.toml:13]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: deploy/golang-reverse-proxy/main.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

# Platform Architecture — breadboard

## Metadata

- Components analyzed: 5/5
- Complete: true
- Components: breadboard, jira-emulator, github-emulator, gitlab-emulator, entra-id-emulator

## Platform Overview

Breadboard is a resettable, self-contained AI-native software engineering platform deployed on local K3s in the ai-pipeline namespace. Its core repository combines a Python CLI/pipeline agent for bug, RFE, and strategy phases with a Flask dashboard (~40 routes including SSE, job submission, and evals) and a read-only FastAPI Fullsend dashboard. Around this core it integrates ~21 emulated and supporting services: Jira, GitHub, and GitLab emulators, an Entra ID (Azure AD) OIDC emulator, the markovd workflow engine with Postgres, Observatory and MLflow telemetry, Model Relay (Vertex/Anthropic gateway), Org Pulse with MongoDB, Fullsend Mint (OIDC-to-GitHub credential exchange), and CI runners. Traefik, cert-manager, and a Go reverse proxy expose everything as *.local HTTPS hosts, letting tooling be developed and tested end-to-end with zero dependency on production SaaS services.

## Component Relationships

### Internal Dependencies

- breadboard -> ai-pipeline Kubernetes namespace
- breadboard -> traefik ingress
- breadboard -> cert-manager
- breadboard -> jira-emulator
- breadboard -> github-emulator
- breadboard -> gitlab-emulator
- breadboard -> model-relay

### Central Components

- **breadboard**

### Integration Patterns

- **hub-and-spoke orchestration**: Breadboard dashboard and CLI drive all emulators; emulators expose wire-compatible APIs (Jira REST v2/v3, GitHub REST/GraphQL/Actions, GitLab API v4) so standard clients work unchanged.
- **emulator-as-substitute**: jira-emulator, github-emulator, gitlab-emulator, and entra-id-emulator replace production Jira, GitHub, GitLab, and Entra ID for offline development, testing, and CI.
- **MCP tool exposure**: jira-emulator runs a FastMCP server on port 8081 exposing ~14 Jira tools for Claude agents.
- **gateway-mediated LLM inference**: All agent inference flows through Model Relay, which fronts Vertex/Anthropic with managed upstream accounts and usage telemetry.
- **CI runner coordination**: GitLab Runner (v19.1.1, Kubernetes executor) registers against gitlab-emulator and executes CI jobs; github-emulator dispatches Actions jobs to runner containers via /_apis pools.
- **OIDC credential exchange**: Fullsend Mint exchanges GitHub Actions OIDC assertions for scoped GitHub credentials used in the OpenShell sandbox runner flow.
- **telemetry aggregation**: Observatory and MLflow collect traces, artifacts, and experiment data that dashboards query.
- **workflow orchestration**: markovd executes declarative workflows from var/markov-workflows, persisting state in Postgres and dispatching Kubernetes jobs.

## Network Architecture

Traefik terminates TLS on ports 80/443; a Go ingress-proxy routes *.local hostnames (dashboard.local, github.local, gitlab.local, jira.local, markovd.local, observatory.local, orgpulse.local, relay.local, fullsend.local) to backends. Cluster-internal HTTPS ingresses on *.ai-pipeline.svc.cluster.local hosts front github-emulator-backend, gitlab-emulator-backend, jira-emulator-backend, pipeline-dashboard, fullsend-dashboard, markovd, observatory, org-pulse-frontend, and model-relay. Simple non-TLS ingresses map jira.local to jira-emulator and github.local to github-emulator. Breadboard exposes 22 services (dashboard 5000, emulators on 80/443/8080/8081/8000, markovd 8080, Postgres 5432, MLflow 5000, relay 8080/8082, Org Pulse 3001/8080/27017, Mint 8080). Egress is limited to Vertex/Anthropic via Model Relay, gitlab.local runner registration, and optional production Jira.

### Analyzer-Detected Service Wiring

| Ingress | Host | Paths | Backend | TLS |
|----|----|----|----|----|
| github-emulator | github-emulator.ai-pipeline.svc.cluster.local | / | github-emulator-backend | true |
| gitlab-emulator | gitlab-emulator.ai-pipeline.svc.cluster.local | / | gitlab-emulator-backend | true |
| jira-emulator | jira-emulator.ai-pipeline.svc.cluster.local | / | jira-emulator-backend | true |
| pipeline-dashboard | dashboard.ai-pipeline.svc.cluster.local | / | pipeline-dashboard | true |
| github-emulator-https | github-emulator.ai-pipeline.svc.cluster.local | / | github-emulator | true |
| jira-emulator-https | jira-emulator.ai-pipeline.svc.cluster.local | / | jira-emulator | true |
| dashboard-https | dashboard.ai-pipeline.svc.cluster.local | / | pipeline-dashboard | true |
| fullsend-dashboard-https | fullsend-dashboard.ai-pipeline.svc.cluster.local | / | fullsend-dashboard | true |
| markovd-https | markovd.ai-pipeline.svc.cluster.local | / | markovd | true |
| observatory-https | observatory.ai-pipeline.svc.cluster.local | / | observatory | true |
| org-pulse-https | org-pulse-frontend.ai-pipeline.svc.cluster.local | / | org-pulse-frontend | true |
| model-relay-https | model-relay.ai-pipeline.svc.cluster.local | / | model-relay | true |
| markovd | markovd.ai-pipeline.svc.cluster.local | / | markovd | true |
| jira-simple | jira.local | / | jira-emulator | false |
| github-simple | github.local | / | github-emulator | false |

## Platform Security

Security relies primarily on the local-only network boundary rather than application-layer auth. Breadboard dashboards lack auth middleware on HTTP APIs, including destructive endpoints (job deletion, workspace reset, volume clear); healthz probes are unauthenticated. Emulators implement their own token/session auth (Bearer/PAT, Basic, JWT, OIDC) but ship insecure defaults: jira-emulator defaults to permissive AUTH_MODE, github-emulator seeds admin/admin credentials, gitlab-emulator ships a default JWT secret, and entra-id-emulator has a default admin password. Kubernetes RBAC roles bound to service accounts (pipeline-orchestrator, traefik, gitlab-runner, fullsend-dashboard-readonly, openshell-gateway-sandbox) control in-cluster access. Secrets supply GCP credentials, emulator tokens, and TLS material; signing keys and secrets stored unencrypted in SQLite within emulators.

## Data Flows

- **pipeline execution**: CLI phases fetch issues from Jira/GitHub/GitLab emulators, run Claude agents via Model Relay, validate YAML artifacts against schemas with retry, and stream SSE events to the dashboard.
- **ticket aggregation**: Dashboard queries all three emulators, paginates issues/PRs/MRs, combines results, and filters closed/merged items by default.
- **fullsend agent flow**: GitHub Actions in a triage-target repo obtains an OIDC token from github-emulator, exchanges it at Fullsend Mint for scoped GitHub credentials, runs agent work in an OpenShell sandbox runner, observed by fullsend-dashboard.
- **job submission and CI**: Dashboard submits Kubernetes Jobs via the python client; GitLab Runner polls gitlab-emulator for CI jobs, executes them with the Kubernetes executor, and uses MinIO S3 cache.
- **markov workflow orchestration**: markovd executes declarative workflows, persists run state in markovd-postgres, and dispatches jobs.
- **telemetry collection**: Observatory collects traces and artifacts, extracts and verifies claims, reports quality; MLflow stores agent traces and experiment data queried by dashboards.
- **model inference**: Agents call Model Relay at relay-api.local, which forwards to Vertex/Anthropic with managed upstream accounts and usage telemetry.
- **authentication emulation**: entra-id-emulator issues signed JWT ID/access/refresh tokens via tenant-scoped OIDC endpoints (authorize, token, JWKS) for relying parties like oauth2-proxy and ODH BYO-IDC.

## Deployment Topology

Breadboard deploys roughly 29 Kubernetes workloads (21 Deployments, 22 Services) into a local K3s cluster in the ai-pipeline namespace, fronted by Traefik v2.11, cert-manager, and a Go ingress-proxy. Emulators run as containers managed by supervisord (jira-emulator API 8080 + MCP 8081; github-emulator uvicorn; gitlab-emulator uvicorn behind in-container Caddy TLS with SSH 2222; entra-id-emulator single Flask process). Persistence uses SQLite (emulators), Postgres (markovd), and MongoDB (Org Pulse); MinIO optionally backs runner cache. All emulators also support standalone Docker/compose/k3s deployment for tests outside the platform. The stack is designed as a resettable local environment, not production.

## Cross-Cutting Concerns

- No application-layer authentication on dashboard APIs; destructive endpoints rely solely on local network boundary
- Insecure default credentials across emulators (admin/admin, default tokens, default JWT secret, permissive AUTH_MODE) unsafe beyond test environments
- Credentials (GCP, GitHub tokens) mounted into multiple workloads from secrets; .env handling required to avoid committing credentials
- Unauthenticated healthz endpoints across services widen surface if exposed
- SQLite-backed emulators limit concurrency and horizontal scalability; no HA or supply-chain controls
- Test/manifest duplication (test-clusterip-services, test-simple-ingress) alongside production manifests risks drift
- Very large emulated endpoint surfaces (381 GitHub, 552 GitLab routes) increase drift risk versus real APIs
- Remote CI includes and Git import in gitlab-emulator create outbound network calls gated only by a host allowlist
- CRDs, gRPC services, and webhooks not verified by analyzer coverage; operator-style extensions may exist unobserved
- gitlab-emulator retains github_emulator scaffolding; many GitLab-specific semantics remain incomplete per STATUS.md

## Analyzer Inventory

| Component | Endpoints | Services | Deployments | Entrypoints |
|----|----|----|----|----|
| breadboard | 44 | 22 | 21 | 8 |
| jira-emulator | 113 | 1 | 0 | 5 |
| github-emulator | 381 | 1 | 0 | 7 |
| gitlab-emulator | 552 | 1 | 0 | 3 |
| entra-id-emulator | 26 | 1 | 0 | 1 |


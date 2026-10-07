# Analyzer Synthesis Context: openshell-dashboard

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 65 http_endpoints facts extracted [source: backend/pkg/server/app.go:100, backend/pkg/server/app.go:103, backend/pkg/server/app.go:104, backend/pkg/server/app.go:105, backend/pkg/server/app.go:106, backend/pkg/server/app.go:109, backend/pkg/server/app.go:110, backend/pkg/server/app.go:112, backend/pkg/server/app.go:113, backend/pkg/server/app.go:115, backend/pkg/server/app.go:116, backend/pkg/server/app.go:117, backend/pkg/server/app.go:119, backend/pkg/server/app.go:120, backend/pkg/server/app.go:121, backend/pkg/server/app.go:122, backend/pkg/server/app.go:124, backend/pkg/server/app.go:125, backend/pkg/server/app.go:126, backend/pkg/server/app.go:127, backend/pkg/server/app.go:128, backend/pkg/server/app.go:129, backend/pkg/server/app.go:130, backend/pkg/server/app.go:131, backend/pkg/server/app.go:132, backend/pkg/server/app.go:133, backend/pkg/server/app.go:134, backend/pkg/server/app.go:135, backend/pkg/server/app.go:136, backend/pkg/server/app.go:137, backend/pkg/server/app.go:138, backend/pkg/server/app.go:139, backend/pkg/server/app.go:140, backend/pkg/server/app.go:141, backend/pkg/server/app.go:142, backend/pkg/server/app.go:143, backend/pkg/server/app.go:144, backend/pkg/server/app.go:145, backend/pkg/server/app.go:146, backend/pkg/server/app.go:147, backend/pkg/server/app.go:149, backend/pkg/server/app.go:150, backend/pkg/server/app.go:151, backend/pkg/server/app.go:153, backend/pkg/server/app.go:154, backend/pkg/server/app.go:155, backend/pkg/server/app.go:156, backend/pkg/server/app.go:157, backend/pkg/server/app.go:158, backend/pkg/server/app.go:159, backend/pkg/server/app.go:160, backend/pkg/server/app.go:161, backend/pkg/server/app.go:163, backend/pkg/server/app.go:164, backend/pkg/server/app.go:165, backend/pkg/server/app.go:166, backend/pkg/server/app.go:167, backend/pkg/server/app.go:168, backend/pkg/server/app.go:86, backend/pkg/server/app.go:88, backend/pkg/server/app.go:89, backend/pkg/server/app.go:94, backend/pkg/server/app.go:95, backend/pkg/server/app.go:96, backend/pkg/server/app.go:99]
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/cmd/server/main.go`:40 (server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/Dockerfile`:29 (deploy/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/Dockerfile.konflux`:66 (deploy/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:100 (/, PUT, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:106 (/global-policy, DELETE, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:109 (/, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:110 (/, POST, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:112 (/, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:113 (/, DELETE, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:86 (/auth/config, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:88 (/healthz, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:94 (/auth/whoami, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:95 (/gateway, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:96 (/draft-summary, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:99 (/, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### http_endpoints

- DELETE / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:113]
- DELETE /global-policy on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:106]
- DELETE /members/{subject} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:117]
- DELETE /provider-profiles/{profileId} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:168]
- DELETE /providers/{name} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:157]
- DELETE /providers/{name}/refresh on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:161]
- GET / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:109]
- GET / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:99]
- GET / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:112]
- GET /auth/config on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:86]
- GET /auth/whoami on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:94]
- GET /draft-summary on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:96]
- GET /gateway on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:95]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:88]
- GET /members on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:115]
- GET /provider-profiles on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:163]
- GET /provider-profiles/{profileId} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:166]
- GET /providers on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:153]
- GET /providers/{name} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:155]
- GET /providers/{name}/refresh-status on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:158]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:89]
- GET /sandboxes/{name}/drafts on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:138]
- GET /sandboxes/{name}/drafts/history on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:145]
- POST / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:110]
- POST /members on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:116]
- POST /provider-profiles on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:164]
- POST /provider-profiles/lint on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:165]
- POST /providers on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:154]
- POST /providers/{name}/refresh on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:159]
- POST /providers/{name}/refresh/rotate on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:160]
- POST /sandboxes/from-template on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:126]
- POST /sandboxes/{name}/drafts/approve-all on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:141]
- POST /sandboxes/{name}/drafts/clear on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:144]
- POST /sandboxes/{name}/drafts/{chunk}/approve on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:139]
- POST /sandboxes/{name}/drafts/{chunk}/reject on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:140]
- POST /sandboxes/{name}/drafts/{chunk}/undo on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:143]
- PUT / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:100]
- PUT /provider-profiles/{profileId} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:167]
- PUT /providers/{name} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:156]
- PUT /sandboxes/{name}/drafts/{chunk} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:142]

## Cross-Cutting Evidence

### deployment_topology

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:deployment_topology]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP DELETE / is owned by pkg/server [source: backend/pkg/server/app.go:113]
- **observed**: HTTP DELETE /global-policy is owned by pkg/server [source: backend/pkg/server/app.go:106]
- **observed**: HTTP DELETE /members/{subject} is owned by pkg/server [source: backend/pkg/server/app.go:117]
- **observed**: HTTP DELETE /provider-profiles/{profileId} is owned by pkg/server [source: backend/pkg/server/app.go:168]
- **observed**: HTTP DELETE /providers/{name} is owned by pkg/server [source: backend/pkg/server/app.go:157]
- **observed**: HTTP DELETE /providers/{name}/refresh is owned by pkg/server [source: backend/pkg/server/app.go:161]
- **observed**: HTTP GET / is owned by pkg/server [source: backend/pkg/server/app.go:109]
- **observed**: HTTP GET /auth/config is owned by pkg/server [source: backend/pkg/server/app.go:86]
- **observed**: HTTP GET /auth/whoami is owned by pkg/server [source: backend/pkg/server/app.go:94]
- **observed**: HTTP GET /draft-summary is owned by pkg/server [source: backend/pkg/server/app.go:96]
- **observed**: HTTP GET /gateway is owned by pkg/server [source: backend/pkg/server/app.go:95]
- **observed**: HTTP GET /healthz is owned by pkg/server [source: backend/pkg/server/app.go:88]
- **observed**: HTTP GET /members is owned by pkg/server [source: backend/pkg/server/app.go:115]
- **observed**: HTTP GET /provider-profiles is owned by pkg/server [source: backend/pkg/server/app.go:163]
- **observed**: HTTP GET /provider-profiles/{profileId} is owned by pkg/server [source: backend/pkg/server/app.go:166]
- **observed**: HTTP GET /providers is owned by pkg/server [source: backend/pkg/server/app.go:153]
- **observed**: HTTP GET /providers/{name} is owned by pkg/server [source: backend/pkg/server/app.go:155]
- **observed**: HTTP GET /providers/{name}/refresh-status is owned by pkg/server [source: backend/pkg/server/app.go:158]
- **observed**: HTTP GET /readyz is owned by pkg/server [source: backend/pkg/server/app.go:89]
- **observed**: HTTP POST / is owned by pkg/server [source: backend/pkg/server/app.go:110]
- **observed**: HTTP POST /members is owned by pkg/server [source: backend/pkg/server/app.go:116]
- **observed**: HTTP POST /provider-profiles is owned by pkg/server [source: backend/pkg/server/app.go:164]
- **observed**: HTTP POST /provider-profiles/lint is owned by pkg/server [source: backend/pkg/server/app.go:165]
- **observed**: HTTP POST /providers is owned by pkg/server [source: backend/pkg/server/app.go:154]
- **observed**: HTTP POST /providers/{name}/refresh is owned by pkg/server [source: backend/pkg/server/app.go:159]
- **observed**: HTTP POST /providers/{name}/refresh/rotate is owned by pkg/server [source: backend/pkg/server/app.go:160]
- **observed**: HTTP POST /sandboxes/from-template is owned by pkg/server [source: backend/pkg/server/app.go:126]
- **observed**: HTTP POST /sandboxes/{name}/drafts/approve-all is owned by pkg/server [source: backend/pkg/server/app.go:141]
- **observed**: HTTP POST /sandboxes/{name}/drafts/clear is owned by pkg/server [source: backend/pkg/server/app.go:144]
- **observed**: HTTP PUT / is owned by pkg/server [source: backend/pkg/server/app.go:100]
- **observed**: HTTP PUT /provider-profiles/{profileId} is owned by pkg/server [source: backend/pkg/server/app.go:167]
- **observed**: HTTP PUT /providers/{name} is owned by pkg/server [source: backend/pkg/server/app.go:156]
### security

- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: backend/cmd/server/inbound_tls.go, backend/pkg/clients/rawexec.go]
- **dependency-signal**: tls-config targets google.golang.org/grpc/credentials: TLS configuration import [source: backend/pkg/clients/rawexec.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

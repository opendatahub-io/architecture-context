# Analyzer Synthesis Context: openshell-dashboard

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 86 http_endpoints facts extracted [source: backend/pkg/server/app.go:147, backend/pkg/server/app.go:149, backend/pkg/server/app.go:150, backend/pkg/server/app.go:155, backend/pkg/server/app.go:156, backend/pkg/server/app.go:159, backend/pkg/server/app.go:162, backend/pkg/server/app.go:165, backend/pkg/server/app.go:166, backend/pkg/server/app.go:167, backend/pkg/server/app.go:170, backend/pkg/server/app.go:171, backend/pkg/server/app.go:172, backend/pkg/server/app.go:173, backend/pkg/server/app.go:177, backend/pkg/server/app.go:178, backend/pkg/server/app.go:179, backend/pkg/server/app.go:180, backend/pkg/server/app.go:187, backend/pkg/server/app.go:188, backend/pkg/server/app.go:189, backend/pkg/server/app.go:190, backend/pkg/server/app.go:191, backend/pkg/server/app.go:192, backend/pkg/server/app.go:195, backend/pkg/server/app.go:196, backend/pkg/server/app.go:198, backend/pkg/server/app.go:199, backend/pkg/server/app.go:201, backend/pkg/server/app.go:202, backend/pkg/server/app.go:203, backend/pkg/server/app.go:205, backend/pkg/server/app.go:206, backend/pkg/server/app.go:207, backend/pkg/server/app.go:208, backend/pkg/server/app.go:210, backend/pkg/server/app.go:212, backend/pkg/server/app.go:213, backend/pkg/server/app.go:214, backend/pkg/server/app.go:215, backend/pkg/server/app.go:216, backend/pkg/server/app.go:217, backend/pkg/server/app.go:218, backend/pkg/server/app.go:219, backend/pkg/server/app.go:220, backend/pkg/server/app.go:221, backend/pkg/server/app.go:222, backend/pkg/server/app.go:223, backend/pkg/server/app.go:224, backend/pkg/server/app.go:225, backend/pkg/server/app.go:226, backend/pkg/server/app.go:227, backend/pkg/server/app.go:228, backend/pkg/server/app.go:229, backend/pkg/server/app.go:230, backend/pkg/server/app.go:231, backend/pkg/server/app.go:232, backend/pkg/server/app.go:233, backend/pkg/server/app.go:234, backend/pkg/server/app.go:235, backend/pkg/server/app.go:236, backend/pkg/server/app.go:237, backend/pkg/server/app.go:238, backend/pkg/server/app.go:239, backend/pkg/server/app.go:240, backend/pkg/server/app.go:241, backend/pkg/server/app.go:243, backend/pkg/server/app.go:244, backend/pkg/server/app.go:245, backend/pkg/server/app.go:247, backend/pkg/server/app.go:249, backend/pkg/server/app.go:251, backend/pkg/server/app.go:252, backend/pkg/server/app.go:253, backend/pkg/server/app.go:254, backend/pkg/server/app.go:255, backend/pkg/server/app.go:256, backend/pkg/server/app.go:257, backend/pkg/server/app.go:258, backend/pkg/server/app.go:259, backend/pkg/server/app.go:261, backend/pkg/server/app.go:262, backend/pkg/server/app.go:263, backend/pkg/server/app.go:264, backend/pkg/server/app.go:265, backend/pkg/server/app.go:266]
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (not-verified)**: 0 ingress facts extracted; absence is not proven by the available coverage
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
  **Candidate:** `deploy/Dockerfile`:56 (deploy/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/Dockerfile.konflux`:66 (deploy/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:147 (/auth/config, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:155 (/auth/whoami, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:156 (/gateway, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:159 (/gateway/compatibility, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:162 (/draft-summary, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:165 (/, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:166 (/, PUT, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:195 (/, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:196 (/, POST, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:198 (/, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:199 (/, DELETE, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:210 (/draft-summary, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### http_endpoints

- DELETE / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:199]
- DELETE /global-policy on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:173]
- DELETE /members/{subject} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:203]
- DELETE /provider-profiles/{profileId} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:192]
- DELETE /provider-profiles/{profileId} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:266]
- DELETE /providers/{name} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:255]
- DELETE /providers/{name}/refresh on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:259]
- GET / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:165]
- GET / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:198]
- GET / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:195]
- GET /auth/config on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:147]
- GET /auth/whoami on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:155]
- GET /draft-summary on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:210]
- GET /draft-summary on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:162]
- GET /gateway on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:156]
- GET /gateway/compatibility on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:159]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:149]
- GET /members on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:201]
- GET /provider-profiles on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:187]
- GET /provider-profiles on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:261]
- GET /provider-profiles/{profileId} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:264]
- GET /provider-profiles/{profileId} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:190]
- GET /providers on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:251]
- GET /providers on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:178]
- GET /providers/{name} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:253]
- GET /providers/{name}/refresh-status on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:256]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:150]
- POST / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:196]
- POST /members on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:202]
- POST /provider-profiles on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:262]
- POST /provider-profiles on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:188]
- POST /provider-profiles/lint on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:189]
- POST /provider-profiles/lint on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:263]
- POST /providers on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:252]
- POST /providers/{name}/refresh on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:257]
- POST /providers/{name}/refresh/rotate on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:258]
- PUT / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:166]
- PUT /provider-profiles/{profileId} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:265]
- PUT /provider-profiles/{profileId} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:191]
- PUT /providers/{name} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:254]

## Cross-Cutting Evidence

### deployment_topology

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:deployment_topology]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP DELETE / is owned by pkg/server [source: backend/pkg/server/app.go:199]
- **observed**: HTTP DELETE /global-policy is owned by pkg/server [source: backend/pkg/server/app.go:173]
- **observed**: HTTP DELETE /members/{subject} is owned by pkg/server [source: backend/pkg/server/app.go:203]
- **observed**: HTTP DELETE /provider-profiles/{profileId} is owned by pkg/server [source: backend/pkg/server/app.go:192]
- **observed**: HTTP DELETE /providers/{name} is owned by pkg/server [source: backend/pkg/server/app.go:255]
- **observed**: HTTP DELETE /providers/{name}/refresh is owned by pkg/server [source: backend/pkg/server/app.go:259]
- **observed**: HTTP GET / is owned by pkg/server [source: backend/pkg/server/app.go:165]
- **observed**: HTTP GET /auth/config is owned by pkg/server [source: backend/pkg/server/app.go:147]
- **observed**: HTTP GET /auth/whoami is owned by pkg/server [source: backend/pkg/server/app.go:155]
- **observed**: HTTP GET /draft-summary is owned by pkg/server [source: backend/pkg/server/app.go:162]
- **observed**: HTTP GET /gateway is owned by pkg/server [source: backend/pkg/server/app.go:156]
- **observed**: HTTP GET /gateway/compatibility is owned by pkg/server [source: backend/pkg/server/app.go:159]
- **observed**: HTTP GET /healthz is owned by pkg/server [source: backend/pkg/server/app.go:149]
- **observed**: HTTP GET /members is owned by pkg/server [source: backend/pkg/server/app.go:201]
- **observed**: HTTP GET /provider-profiles is owned by pkg/server [source: backend/pkg/server/app.go:187]
- **observed**: HTTP GET /provider-profiles/{profileId} is owned by pkg/server [source: backend/pkg/server/app.go:264]
- **observed**: HTTP GET /providers is owned by pkg/server [source: backend/pkg/server/app.go:178]
- **observed**: HTTP GET /providers/{name} is owned by pkg/server [source: backend/pkg/server/app.go:253]
- **observed**: HTTP GET /providers/{name}/refresh-status is owned by pkg/server [source: backend/pkg/server/app.go:256]
- **observed**: HTTP GET /readyz is owned by pkg/server [source: backend/pkg/server/app.go:150]
- **observed**: HTTP GET /revisions/{version} is owned by pkg/server [source: backend/pkg/server/app.go:167]
- **observed**: HTTP POST / is owned by pkg/server [source: backend/pkg/server/app.go:196]
- **observed**: HTTP POST /members is owned by pkg/server [source: backend/pkg/server/app.go:202]
- **observed**: HTTP POST /provider-profiles is owned by pkg/server [source: backend/pkg/server/app.go:188]
- **observed**: HTTP POST /provider-profiles/lint is owned by pkg/server [source: backend/pkg/server/app.go:263]
- **observed**: HTTP POST /providers is owned by pkg/server [source: backend/pkg/server/app.go:252]
- **observed**: HTTP POST /providers/{name}/refresh is owned by pkg/server [source: backend/pkg/server/app.go:257]
- **observed**: HTTP POST /providers/{name}/refresh/rotate is owned by pkg/server [source: backend/pkg/server/app.go:258]
- **observed**: HTTP POST /sandboxes/from-template is owned by pkg/server [source: backend/pkg/server/app.go:214]
- **observed**: HTTP PUT / is owned by pkg/server [source: backend/pkg/server/app.go:166]
- **observed**: HTTP PUT /provider-profiles/{profileId} is owned by pkg/server [source: backend/pkg/server/app.go:191]
- **observed**: HTTP PUT /providers/{name} is owned by pkg/server [source: backend/pkg/server/app.go:254]
### security

- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: backend/cmd/server/inbound_tls.go, backend/pkg/clients/rawexec.go]
- **dependency-signal**: tls-config targets google.golang.org/grpc/credentials: TLS configuration import [source: backend/pkg/clients/rawexec.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

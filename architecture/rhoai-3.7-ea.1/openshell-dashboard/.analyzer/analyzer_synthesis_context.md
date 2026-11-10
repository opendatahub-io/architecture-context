# Analyzer Synthesis Context: openshell-dashboard

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 87 http_endpoints facts extracted [source: backend/pkg/server/app.go:148, backend/pkg/server/app.go:150, backend/pkg/server/app.go:151, backend/pkg/server/app.go:156, backend/pkg/server/app.go:157, backend/pkg/server/app.go:160, backend/pkg/server/app.go:163, backend/pkg/server/app.go:166, backend/pkg/server/app.go:167, backend/pkg/server/app.go:168, backend/pkg/server/app.go:171, backend/pkg/server/app.go:172, backend/pkg/server/app.go:173, backend/pkg/server/app.go:174, backend/pkg/server/app.go:178, backend/pkg/server/app.go:179, backend/pkg/server/app.go:180, backend/pkg/server/app.go:181, backend/pkg/server/app.go:188, backend/pkg/server/app.go:189, backend/pkg/server/app.go:190, backend/pkg/server/app.go:191, backend/pkg/server/app.go:192, backend/pkg/server/app.go:193, backend/pkg/server/app.go:196, backend/pkg/server/app.go:197, backend/pkg/server/app.go:199, backend/pkg/server/app.go:200, backend/pkg/server/app.go:202, backend/pkg/server/app.go:203, backend/pkg/server/app.go:204, backend/pkg/server/app.go:206, backend/pkg/server/app.go:207, backend/pkg/server/app.go:208, backend/pkg/server/app.go:209, backend/pkg/server/app.go:211, backend/pkg/server/app.go:213, backend/pkg/server/app.go:214, backend/pkg/server/app.go:215, backend/pkg/server/app.go:216, backend/pkg/server/app.go:217, backend/pkg/server/app.go:218, backend/pkg/server/app.go:219, backend/pkg/server/app.go:220, backend/pkg/server/app.go:221, backend/pkg/server/app.go:222, backend/pkg/server/app.go:223, backend/pkg/server/app.go:224, backend/pkg/server/app.go:225, backend/pkg/server/app.go:226, backend/pkg/server/app.go:227, backend/pkg/server/app.go:228, backend/pkg/server/app.go:229, backend/pkg/server/app.go:230, backend/pkg/server/app.go:231, backend/pkg/server/app.go:232, backend/pkg/server/app.go:233, backend/pkg/server/app.go:234, backend/pkg/server/app.go:235, backend/pkg/server/app.go:236, backend/pkg/server/app.go:237, backend/pkg/server/app.go:238, backend/pkg/server/app.go:239, backend/pkg/server/app.go:240, backend/pkg/server/app.go:241, backend/pkg/server/app.go:242, backend/pkg/server/app.go:243, backend/pkg/server/app.go:245, backend/pkg/server/app.go:246, backend/pkg/server/app.go:247, backend/pkg/server/app.go:249, backend/pkg/server/app.go:251, backend/pkg/server/app.go:253, backend/pkg/server/app.go:254, backend/pkg/server/app.go:255, backend/pkg/server/app.go:256, backend/pkg/server/app.go:257, backend/pkg/server/app.go:258, backend/pkg/server/app.go:259, backend/pkg/server/app.go:260, backend/pkg/server/app.go:261, backend/pkg/server/app.go:263, backend/pkg/server/app.go:264, backend/pkg/server/app.go:265, backend/pkg/server/app.go:266, backend/pkg/server/app.go:267, backend/pkg/server/app.go:268]
- **services (observed)**: 1 services facts extracted [source: deploy/keycloak/dev/keycloak.yaml:72]
- **ingress (not-verified)**: 0 ingress facts extracted; absence is not proven by the available coverage
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `backend/cmd/server/main.go`:41 (server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/Dockerfile`:64 (deploy/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `deploy/Dockerfile.konflux`:66 (deploy/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:148 (/auth/config, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:156 (/auth/whoami, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:157 (/gateway, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:160 (/gateway/compatibility, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:163 (/draft-summary, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:166 (/, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:167 (/, PUT, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:196 (/, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:197 (/, POST, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:199 (/, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:200 (/, DELETE, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `backend/pkg/server/app.go`:211 (/draft-summary, GET, pkg/server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `deploy/keycloak/dev/keycloak.yaml`:12 (keycloak)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `deploy/keycloak/dev/keycloak.yaml`:72 (keycloak)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### http_endpoints

- DELETE / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:200]
- DELETE /global-policy on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:174]
- DELETE /members/{subject} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:204]
- DELETE /provider-profiles/{profileId} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:193]
- DELETE /provider-profiles/{profileId} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:268]
- DELETE /providers/{name} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:257]
- DELETE /providers/{name}/refresh on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:261]
- GET / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:166]
- GET / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:199]
- GET / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:196]
- GET /auth/config on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:148]
- GET /auth/whoami on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:156]
- GET /draft-summary on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:211]
- GET /draft-summary on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:163]
- GET /gateway on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:157]
- GET /gateway/compatibility on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:160]
- GET /healthz on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:150]
- GET /members on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:202]
- GET /provider-profiles on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:188]
- GET /provider-profiles on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:263]
- GET /provider-profiles/{profileId} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:266]
- GET /provider-profiles/{profileId} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:191]
- GET /providers on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:253]
- GET /providers on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:179]
- GET /providers/{name} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:255]
- GET /providers/{name}/refresh-status on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:258]
- GET /readyz on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:151]
- POST / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:197]
- POST /members on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:203]
- POST /provider-profiles on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:264]
- POST /provider-profiles on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:189]
- POST /provider-profiles/lint on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:190]
- POST /provider-profiles/lint on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:265]
- POST /providers on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:254]
- POST /providers/{name}/refresh on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:259]
- POST /providers/{name}/refresh/rotate on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:260]
- PUT / on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:167]
- PUT /provider-profiles/{profileId} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:267]
- PUT /provider-profiles/{profileId} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:192]
- PUT /providers/{name} on port ; transport=HTTP/1.1 encryption= auth= owner=pkg/server [source: backend/pkg/server/app.go:256]
### services

- keycloak port=8443 target=https protocol=TCP encryption= auth= [source: deploy/keycloak/dev/keycloak.yaml:72]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload keycloak uses service account  and 1 container(s) [source: deploy/keycloak/dev/keycloak.yaml:12]
- **observed**: Service keycloak targets keycloak with 1 port(s) [source: deploy/keycloak/dev/keycloak.yaml:72]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: HTTP DELETE / is owned by pkg/server [source: backend/pkg/server/app.go:200]
- **observed**: HTTP DELETE /global-policy is owned by pkg/server [source: backend/pkg/server/app.go:174]
- **observed**: HTTP DELETE /members/{subject} is owned by pkg/server [source: backend/pkg/server/app.go:204]
- **observed**: HTTP DELETE /provider-profiles/{profileId} is owned by pkg/server [source: backend/pkg/server/app.go:193]
- **observed**: HTTP DELETE /providers/{name} is owned by pkg/server [source: backend/pkg/server/app.go:257]
- **observed**: HTTP DELETE /providers/{name}/refresh is owned by pkg/server [source: backend/pkg/server/app.go:261]
- **observed**: HTTP GET / is owned by pkg/server [source: backend/pkg/server/app.go:166]
- **observed**: HTTP GET /auth/config is owned by pkg/server [source: backend/pkg/server/app.go:148]
- **observed**: HTTP GET /auth/whoami is owned by pkg/server [source: backend/pkg/server/app.go:156]
- **observed**: HTTP GET /draft-summary is owned by pkg/server [source: backend/pkg/server/app.go:163]
- **observed**: HTTP GET /gateway is owned by pkg/server [source: backend/pkg/server/app.go:157]
- **observed**: HTTP GET /gateway/compatibility is owned by pkg/server [source: backend/pkg/server/app.go:160]
- **observed**: HTTP GET /healthz is owned by pkg/server [source: backend/pkg/server/app.go:150]
- **observed**: HTTP GET /members is owned by pkg/server [source: backend/pkg/server/app.go:202]
- **observed**: HTTP GET /provider-profiles is owned by pkg/server [source: backend/pkg/server/app.go:188]
- **observed**: HTTP GET /provider-profiles/{profileId} is owned by pkg/server [source: backend/pkg/server/app.go:266]
- **observed**: HTTP GET /providers is owned by pkg/server [source: backend/pkg/server/app.go:179]
- **observed**: HTTP GET /providers/{name} is owned by pkg/server [source: backend/pkg/server/app.go:255]
- **observed**: HTTP GET /providers/{name}/refresh-status is owned by pkg/server [source: backend/pkg/server/app.go:258]
- **observed**: HTTP GET /readyz is owned by pkg/server [source: backend/pkg/server/app.go:151]
- **observed**: HTTP GET /revisions/{version} is owned by pkg/server [source: backend/pkg/server/app.go:168]
- **observed**: HTTP POST / is owned by pkg/server [source: backend/pkg/server/app.go:197]
- **observed**: HTTP POST /members is owned by pkg/server [source: backend/pkg/server/app.go:203]
- **observed**: HTTP POST /provider-profiles is owned by pkg/server [source: backend/pkg/server/app.go:189]
- **observed**: HTTP POST /provider-profiles/lint is owned by pkg/server [source: backend/pkg/server/app.go:265]
- **observed**: HTTP POST /providers is owned by pkg/server [source: backend/pkg/server/app.go:254]
- **observed**: HTTP POST /providers/{name}/refresh is owned by pkg/server [source: backend/pkg/server/app.go:259]
- **observed**: HTTP POST /providers/{name}/refresh/rotate is owned by pkg/server [source: backend/pkg/server/app.go:260]
- **observed**: HTTP POST /sandboxes/from-template is owned by pkg/server [source: backend/pkg/server/app.go:215]
- **observed**: HTTP PUT / is owned by pkg/server [source: backend/pkg/server/app.go:167]
- **observed**: HTTP PUT /provider-profiles/{profileId} is owned by pkg/server [source: backend/pkg/server/app.go:192]
- **observed**: HTTP PUT /providers/{name} is owned by pkg/server [source: backend/pkg/server/app.go:256]
### security

- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: backend/cmd/server/inbound_tls.go, backend/pkg/clients/rawexec.go]
- **dependency-signal**: tls-config targets google.golang.org/grpc/credentials: TLS configuration import [source: backend/pkg/clients/rawexec.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

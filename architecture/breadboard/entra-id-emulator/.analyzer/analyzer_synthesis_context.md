# Analyzer Synthesis Context: entra-id-emulator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 26 http_endpoints facts extracted [source: entra_mock/routes/admin_api.py:108, entra_mock/routes/admin_api.py:119, entra_mock/routes/admin_api.py:142, entra_mock/routes/admin_api.py:177, entra_mock/routes/admin_api.py:217, entra_mock/routes/admin_api.py:229, entra_mock/routes/admin_api.py:249, entra_mock/routes/admin_api.py:280, entra_mock/routes/admin_api.py:315, entra_mock/routes/admin_api.py:327, entra_mock/routes/admin_api.py:346, entra_mock/routes/admin_api.py:384, entra_mock/routes/admin_api.py:419, entra_mock/routes/admin_api.py:43, entra_mock/routes/admin_api.py:50, entra_mock/routes/admin_api.py:63, entra_mock/routes/admin_api.py:89, entra_mock/routes/authorize.py:56, entra_mock/routes/discovery.py:10, entra_mock/routes/jwks.py:11, entra_mock/routes/logout.py:16, entra_mock/routes/token.py:116, entra_mock/routes/userinfo.py:11]
- **services (observed)**: 1 services facts extracted [source: entra_mock/routes/jwks.py:11]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `entra_mock/routes/jwks.py`:11 (HTTP API, None (no auth middleware detected))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:9 (Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `entra_mock/routes/admin_api.py`:327 (/api/clients, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `entra_mock/routes/admin_api.py`:346 (/api/clients, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `entra_mock/routes/admin_api.py`:384 (/api/clients/<client_id>, PUT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `entra_mock/routes/admin_api.py`:419 (/api/clients/<client_id>, DELETE)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `entra_mock/routes/admin_api.py`:43 (/, Unknown)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `entra_mock/routes/authorize.py`:56 (/<tenant>/oauth2/v2.0/authorize, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `entra_mock/routes/authorize.py`:56 (/<tenant>/oauth2/v2.0/authorize, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `entra_mock/routes/discovery.py`:10 (/<tenant>/v2.0/.well-known/openid-configuration, Unknown)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `entra_mock/routes/jwks.py`:11 (/<tenant>/discovery/v2.0/keys, Unknown)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `entra_mock/routes/logout.py`:16 (/<tenant>/oauth2/v2.0/logout, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `entra_mock/routes/logout.py`:16 (/<tenant>/oauth2/v2.0/logout, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `entra_mock/routes/token.py`:116 (/<tenant>/oauth2/v2.0/token, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `entra_mock/routes/jwks.py`:11 (entra-id-emulator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=None (no auth middleware detected) enforcement=FastAPI/Starlette application policy=No authentication middleware registered [source: entra_mock/routes/jwks.py:11]
### http_endpoints

- DELETE /api/clients/<client_id> on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:419]
- DELETE /api/groups/<group_id> on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:315]
- DELETE /api/tenants/<tenant_id> on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:108]
- DELETE /api/users/<user_id> on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:217]
- GET /<tenant>/oauth2/v2.0/authorize on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/authorize.py:56]
- GET /<tenant>/oauth2/v2.0/logout on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/logout.py:16]
- GET /api/clients on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:327]
- GET /api/groups on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:229]
- GET /api/tenants on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:50]
- GET /api/users on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:119]
- GET /oidc/userinfo on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/userinfo.py:11]
- POST /<tenant>/oauth2/v2.0/authorize on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/authorize.py:56]
- POST /<tenant>/oauth2/v2.0/logout on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/logout.py:16]
- POST /<tenant>/oauth2/v2.0/token on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/token.py:116]
- POST /api/clients on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:346]
- POST /api/groups on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:249]
- POST /api/tenants on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:63]
- POST /api/users on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:142]
- POST /oidc/userinfo on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/userinfo.py:11]
- PUT /api/clients/<client_id> on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:384]
- PUT /api/groups/<group_id> on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:280]
- PUT /api/tenants/<tenant_id> on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:89]
- PUT /api/users/<user_id> on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:177]
- Unknown / on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/admin_api.py:43]
- Unknown /<tenant>/discovery/v2.0/keys on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/jwks.py:11]
- Unknown /<tenant>/v2.0/.well-known/openid-configuration on port ; transport= encryption=Configurable auth=Unknown owner= [source: entra_mock/routes/discovery.py:10]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service entra-id-emulator targets  with 0 port(s) [source: entra_mock/routes/jwks.py:11]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses None (no auth middleware detected) at FastAPI/Starlette application; policy=No authentication middleware registered [source: entra_mock/routes/jwks.py:11]
- **dependency-signal**: auth-middleware targets pyjwt: JWT/OAuth authentication library dependency [source: requirements.txt:2]
- **dependency-signal**: tls-config targets cryptography: TLS/cryptography library dependency [source: requirements.txt:3]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

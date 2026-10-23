# Analyzer Synthesis Context: jira-emulator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 113 http_endpoints facts extracted [source: src/jira_emulator/routers/admin.py:152, src/jira_emulator/routers/admin.py:190, src/jira_emulator/routers/admin.py:211, src/jira_emulator/routers/admin.py:224, src/jira_emulator/routers/admin.py:258, src/jira_emulator/routers/admin.py:265, src/jira_emulator/routers/admin.py:277, src/jira_emulator/routers/admin.py:288, src/jira_emulator/routers/admin.py:71, src/jira_emulator/routers/admin.py:88, src/jira_emulator/routers/attachments.py:153, src/jira_emulator/routers/attachments.py:177, src/jira_emulator/routers/attachments.py:229, src/jira_emulator/routers/attachments.py:262, src/jira_emulator/routers/attachments.py:299, src/jira_emulator/routers/attachments.py:52, src/jira_emulator/routers/auth.py:130, src/jira_emulator/routers/auth.py:186, src/jira_emulator/routers/auth.py:38, src/jira_emulator/routers/auth.py:59, src/jira_emulator/routers/auth.py:83, src/jira_emulator/routers/fields.py:225, src/jira_emulator/routers/issue_properties.py:152, src/jira_emulator/routers/issue_properties.py:37, src/jira_emulator/routers/issue_properties.py:53, src/jira_emulator/routers/issue_properties.py:77, src/jira_emulator/routers/issues.py:116, src/jira_emulator/routers/issues.py:150, src/jira_emulator/routers/issues.py:207, src/jira_emulator/routers/issues.py:253, src/jira_emulator/routers/issues.py:316, src/jira_emulator/routers/issues.py:435, src/jira_emulator/routers/issues.py:480, src/jira_emulator/routers/issues.py:523, src/jira_emulator/routers/issues.py:558, src/jira_emulator/routers/issues.py:595, src/jira_emulator/routers/issues.py:67, src/jira_emulator/routers/links.py:123, src/jira_emulator/routers/links.py:155, src/jira_emulator/routers/links.py:24, src/jira_emulator/routers/metadata.py:109, src/jira_emulator/routers/metadata.py:133, src/jira_emulator/routers/metadata.py:33, src/jira_emulator/routers/metadata.py:57, src/jira_emulator/routers/metadata.py:83, src/jira_emulator/routers/projects.py:114, src/jira_emulator/routers/projects.py:141, src/jira_emulator/routers/projects.py:205, src/jira_emulator/routers/projects.py:218, src/jira_emulator/routers/projects.py:247, src/jira_emulator/routers/projects.py:282, src/jira_emulator/routers/projects.py:317, src/jira_emulator/routers/projects.py:352, src/jira_emulator/routers/projects.py:366, src/jira_emulator/routers/projects.py:376, src/jira_emulator/routers/projects.py:423, src/jira_emulator/routers/remote_links.py:134, src/jira_emulator/routers/remote_links.py:158, src/jira_emulator/routers/remote_links.py:179, src/jira_emulator/routers/remote_links.py:193, src/jira_emulator/routers/remote_links.py:208, src/jira_emulator/routers/remote_links.py:92, src/jira_emulator/routers/search.py:24, src/jira_emulator/routers/search.py:25, src/jira_emulator/routers/search.py:57, src/jira_emulator/routers/search.py:58, src/jira_emulator/routers/tokens.py:29, src/jira_emulator/routers/tokens.py:59, src/jira_emulator/routers/tokens.py:88, src/jira_emulator/routers/users.py:124, src/jira_emulator/routers/users.py:156, src/jira_emulator/routers/users.py:38, src/jira_emulator/routers/users.py:71, src/jira_emulator/routers/users.py:92, src/jira_emulator/routers/webhooks.py:150, src/jira_emulator/routers/webhooks.py:160, src/jira_emulator/routers/webhooks.py:179, src/jira_emulator/routers/webhooks.py:18, src/jira_emulator/routers/webhooks.py:26, src/jira_emulator/routers/webhooks.py:54, src/jira_emulator/routers/webhooks.py:77, src/jira_emulator/routers/webhooks.py:99, src/jira_emulator/web/routes.py:1075, src/jira_emulator/web/routes.py:1127, src/jira_emulator/web/routes.py:1193, src/jira_emulator/web/routes.py:1244, src/jira_emulator/web/routes.py:144, src/jira_emulator/web/routes.py:179, src/jira_emulator/web/routes.py:228, src/jira_emulator/web/routes.py:321, src/jira_emulator/web/routes.py:387, src/jira_emulator/web/routes.py:395, src/jira_emulator/web/routes.py:404, src/jira_emulator/web/routes.py:414, src/jira_emulator/web/routes.py:432, src/jira_emulator/web/routes.py:483, src/jira_emulator/web/routes.py:501, src/jira_emulator/web/routes.py:518, src/jira_emulator/web/routes.py:535, src/jira_emulator/web/routes.py:550, src/jira_emulator/web/routes.py:560, src/jira_emulator/web/routes.py:583, src/jira_emulator/web/routes.py:596, src/jira_emulator/web/routes.py:614, src/jira_emulator/web/routes.py:641, src/jira_emulator/web/routes.py:657, src/jira_emulator/web/routes.py:692, src/jira_emulator/web/routes.py:703, src/jira_emulator/web/routes.py:812, src/jira_emulator/web/routes.py:832, src/jira_emulator/web/routes.py:878, src/jira_emulator/web/routes.py:946, src/jira_emulator/web/routes.py:972]
- **services (observed)**: 1 services facts extracted [source: src/jira_emulator/web/routes.py:144]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `src/jira_emulator/routers/admin.py`:74 (Bearer token or API key, HTTP API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:44 (Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:46 (Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.k3s`:56 (Dockerfile.k3s:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.k3s`:60 (Dockerfile.k3s:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:12 (uvicorn)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/jira_emulator/web/routes.py`:144 (/, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/jira_emulator/web/routes.py`:404 (/admin/import, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/jira_emulator/web/routes.py`:483 (/admin/users/{username}/profile, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/jira_emulator/web/routes.py`:501 (/admin/users/{username}/status, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/jira_emulator/web/routes.py`:518 (/admin/users/{username}/password, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/jira_emulator/web/routes.py`:550 (/admin/backup, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/jira_emulator/web/routes.py`:560 (/admin/restore/{name}, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/jira_emulator/web/routes.py`:583 (/admin/snapshot/{name}/delete, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/jira_emulator/web/routes.py`:596 (/admin/reset, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/jira_emulator/web/routes.py`:614 (/admin/projects, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/jira_emulator/web/routes.py`:641 (/admin/projects/{project_key}/delete, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/jira_emulator/web/routes.py`:703 (/admin/import, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `src/jira_emulator/web/routes.py`:144 (jira-emulator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=Bearer token or API key enforcement=Python API dependency or middleware policy=Source-defined authentication [source: src/jira_emulator/routers/admin.py:74]
### http_endpoints

- DELETE /api/admin/projects/{project_key} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/routers/admin.py:211]
- DELETE /api/admin/snapshots/{name} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/routers/admin.py:288]
- GET / on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:144]
- GET /admin/import on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:404]
- GET /admin/users/{username} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:432]
- GET /api/admin/snapshots on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/routers/admin.py:258]
- GET /api/web/create-metadata on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:812]
- GET /attachment/{attachment_id}/view on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:1244]
- GET /browse/{key} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:387]
- GET /issue/{key} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:321]
- GET /issues on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:228]
- GET /project/{key} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:179]
- POST /admin/backup on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:550]
- POST /admin/import on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:703]
- POST /admin/projects on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:614]
- POST /admin/projects/{project_key}/delete on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:641]
- POST /admin/reset on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:596]
- POST /admin/restore/{name} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:560]
- POST /admin/snapshot/{name}/delete on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:583]
- POST /admin/users on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:414]
- POST /admin/users/{username}/password on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:518]
- POST /admin/users/{username}/profile on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:483]
- POST /admin/users/{username}/status on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:501]
- POST /admin/users/{username}/tokens/{token_id}/revoke on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:535]
- POST /admin/webhooks on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:657]
- POST /admin/webhooks/{webhook_id}/delete on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:692]
- POST /api/admin/import on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/routers/admin.py:71]
- POST /api/admin/import/file on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/routers/admin.py:88]
- POST /api/admin/import/project-config on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/routers/admin.py:152]
- POST /api/admin/projects on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/routers/admin.py:190]
- POST /api/admin/reset on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/routers/admin.py:224]
- POST /api/admin/snapshots on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/routers/admin.py:265]
- POST /api/admin/snapshots/{name}/restore on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/routers/admin.py:277]
- POST /issue/create on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:832]
- POST /issue/{key}/attachment on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:1127]
- POST /issue/{key}/attachment/{attachment_id}/delete on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:1193]
- POST /issue/{key}/comment on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:1075]
- POST /issue/{key}/delete on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:946]
- POST /issue/{key}/edit on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:878]
- POST /issue/{key}/rollback/{history_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/jira_emulator/web/routes.py:972]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service jira-emulator targets  with 0 port(s) [source: src/jira_emulator/web/routes.py:144]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses Bearer token or API key at Python API dependency or middleware; policy=Source-defined authentication [source: src/jira_emulator/routers/admin.py:74]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

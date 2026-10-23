# Analyzer Synthesis Context: github-emulator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 381 http_endpoints facts extracted [source: src/app/api/actions.py:158, src/app/api/actions.py:166, src/app/api/actions.py:246, src/app/api/actions.py:255, src/app/api/actions.py:274, src/app/api/actions.py:302, src/app/api/actions.py:320, src/app/api/actions.py:346, src/app/api/actions.py:366, src/app/api/actions.py:443, src/app/api/actions.py:466, src/app/api/actions.py:502, src/app/api/actions.py:516, src/app/api/actions.py:572, src/app/api/actions.py:597, src/app/api/actions.py:620, src/app/api/actions.py:647, src/app/api/actions.py:668, src/app/api/actions.py:682, src/app/api/actions.py:697, src/app/api/actions.py:725, src/app/api/actions.py:743, src/app/api/actions.py:753, src/app/api/actions.py:770, src/app/api/actions.py:789, src/app/api/actions.py:812, src/app/api/actions.py:829, src/app/api/actions.py:863, src/app/api/actions.py:884, src/app/api/actions.py:906, src/app/api/actions_dispatch.py:346, src/app/api/actions_dispatch.py:359, src/app/api/actions_dispatch.py:402, src/app/api/actions_dispatch.py:415, src/app/api/actions_dispatch.py:425, src/app/api/actions_dispatch.py:450, src/app/api/actions_dispatch.py:563, src/app/api/actions_dispatch.py:584, src/app/api/actions_dispatch.py:632, src/app/api/actions_distributed_task.py:1013, src/app/api/actions_distributed_task.py:1014, src/app/api/actions_distributed_task.py:1039, src/app/api/actions_distributed_task.py:1040, src/app/api/actions_distributed_task.py:1061, src/app/api/actions_distributed_task.py:1062, src/app/api/actions_distributed_task.py:1083, src/app/api/actions_distributed_task.py:1084, src/app/api/actions_distributed_task.py:1092, src/app/api/actions_distributed_task.py:1093, src/app/api/actions_distributed_task.py:1105, src/app/api/actions_distributed_task.py:1106, src/app/api/actions_distributed_task.py:1118, src/app/api/actions_distributed_task.py:1119, src/app/api/actions_distributed_task.py:1132, src/app/api/actions_distributed_task.py:1133, src/app/api/actions_distributed_task.py:1141, src/app/api/actions_distributed_task.py:1142, src/app/api/actions_distributed_task.py:1157, src/app/api/actions_distributed_task.py:1158, src/app/api/actions_distributed_task.py:1184, src/app/api/actions_distributed_task.py:1185, src/app/api/actions_distributed_task.py:1203, src/app/api/actions_distributed_task.py:1204, src/app/api/actions_distributed_task.py:1211, src/app/api/actions_distributed_task.py:1212, src/app/api/actions_distributed_task.py:1228, src/app/api/actions_distributed_task.py:1229, src/app/api/actions_distributed_task.py:1248, src/app/api/actions_distributed_task.py:1249, src/app/api/actions_distributed_task.py:1304, src/app/api/actions_distributed_task.py:1305, src/app/api/actions_distributed_task.py:1350, src/app/api/actions_distributed_task.py:1351, src/app/api/actions_distributed_task.py:1365, src/app/api/actions_distributed_task.py:1366, src/app/api/actions_distributed_task.py:1394, src/app/api/actions_distributed_task.py:1395, src/app/api/actions_distributed_task.py:1418, src/app/api/actions_distributed_task.py:1419, src/app/api/actions_distributed_task.py:155, src/app/api/actions_distributed_task.py:156, src/app/api/actions_distributed_task.py:259, src/app/api/actions_distributed_task.py:260, src/app/api/actions_distributed_task.py:272, src/app/api/actions_distributed_task.py:273, src/app/api/actions_distributed_task.py:381, src/app/api/actions_distributed_task.py:382, src/app/api/actions_distributed_task.py:444, src/app/api/actions_distributed_task.py:445, src/app/api/actions_distributed_task.py:463, src/app/api/actions_distributed_task.py:464, src/app/api/actions_distributed_task.py:465, src/app/api/actions_distributed_task.py:466, src/app/api/actions_distributed_task.py:496, src/app/api/actions_distributed_task.py:497, src/app/api/actions_distributed_task.py:522, src/app/api/actions_distributed_task.py:523, src/app/api/actions_distributed_task.py:953, src/app/api/actions_distributed_task.py:954, src/app/api/actions_distributed_task.py:983, src/app/api/actions_distributed_task.py:984, src/app/api/actions_pipelines.py:102, src/app/api/actions_pipelines.py:117, src/app/api/actions_pipelines.py:177, src/app/api/actions_pipelines.py:193, src/app/api/actions_pipelines.py:33, src/app/api/actions_pipelines.py:86, src/app/api/actions_runners.py:115, src/app/api/actions_runners.py:132, src/app/api/actions_runners.py:147, src/app/api/actions_runners.py:218, src/app/api/actions_runners.py:233, src/app/api/actions_runners.py:254, src/app/api/actions_runners.py:264, src/app/api/actions_runners.py:281, src/app/api/actions_runners.py:296, src/app/api/actions_runners.py:314, src/app/api/actions_runners.py:98, src/app/api/admin_apps.py:107, src/app/api/admin_apps.py:123, src/app/api/admin_apps.py:132, src/app/api/admin_apps.py:143, src/app/api/admin_apps.py:180, src/app/api/admin_apps.py:199, src/app/api/admin_apps.py:212, src/app/api/admin_frontend.py:140, src/app/api/admin_frontend.py:148, src/app/api/admin_frontend.py:154, src/app/api/admin_frontend.py:164, src/app/api/admin_frontend.py:176, src/app/api/admin_frontend.py:185, src/app/api/admin_frontend.py:191, src/app/api/admin_frontend.py:202, src/app/api/admin_frontend.py:212, src/app/api/admin_frontend.py:230, src/app/api/admin_frontend.py:236, src/app/api/admin_frontend.py:244, src/app/api/admin_frontend.py:250, src/app/api/admin_frontend.py:257, src/app/api/admin_frontend.py:265, src/app/api/admin_frontend.py:280, src/app/api/admin_frontend.py:301, src/app/api/admin_frontend.py:323, src/app/api/admin_frontend.py:329, src/app/api/admin_frontend.py:339, src/app/api/admin_frontend.py:365, src/app/api/admin_frontend.py:495, src/app/api/admin_frontend.py:576, src/app/api/admin_frontend.py:598, src/app/api/admin_frontend.py:626, src/app/api/admin_frontend.py:647, src/app/api/apps.py:117, src/app/api/apps.py:143, src/app/api/apps.py:169, src/app/api/apps.py:185, src/app/api/apps.py:245, src/app/api/apps.py:250, src/app/api/apps.py:257, src/app/api/apps.py:295, src/app/api/apps.py:305, src/app/api/apps.py:343, src/app/api/apps.py:352, src/app/api/branches.py:252, src/app/api/branches.py:271, src/app/api/branches.py:285, src/app/api/branches.py:316, src/app/api/branches.py:332, src/app/api/branches.py:344, src/app/api/branches.py:361, src/app/api/branches.py:379, src/app/api/branches.py:393, src/app/api/branches.py:412, src/app/api/branches.py:430, src/app/api/branches.py:445, src/app/api/branches.py:461, src/app/api/branches.py:479, src/app/api/browser_repositories.py:128, src/app/api/browser_repositories.py:37, src/app/api/browser_repositories.py:74, src/app/api/browser_session.py:40, src/app/api/browser_session.py:66, src/app/api/browser_session.py:74, src/app/api/check_runs.py:119, src/app/api/check_runs.py:136, src/app/api/check_runs.py:178, src/app/api/check_runs.py:200, src/app/api/check_runs.py:217, src/app/api/check_runs.py:240, src/app/api/check_runs.py:61, src/app/api/collaborators.py:136, src/app/api/collaborators.py:157, src/app/api/collaborators.py:52, src/app/api/collaborators.py:77, src/app/api/collaborators.py:98, src/app/api/comments.py:102, src/app/api/comments.py:152, src/app/api/comments.py:179, src/app/api/comments.py:211, src/app/api/comments.py:47, src/app/api/commits.py:129, src/app/api/commits.py:186, src/app/api/commits.py:84, src/app/api/contents.py:159, src/app/api/contents.py:279, src/app/api/contents.py:298, src/app/api/contents.py:91, src/app/api/deploy_keys.py:29, src/app/api/deploy_keys.py:47, src/app/api/deploy_keys.py:73, src/app/api/deploy_keys.py:88, src/app/api/emojis.py:36, src/app/api/events.py:34, src/app/api/events.py:53, src/app/api/events.py:72, src/app/api/events.py:95, src/app/api/forks.py:20, src/app/api/forks.py:72, src/app/api/gists.py:118, src/app/api/gists.py:148, src/app/api/gists.py:158, src/app/api/gists.py:205, src/app/api/gists.py:56, src/app/api/gists.py:75, src/app/api/gists.py:93, src/app/api/git_blobs.py:46, src/app/api/git_blobs.py:71, src/app/api/git_commits.py:39, src/app/api/git_commits.py:93, src/app/api/git_refs.py:140, src/app/api/git_refs.py:166, src/app/api/git_refs.py:184, src/app/api/git_refs.py:208, src/app/api/git_refs.py:252, src/app/api/git_refs.py:58, src/app/api/git_tags.py:32, src/app/api/git_tags.py:93, src/app/api/git_trees.py:40, src/app/api/git_trees.py:87, src/app/api/gitignore.py:79, src/app/api/gitignore.py:85, src/app/api/issue_events.py:30, src/app/api/issues.py:156, src/app/api/issues.py:221, src/app/api/issues.py:300, src/app/api/issues.py:323, src/app/api/labels.py:120, src/app/api/labels.py:149, src/app/api/labels.py:170, src/app/api/labels.py:200, src/app/api/labels.py:224, src/app/api/labels.py:245, src/app/api/labels.py:305, src/app/api/labels.py:371, src/app/api/labels.py:98, src/app/api/licenses.py:101, src/app/api/licenses.py:116, src/app/api/markdown.py:39, src/app/api/markdown.py:9, src/app/api/milestones.py:106, src/app/api/milestones.py:130, src/app/api/milestones.py:179, src/app/api/milestones.py:28, src/app/api/milestones.py:70, src/app/api/notifications.py:102, src/app/api/notifications.py:116, src/app/api/notifications.py:39, src/app/api/notifications.py:61, src/app/api/notifications.py:76, src/app/api/oauth.py:20, src/app/api/oauth.py:48, src/app/api/oidc.py:16, src/app/api/oidc.py:26, src/app/api/oidc.py:31, src/app/api/orgs.py:103, src/app/api/orgs.py:120, src/app/api/orgs.py:148, src/app/api/orgs.py:160, src/app/api/orgs.py:179, src/app/api/orgs.py:52, src/app/api/orgs.py:93, src/app/api/pulls.py:1016, src/app/api/pulls.py:1051, src/app/api/pulls.py:560, src/app/api/pulls.py:634, src/app/api/pulls.py:725, src/app/api/pulls.py:749, src/app/api/pulls.py:841, src/app/api/raw_content.py:27, src/app/api/reactions.py:102, src/app/api/reactions.py:118, src/app/api/reactions.py:136, src/app/api/reactions.py:169, src/app/api/reactions.py:33, src/app/api/reactions.py:60, src/app/api/releases.py:146, src/app/api/releases.py:165, src/app/api/releases.py:198, src/app/api/releases.py:217, src/app/api/releases.py:234, src/app/api/releases.py:255, src/app/api/releases.py:272, src/app/api/releases.py:287, src/app/api/releases.py:301, src/app/api/releases.py:353, src/app/api/releases.py:370, src/app/api/releases.py:387, src/app/api/releases.py:411, src/app/api/repos.py:173, src/app/api/repos.py:194, src/app/api/repos.py:262, src/app/api/repos.py:285, src/app/api/repos.py:327, src/app/api/repos.py:347, src/app/api/repos.py:409, src/app/api/repos.py:459, src/app/api/repos.py:518, src/app/api/review_comments.py:130, src/app/api/review_comments.py:177, src/app/api/review_comments.py:208, src/app/api/review_comments.py:241, src/app/api/review_comments.py:259, src/app/api/review_comments.py:80, src/app/api/reviews.py:210, src/app/api/reviews.py:226, src/app/api/reviews.py:277, src/app/api/reviews.py:56, src/app/api/reviews.py:76, src/app/api/root.py:53, src/app/api/root.py:66, src/app/api/root.py:72, src/app/api/root.py:91, src/app/api/search.py:138, src/app/api/search.py:185, src/app/api/search.py:278, src/app/api/search.py:40, src/app/api/search.py:92, src/app/api/starring.py:112, src/app/api/starring.py:18, src/app/api/starring.py:37, src/app/api/starring.py:57, src/app/api/starring.py:73, src/app/api/starring.py:92, src/app/api/statuses.py:34, src/app/api/statuses.py:63, src/app/api/statuses.py:83, src/app/api/teams.py:105, src/app/api/teams.py:122, src/app/api/teams.py:141, src/app/api/teams.py:152, src/app/api/teams.py:45, src/app/api/teams.py:67, src/app/api/teams.py:95, src/app/api/user_keys.py:108, src/app/api/user_keys.py:120, src/app/api/user_keys.py:135, src/app/api/user_keys.py:145, src/app/api/user_keys.py:166, src/app/api/user_keys.py:178, src/app/api/user_keys.py:193, src/app/api/user_keys.py:74, src/app/api/user_keys.py:84, src/app/api/users.py:109, src/app/api/users.py:171, src/app/api/users.py:202, src/app/api/users.py:33, src/app/api/users.py:39, src/app/api/users.py:52, src/app/api/users.py:62, src/app/api/users.py:82, src/app/api/webhooks.py:131, src/app/api/webhooks.py:147, src/app/api/webhooks.py:39, src/app/api/webhooks.py:57, src/app/api/webhooks.py:84, src/app/api/webhooks.py:99, src/app/git/smart_http.py:385, src/app/git/smart_http.py:386, src/app/git/smart_http.py:443, src/app/git/smart_http.py:444, src/app/git/smart_http.py:489, src/app/git/smart_http.py:490]
- **services (observed)**: 1 services facts extracted [source: src/app/api/oidc.py:26]
- **ingress (not-verified)**: 0 ingress facts extracted; absence is not proven by the available coverage
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `src/app/api/deps.py`:273 (Bearer token or API key, HTTP API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:51 (Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:54 (Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.k3s`:52 (Dockerfile.k3s:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.k3s`:55 (Dockerfile.k3s:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:12 (uvicorn)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `src/runners/emulator/Dockerfile`:24 (src/runners/emulator/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `src/runners/upstream/Dockerfile`:37 (src/runners/upstream/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/app/api/actions_distributed_task.py`:1248 (/_apis/distributedtask/hubs/{hub_name}/plans/{plan_id}/timelines/{timeline_id}/records/{record_id}/feed, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/app/api/actions_distributed_task.py`:1304 (/_apis/distributedtask/hubs/{hub_name}/plans/{plan_id}/actionsdownloadinfo, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/app/api/actions_distributed_task.py`:1350 (/_apis/distributedtask/actions/archives/{owner}/{repo}/{sha}/archive.{fmt}, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/app/api/actions_distributed_task.py`:1365 (/_apis/distributedtask/hubs/{hub_name}/plans/{plan_id}/logs, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/app/api/actions_distributed_task.py`:1394 (/_apis/distributedtask/hubs/{hub_name}/plans/{plan_id}/logs/{log_id}, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/app/api/actions_distributed_task.py`:1418 (/_apis/distributedtask/hubs/{hub_name}/plans/{plan_id}/timelines/{timeline_id}/records, PATCH)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/app/api/actions_distributed_task.py`:155 (/_apis/connectionData, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/app/api/actions_distributed_task.py`:259 (/_apis/, OPTIONS)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/app/api/actions_distributed_task.py`:953 (/_apis/distributedtask/connect, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/app/api/oidc.py`:16 (/.well-known/openid-configuration, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/app/api/oidc.py`:26 (/.well-known/jwks.json, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `src/app/api/root.py`:53 (/, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `src/app/api/oidc.py`:26 (github-emulator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=Bearer token or API key enforcement=Python API dependency or middleware policy=Source-defined authentication [source: src/app/api/deps.py:273]
### http_endpoints

- DELETE /_apis/distributedtask/pools/{pool_id}/agents/{agent_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:522]
- DELETE /_apis/distributedtask/pools/{pool_id}/jobrequests/{request_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1184]
- DELETE /_apis/distributedtask/pools/{pool_id}/messages/{message_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1118]
- DELETE /_apis/distributedtask/pools/{pool_id}/sessions/{session_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1132]
- DELETE /_apis/distributedtask/session/{session_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1013]
- DELETE /_services/pipelines/enterprises/{enterprise}/_apis/pipelines/runs/{runner_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_pipelines.py:86]
- DELETE /_services/pipelines/{owner}/{repo}/_apis/pipelines/runs/{runner_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_pipelines.py:177]
- GET / on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/root.py:53]
- GET /.well-known/jwks.json on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/oidc.py:26]
- GET /.well-known/openid-configuration on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/oidc.py:16]
- GET /_apis/connectionData on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:155]
- GET /_apis/distributedtask/actions/archives/{owner}/{repo}/{sha}/archive.{fmt} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1350]
- GET /_apis/distributedtask/pools on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:496]
- GET /_apis/distributedtask/pools/{pool_id}/agents on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:444]
- GET /_apis/distributedtask/pools/{pool_id}/messages on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1105]
- GET /_apis/distributedtask/pools/{pool_id}/sessions/{session_id}/messages on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1092]
- GET /_apis/distributedtask/session/{session_id}/messages on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:983]
- GET /_services/pipelines/enterprises/{enterprise}/_apis/pipelines/runs on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_pipelines.py:102]
- GET /_services/pipelines/{owner}/{repo}/_apis/pipelines/runs on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_pipelines.py:193]
- OPTIONS /_apis/ on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:259]
- PATCH /_apis/distributedtask/hubs/{hub_name}/plans/{plan_id}/timelines/{timeline_id}/records on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1418]
- PATCH /_apis/distributedtask/pools/{pool_id}/agents/{agent_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:463]
- PATCH /_apis/distributedtask/pools/{pool_id}/jobrequests/{request_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1157]
- PATCH /_apis/distributedtask/pools/{pool_id}/timelines/{timeline_id}/records on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1211]
- POST /_apis/distributedtask/connect on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:953]
- POST /_apis/distributedtask/hubs/{hub_name}/plans/{plan_id}/actionsdownloadinfo on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1304]
- POST /_apis/distributedtask/hubs/{hub_name}/plans/{plan_id}/logs on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1365]
- POST /_apis/distributedtask/hubs/{hub_name}/plans/{plan_id}/logs/{log_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1394]
- POST /_apis/distributedtask/hubs/{hub_name}/plans/{plan_id}/timelines/{timeline_id}/records/{record_id}/feed on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1248]
- POST /_apis/distributedtask/jobs/{job_id}/complete on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1061]
- POST /_apis/distributedtask/jobs/{job_id}/timeline on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1039]
- POST /_apis/distributedtask/pools/{pool_id}/agents on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:381]
- POST /_apis/distributedtask/pools/{pool_id}/jobrequests/{request_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1141]
- POST /_apis/distributedtask/pools/{pool_id}/sessions on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1083]
- POST /_apis/distributedtask/pools/{pool_id}/timelines on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1203]
- POST /_apis/distributedtask/pools/{pool_id}/timelines/{timeline_id}/logs/{log_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:1228]
- POST /_apis/oauth2/token on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:272]
- POST /_services/pipelines/enterprises/{enterprise}/_apis/pipelines/runs/register on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_pipelines.py:33]
- POST /_services/pipelines/{owner}/{repo}/_apis/pipelines/runs/register on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_pipelines.py:117]
- PUT /_apis/distributedtask/pools/{pool_id}/agents/{agent_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: src/app/api/actions_distributed_task.py:464]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service github-emulator targets  with 0 port(s) [source: src/app/api/oidc.py:26]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses Bearer token or API key at Python API dependency or middleware; policy=Source-defined authentication [source: src/app/api/deps.py:273]
- **dependency-signal**: auth-middleware targets python-jose: JWT/OAuth authentication library dependency [source: pyproject.toml:19]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

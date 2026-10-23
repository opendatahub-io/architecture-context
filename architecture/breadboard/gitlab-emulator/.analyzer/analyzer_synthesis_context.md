# Analyzer Synthesis Context: gitlab-emulator

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (confirmed-empty)**: 0 grpc_services facts extracted
- **http_endpoints (observed)**: 552 http_endpoints facts extracted [source: app/admin/routes.py:1049, app/admin/routes.py:1079, app/admin/routes.py:1118, app/admin/routes.py:1174, app/admin/routes.py:1194, app/admin/routes.py:1208, app/admin/routes.py:1252, app/admin/routes.py:1275, app/admin/routes.py:1308, app/admin/routes.py:1332, app/admin/routes.py:1354, app/admin/routes.py:1374, app/admin/routes.py:1415, app/admin/routes.py:1441, app/admin/routes.py:1461, app/admin/routes.py:1505, app/admin/routes.py:1554, app/admin/routes.py:1579, app/admin/routes.py:1599, app/admin/routes.py:1616, app/admin/routes.py:1723, app/admin/routes.py:1774, app/admin/routes.py:1813, app/admin/routes.py:1865, app/admin/routes.py:1919, app/admin/routes.py:1948, app/admin/routes.py:1994, app/admin/routes.py:2043, app/admin/routes.py:2072, app/admin/routes.py:2098, app/admin/routes.py:2124, app/admin/routes.py:2144, app/admin/routes.py:2217, app/admin/routes.py:2239, app/admin/routes.py:320, app/admin/routes.py:350, app/admin/routes.py:401, app/admin/routes.py:460, app/admin/routes.py:626, app/admin/routes.py:639, app/admin/routes.py:688, app/admin/routes.py:700, app/admin/routes.py:753, app/admin/routes.py:782, app/admin/routes.py:817, app/admin/routes.py:870, app/admin/routes.py:911, app/admin/routes.py:948, app/api/actions.py:114, app/api/actions.py:138, app/api/actions.py:160, app/api/actions.py:182, app/api/actions.py:19, app/api/actions.py:198, app/api/actions.py:216, app/api/actions.py:235, app/api/actions.py:253, app/api/actions.py:271, app/api/actions.py:294, app/api/actions.py:52, app/api/actions.py:74, app/api/admin_ci_variables.py:124, app/api/admin_ci_variables.py:143, app/api/admin_ci_variables.py:174, app/api/admin_ci_variables.py:187, app/api/admin_ci_variables.py:227, app/api/application.py:77, app/api/application.py:88, app/api/branches.py:37, app/api/branches.py:60, app/api/branches.py:79, app/api/check_runs.py:118, app/api/check_runs.py:135, app/api/check_runs.py:175, app/api/check_runs.py:197, app/api/check_runs.py:214, app/api/check_runs.py:238, app/api/check_runs.py:62, app/api/collaborators.py:154, app/api/collaborators.py:199, app/api/collaborators.py:215, app/api/collaborators.py:259, app/api/collaborators.py:283, app/api/collaborators.py:308, app/api/collaborators.py:333, app/api/collaborators.py:376, app/api/collaborators.py:401, app/api/comments.py:137, app/api/comments.py:161, app/api/comments.py:194, app/api/comments.py:47, app/api/comments.py:99, app/api/commits.py:118, app/api/commits.py:141, app/api/commits.py:79, app/api/contents.py:151, app/api/contents.py:241, app/api/contents.py:321, app/api/contents.py:86, app/api/deploy_keys.py:127, app/api/deploy_keys.py:146, app/api/deploy_keys.py:167, app/api/deploy_keys.py:185, app/api/deploy_keys.py:212, app/api/deploy_keys.py:227, app/api/deploy_keys.py:62, app/api/deploy_keys.py:99, app/api/emojis.py:36, app/api/events.py:102, app/api/events.py:38, app/api/events.py:58, app/api/events.py:78, app/api/forks.py:22, app/api/forks.py:82, app/api/gists.py:118, app/api/gists.py:148, app/api/gists.py:158, app/api/gists.py:205, app/api/gists.py:56, app/api/gists.py:75, app/api/gists.py:93, app/api/git_blobs.py:47, app/api/git_blobs.py:72, app/api/git_commits.py:32, app/api/git_commits.py:81, app/api/git_refs.py:112, app/api/git_refs.py:142, app/api/git_refs.py:45, app/api/git_refs.py:71, app/api/git_refs.py:89, app/api/git_tags.py:32, app/api/git_tags.py:88, app/api/git_trees.py:32, app/api/git_trees.py:79, app/api/gitignore.py:79, app/api/gitignore.py:85, app/api/gitlab_commits.py:177, app/api/gitlab_commits.py:232, app/api/gitlab_commits.py:276, app/api/gitlab_commits.py:289, app/api/groups.py:1003, app/api/groups.py:1046, app/api/groups.py:1070, app/api/groups.py:394, app/api/groups.py:435, app/api/groups.py:508, app/api/groups.py:549, app/api/groups.py:590, app/api/groups.py:631, app/api/groups.py:677, app/api/groups.py:703, app/api/groups.py:729, app/api/groups.py:773, app/api/groups.py:797, app/api/groups.py:818, app/api/groups.py:850, app/api/groups.py:865, app/api/groups.py:906, app/api/groups.py:923, app/api/groups.py:949, app/api/groups.py:981, app/api/issues.py:314, app/api/issues.py:358, app/api/issues.py:395, app/api/issues.py:408, app/api/issues.py:409, app/api/issues.py:467, app/api/issues.py:530, app/api/issues.py:596, app/api/issues.py:615, app/api/labels.py:136, app/api/labels.py:165, app/api/labels.py:182, app/api/labels.py:208, app/api/labels.py:227, app/api/labels.py:249, app/api/labels.py:277, app/api/labels.py:295, app/api/labels.py:325, app/api/labels.py:350, app/api/labels.py:368, app/api/labels.py:413, app/api/labels.py:455, app/api/labels.py:94, app/api/licenses.py:101, app/api/licenses.py:116, app/api/markdown.py:39, app/api/markdown.py:9, app/api/merge_requests.py:439, app/api/merge_requests.py:491, app/api/merge_requests.py:572, app/api/merge_requests.py:585, app/api/merge_requests.py:631, app/api/merge_requests.py:653, app/api/merge_requests.py:675, app/api/merge_requests.py:699, app/api/merge_requests.py:790, app/api/milestones.py:115, app/api/milestones.py:166, app/api/milestones.py:197, app/api/milestones.py:212, app/api/milestones.py:248, app/api/milestones.py:263, app/api/milestones.py:305, app/api/milestones.py:335, app/api/milestones.py:359, app/api/milestones.py:406, app/api/namespaces.py:137, app/api/namespaces.py:89, app/api/notifications.py:102, app/api/notifications.py:116, app/api/notifications.py:39, app/api/notifications.py:61, app/api/notifications.py:76, app/api/oauth.py:20, app/api/oauth.py:48, app/api/orgs.py:103, app/api/orgs.py:121, app/api/orgs.py:133, app/api/orgs.py:152, app/api/orgs.py:52, app/api/orgs.py:93, app/api/packages.py:34, app/api/packages.py:62, app/api/packages.py:83, app/api/pipelines.py:1747, app/api/pipelines.py:1752, app/api/pipelines.py:2325, app/api/pipelines.py:2341, app/api/pipelines.py:2362, app/api/pipelines.py:2395, app/api/pipelines.py:2429, app/api/pipelines.py:2449, app/api/pipelines.py:2486, app/api/pipelines.py:2499, app/api/pipelines.py:2536, app/api/pipelines.py:2658, app/api/pipelines.py:2670, app/api/pipelines.py:2687, app/api/pipelines.py:2700, app/api/pipelines.py:2716, app/api/pipelines.py:2733, app/api/pipelines.py:2749, app/api/pipelines.py:2761, app/api/pipelines.py:2779, app/api/pipelines.py:2792, app/api/pipelines.py:2807, app/api/pipelines.py:2829, app/api/pipelines.py:2841, app/api/pipelines.py:2858, app/api/pipelines.py:2873, app/api/pipelines.py:2891, app/api/pipelines.py:2908, app/api/pipelines.py:2929, app/api/pipelines.py:2951, app/api/pipelines.py:3041, app/api/pipelines.py:3070, app/api/pipelines.py:3087, app/api/pipelines.py:3110, app/api/pipelines.py:3161, app/api/pipelines.py:3205, app/api/pipelines.py:3234, app/api/pipelines.py:3258, app/api/pipelines.py:3268, app/api/pipelines.py:3288, app/api/pipelines.py:3304, app/api/pipelines.py:3314, app/api/pipelines.py:3330, app/api/pipelines.py:3367, app/api/pipelines.py:3388, app/api/pipelines.py:3411, app/api/pipelines.py:3445, app/api/pipelines.py:3491, app/api/pipelines.py:3536, app/api/pipelines.py:3574, app/api/pipelines.py:3618, app/api/pipelines.py:3673, app/api/pipelines.py:3712, app/api/pipelines.py:3731, app/api/pipelines.py:3753, app/api/pipelines.py:3793, app/api/pipelines.py:3810, app/api/pipelines.py:3832, app/api/pipelines.py:3850, app/api/pipelines.py:3882, app/api/projects.py:1024, app/api/projects.py:1065, app/api/projects.py:1066, app/api/projects.py:1105, app/api/projects.py:1133, app/api/projects.py:1172, app/api/projects.py:1184, app/api/projects.py:1207, app/api/projects.py:1224, app/api/projects.py:1261, app/api/projects.py:1273, app/api/projects.py:1294, app/api/projects.py:1327, app/api/projects.py:1414, app/api/projects.py:1430, app/api/projects.py:1454, app/api/projects.py:1475, app/api/projects.py:1487, app/api/projects.py:1511, app/api/projects.py:1543, app/api/projects.py:1567, app/api/projects.py:1617, app/api/projects.py:1643, app/api/projects.py:1669, app/api/projects.py:1701, app/api/projects.py:1723, app/api/projects.py:1766, app/api/projects.py:1790, app/api/projects.py:1823, app/api/projects.py:1884, app/api/projects.py:1898, app/api/projects.py:1922, app/api/projects.py:863, app/api/projects.py:919, app/api/projects.py:990, app/api/pulls.py:357, app/api/pulls.py:428, app/api/pulls.py:501, app/api/pulls.py:520, app/api/pulls.py:570, app/api/pulls.py:649, app/api/pulls.py:721, app/api/reactions.py:104, app/api/reactions.py:122, app/api/reactions.py:140, app/api/reactions.py:175, app/api/reactions.py:34, app/api/reactions.py:61, app/api/releases.py:236, app/api/releases.py:263, app/api/releases.py:311, app/api/releases.py:327, app/api/releases.py:350, app/api/releases.py:367, app/api/releases.py:400, app/api/releases.py:421, app/api/releases.py:434, app/api/releases.py:461, app/api/releases.py:480, app/api/releases.py:504, app/api/releases.py:534, app/api/releases.py:551, app/api/releases.py:569, app/api/releases.py:586, app/api/releases.py:611, app/api/repos.py:159, app/api/repos.py:218, app/api/repos.py:239, app/api/repos.py:275, app/api/repos.py:294, app/api/repos.py:353, app/api/repos.py:399, app/api/repository_files.py:558, app/api/repository_files.py:614, app/api/repository_files.py:674, app/api/repository_files.py:694, app/api/repository_files.py:708, app/api/repository_files.py:721, app/api/repository_files.py:761, app/api/repository_files.py:789, app/api/review_comments.py:130, app/api/review_comments.py:178, app/api/review_comments.py:209, app/api/review_comments.py:243, app/api/review_comments.py:262, app/api/review_comments.py:80, app/api/reviews.py:105, app/api/reviews.py:121, app/api/reviews.py:151, app/api/reviews.py:56, app/api/reviews.py:76, app/api/root.py:100, app/api/root.py:115, app/api/root.py:53, app/api/root.py:66, app/api/root.py:72, app/api/root.py:91, app/api/runner.py:1489, app/api/runner.py:1508, app/api/runner.py:1518, app/api/runner.py:1556, app/api/runner.py:1585, app/api/runner.py:1606, app/api/runner.py:1624, app/api/runner.py:1705, app/api/runner.py:1771, app/api/runner.py:1824, app/api/runner.py:1881, app/api/runner.py:1977, app/api/runner.py:1998, app/api/runner.py:2017, app/api/search.py:105, app/api/search.py:333, app/api/search.py:378, app/api/search.py:430, app/api/search.py:478, app/api/search.py:575, app/api/snippets.py:133, app/api/snippets.py:157, app/api/snippets.py:166, app/api/snippets.py:181, app/api/snippets.py:198, app/api/snippets.py:225, app/api/starring.py:112, app/api/starring.py:18, app/api/starring.py:37, app/api/starring.py:57, app/api/starring.py:73, app/api/starring.py:92, app/api/statuses.py:123, app/api/statuses.py:143, app/api/statuses.py:165, app/api/statuses.py:65, app/api/statuses.py:92, app/api/teams.py:107, app/api/teams.py:124, app/api/teams.py:144, app/api/teams.py:156, app/api/teams.py:46, app/api/teams.py:68, app/api/teams.py:97, app/api/user_keys.py:112, app/api/user_keys.py:124, app/api/user_keys.py:139, app/api/user_keys.py:149, app/api/user_keys.py:175, app/api/user_keys.py:187, app/api/user_keys.py:202, app/api/user_keys.py:78, app/api/user_keys.py:88, app/api/users.py:127, app/api/users.py:24, app/api/users.py:30, app/api/users.py:43, app/api/users.py:56, app/api/users.py:99, app/api/webhooks.py:135, app/api/webhooks.py:162, app/api/webhooks.py:190, app/api/webhooks.py:203, app/api/webhooks.py:227, app/api/webhooks.py:242, app/api/webhooks.py:269, app/api/webhooks.py:297, app/api/webhooks.py:310, app/api/webhooks.py:334, app/api/webhooks.py:349, app/api/webhooks.py:372, app/api/webhooks.py:400, app/api/webhooks.py:415, app/api/webhooks.py:448, app/api/webhooks.py:465, app/git/smart_http.py:518, app/git/smart_http.py:565, app/git/smart_http.py:600, app/web/routes.py:1041, app/web/routes.py:1099, app/web/routes.py:1131, app/web/routes.py:1248, app/web/routes.py:1287, app/web/routes.py:1326, app/web/routes.py:1380, app/web/routes.py:1439, app/web/routes.py:1471, app/web/routes.py:1508, app/web/routes.py:1560, app/web/routes.py:1618, app/web/routes.py:1654, app/web/routes.py:1714, app/web/routes.py:1775, app/web/routes.py:1819, app/web/routes.py:1857, app/web/routes.py:1893, app/web/routes.py:1935, app/web/routes.py:1981, app/web/routes.py:2013, app/web/routes.py:2052, app/web/routes.py:2098, app/web/routes.py:2155, app/web/routes.py:2183, app/web/routes.py:2221, app/web/routes.py:2276, app/web/routes.py:2333, app/web/routes.py:2368, app/web/routes.py:2406, app/web/routes.py:2465, app/web/routes.py:2505, app/web/routes.py:2537, app/web/routes.py:2575, app/web/routes.py:2613, app/web/routes.py:2645, app/web/routes.py:2686, app/web/routes.py:2725, app/web/routes.py:2768, app/web/routes.py:2800, app/web/routes.py:2843, app/web/routes.py:2871, app/web/routes.py:2922, app/web/routes.py:2979, app/web/routes.py:3024, app/web/routes.py:3222, app/web/routes.py:3234, app/web/routes.py:3299, app/web/routes.py:3334, app/web/routes.py:3361, app/web/routes.py:3409, app/web/routes.py:3452, app/web/routes.py:3490, app/web/routes.py:3554, app/web/routes.py:3602, app/web/routes.py:3618, app/web/routes.py:3645, app/web/routes.py:3712, app/web/routes.py:3755, app/web/routes.py:3838, app/web/routes.py:3863, app/web/routes.py:3889, app/web/routes.py:3946, app/web/routes.py:4019, app/web/routes.py:4050, app/web/routes.py:4094, app/web/routes.py:4149, app/web/routes.py:4204, app/web/routes.py:4205, app/web/routes.py:4235, app/web/routes.py:4236, app/web/routes.py:4295, app/web/routes.py:4332, app/web/routes.py:4387, app/web/routes.py:4447, app/web/routes.py:4489, app/web/routes.py:4527, app/web/routes.py:4566, app/web/routes.py:4597, app/web/routes.py:4598, app/web/routes.py:4649, app/web/routes.py:4685, app/web/routes.py:4709, app/web/routes.py:4710, app/web/routes.py:528, app/web/routes.py:541, app/web/routes.py:570, app/web/routes.py:582, app/web/routes.py:602, app/web/routes.py:663, app/web/routes.py:690, app/web/routes.py:851]
- **services (observed)**: 1 services facts extracted [source: app/api/root.py:53]
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (confirmed-empty)**: 0 webhooks facts extracted

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `app/api/deps.py`:90 (Bearer token or API key, HTTP API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:50 (Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:53 (Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pyproject.toml`:12 (uvicorn)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `app/admin/routes.py`:320 (/admin/ci-variables, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `app/admin/routes.py`:350 (/admin/ci-variables, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `app/admin/routes.py`:401 (/admin/ci-variables/{variable_id}/update, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `app/admin/routes.py`:460 (/admin/ci-variables/{variable_id}/delete, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `app/admin/routes.py`:700 (/admin/, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `app/admin/routes.py`:753 (/admin/ci-lab, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `app/admin/routes.py`:782 (/admin/ci-lab/projects, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `app/admin/routes.py`:817 (/admin/ci-lab/yaml, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `app/admin/routes.py`:870 (/admin/ci-lab/pipelines, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `app/admin/routes.py`:911 (/admin/ci-lab/pipelines/{pipeline_id}/cancel, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `app/admin/routes.py`:948 (/admin/ci-lab/jobs/{job_id}/{action}, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `app/api/root.py`:53 (/, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `app/api/root.py`:53 (gitlab-emulator)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=Bearer token or API key enforcement=Python API dependency or middleware policy=Source-defined authentication [source: app/api/deps.py:90]
### http_endpoints

- DELETE /admin/ci/variables/{key} on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/api/admin_ci_variables.py:227]
- GET / on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/api/root.py:53]
- GET /admin/ on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:700]
- GET /admin/ci-lab on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:753]
- GET /admin/ci-variables on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:320]
- GET /admin/ci/variables on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/api/admin_ci_variables.py:124]
- GET /admin/ci/variables/{key} on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/api/admin_ci_variables.py:174]
- GET /admin/import on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:2124]
- GET /admin/import/jobs on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:2217]
- GET /admin/import/jobs/{job_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:2239]
- GET /admin/issues on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:2098]
- GET /admin/login on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:626]
- GET /admin/logout on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:688]
- GET /admin/orgs on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:1579]
- GET /admin/orgs/create on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:1599]
- GET /admin/orgs/{org_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:1723]
- GET /admin/repos/{repo_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:1461]
- POST /admin/ci-lab/jobs/{job_id}/{action} on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:948]
- POST /admin/ci-lab/pipelines on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:870]
- POST /admin/ci-lab/pipelines/{pipeline_id}/cancel on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:911]
- POST /admin/ci-lab/projects on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:782]
- POST /admin/ci-lab/yaml on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:817]
- POST /admin/ci-variables on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:350]
- POST /admin/ci-variables/{variable_id}/delete on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:460]
- POST /admin/ci-variables/{variable_id}/update on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:401]
- POST /admin/ci/variables on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/api/admin_ci_variables.py:143]
- POST /admin/import on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:2144]
- POST /admin/login on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:639]
- POST /admin/orgs/create on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:1616]
- POST /admin/orgs/{org_id} on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:1774]
- POST /admin/orgs/{org_id}/delete on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:2072]
- POST /admin/orgs/{org_id}/secrets on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:1948]
- POST /admin/orgs/{org_id}/secrets/{secret_id}/delete on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:2043]
- POST /admin/orgs/{org_id}/secrets/{secret_id}/update on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:1994]
- POST /admin/orgs/{org_id}/variables on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:1813]
- POST /admin/orgs/{org_id}/variables/{variable_id}/delete on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:1919]
- POST /admin/orgs/{org_id}/variables/{variable_id}/update on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:1865]
- POST /admin/repos/{repo_id}/delete on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:1554]
- POST /admin/repos/{repo_id}/pipelines/delete on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/admin/routes.py:1505]
- PUT /admin/ci/variables/{key} on port ; transport= encryption=Configurable auth=Unknown owner= [source: app/api/admin_ci_variables.py:187]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service gitlab-emulator targets  with 0 port(s) [source: app/api/root.py:53]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses Bearer token or API key at Python API dependency or middleware; policy=Source-defined authentication [source: app/api/deps.py:90]
- **dependency-signal**: auth-middleware targets python-jose: JWT/OAuth authentication library dependency [source: pyproject.toml:17]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]

---
id: "0005"
title: EvalHub custom provider registration and adapter container contract
status: active
created: 2026-05-05
affects:
  - eval-hub
release:
  - "3.4"
provenance:
  - https://github.com/opendatahub-io/agent-eval-harness/pull/30
author: Jeremy Eder
superseded_by: null
---

## Fact

The generated `eval-hub.md` is missing the adapter container contract and custom provider registration mechanism. Discovered during integration of the agent-eval-harness custom provider (PR #30):

1. **Job spec mount path**: The job specification JSON is mounted at `/meta/job.json` inside adapter containers (not documented).
2. **emptyDir at /data**: EvalHub mounts an `emptyDir` volume at `/data` in adapter pods, overwriting any files baked into the container image at that path. Adapters that ship static files (configs, test data) must use a different path (e.g., `/app/`).
3. **Custom provider registration**: Custom providers are registered via labeled ConfigMaps in the `redhat-ods-applications` namespace (not the EvalHub CR namespace). Five labels are required: `app.kubernetes.io/part-of: trustyai`, `app.opendatahub.io/trustyai: "true"`, `trustyai.opendatahub.io/evalhub-provider-type: custom`, `trustyai.opendatahub.io/evalhub-provider-name: <id>`, `opendatahub.io/managed: "true"`. The provider ID must also be added to the EvalHub CR `spec.providers[]` list and the pod restarted.
4. **Parameter passthrough gap**: The `job.parameters` field in the job submission API is not passed through to adapter containers as environment variables or mounted files. Adapters must read parameters from the job spec JSON at `/meta/job.json`.

## Impact on Strategies

- Strategies involving custom EvalHub providers must account for the `/data` emptyDir override — bake static files at `/app/` or another path
- Any strategy referencing the adapter container contract should specify `/meta/job.json` as the job spec location
- Provider registration requires ConfigMap in `redhat-ods-applications`, not the EvalHub namespace — RBAC and namespace scoping strategies must account for this
- Strategies depending on `job.parameters` passthrough will not work; adapters must parse `/meta/job.json` directly

## Context

The `architecture/rhoai-3.4/eval-hub.md` was generated from EvalHub source code analysis in March 2026. The adapter container contract (mount paths, volume behavior) and custom provider registration mechanism are runtime behaviors discovered through integration testing, not visible in source analysis alone. This overlay captures operational knowledge from building and deploying the first custom provider (agent-eval-harness).

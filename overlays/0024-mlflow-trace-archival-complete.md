---
id: "0024"
title: MLflow trace archival is delivered as an operator-managed capability
status: active
created: 2026-08-13
affects:
  - mlflow
  - mlflow-operator
release:
  - "3.5"
  - "next"
provenance:
  - https://redhat.atlassian.net/browse/RHAIRFE-2051
  - https://redhat.atlassian.net/browse/RHAISTRAT-1920
  - https://github.com/red-hat-data-services/mlflow-operator/blob/main/README.md
  - https://github.com/red-hat-data-services/mlflow-operator/blob/main/api/v1/mlflow_types.go
  - https://github.com/red-hat-data-services/mlflow-operator/blob/main/charts/mlflow/templates/trace-archival-cronjob.yaml
  - https://github.com/red-hat-data-services/mlflow/blob/main/docs/docs/genai/tracing/observe-with-traces/archive-traces.mdx
  - https://github.com/red-hat-data-services/mlflow/blob/main/mlflow/tracing/constant.py
author: Matthew Prahl
superseded_by: null
---

## Fact

MLflow trace archival is a delivered capability for RHOAI that moves older
trace span payloads out of the SQL tracking store and into a configured
artifact repository while keeping trace metadata and trace detail views
available through the same MLflow UI and APIs. In downstream RHOAI
deployments, this feature is exposed declaratively on the `MLflow` custom
resource as `spec.traceArchival` and executed by the operator as a dedicated
`mlflow-trace-archival` CronJob with a mounted archival config, rather than by
the MLflow server's in-process scheduler.

The delivered behavior includes policy resolution across server, workspace, and
experiment scopes; server-side limits such as `maxTracesPerPass` and
`longRetentionAllowlist`; archived-trace state tracking via
`mlflow.trace.spansLocation=ARCHIVE_REPO`; and user-visible limitations after
archival. Archived traces remain readable, but searches that depend on span
payloads such as `trace.text` and `span.content` stop working, and new spans
cannot be appended to an archived trace.

## Impact on Strategies

- Strategies that discuss MLflow tracing should model trace storage as a
  tiered design: SQL retains trace metadata and archive pointers, while the
  archived span payloads move to object storage or another configured artifact
  repository.
- Strategies should treat trace archival as an operator-managed platform
  capability, not as an always-on in-server background worker. In RHOAI, the
  operator keeps `MLFLOW_SERVER_ENABLE_JOB_EXECUTION=false` and runs archival
  externally via a dedicated CronJob.
- Strategies that reason about retention policy need to account for the
  hierarchy documented by the shipped MLflow implementation: server defaults,
  optional workspace overrides, and experiment-level retention overrides, with
  `longRetentionAllowlist` gating longer experiment retention than the broader
  policy.
- Search, troubleshooting, and UX strategies must account for archived-trace
  limitations: archived traces still open normally, but payload-based search is
  no longer complete and archived traces reject new span writes.
- Admin and automation strategies should use the `MLflow` CR as the RHOAI
  control surface for archival scheduling, location, retention, and batch
  sizing. The capability is not just a generic upstream MLflow runtime fact; it
  is a downstream operator-integrated feature with dedicated Kubernetes
  resources and RBAC.

## Context

The generated RHOAI 3.5 architecture snapshots already mention trace archival
in places, but they do not yet capture the full delivered architecture and
operating constraints. `architecture/rhoai-3.5/mlflow-operator.md` mentions
trace archival CronJobs at a high level without describing the execution model,
policy surface, or archived-trace limitations. `architecture/rhoai-3.5/mlflow.md`
mentions per-workspace trace archival configuration but not the broader
retention hierarchy or the post-archival behavior change.

This overlay bridges that RHOAI 3.5 documentation gap until a future
architecture regeneration captures the full trace archival design from the
downstream `mlflow` and `mlflow-operator` repositories.

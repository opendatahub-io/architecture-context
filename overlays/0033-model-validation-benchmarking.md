---
id: "0033"
title: Model Validation & Benchmarking missing from component inventory
status: active
created: 2026-11-25
affects:
  - platform
release:
  - "all"
provenance:
  - https://github.com/Jounce-IO/jounce/blob/0814bb0881e051fcf4692e2dcf908412c3fe4963/docs/0027-model-validation-benchmarking.md
  - https://github.com/Jounce-IO/jounce
  - https://github.com/Jounce-IO/model-packaging-pipeline
author: Joseph Berry
superseded_by: null
---

## Fact

**Model Validation & Benchmarking** (Jounce/JBenchmark, `github.com/Jounce-IO/jounce`)
is an AIPCC component for evaluating and validating LLM inference and deployment
health, submitting security/safety evaluations, and tracking experiment results
across multiple hardware targets and GPU configurations.

Model Validation Pipeline is an AIPCC component which validates models on top of
Red Hat products. Each model which begins as a HuggingFace repo under the RedHatAI
organization is packaged into OCI and ModelCar artifacts. While packaging, the
model's files are scanned for security vulnerabilities with static security
scanning tools. Then the ModelCar artifacts are taken through the Validation
process which is comprised of Smoke Tests, Performance Benchmarks, AI Safety
(Red Teaming) & Quality Evaluations.

Model Validation Pipeline does not appear in the RHOAI Architecture Component Inventory because the
architecture generation pipeline discovers repositories only within the
`red-hat-data-services` and `opendatahub-io` GitHub organizations. `Jounce-IO/jounce`
is outside that discovery scope and has no mirror in either org.
Moreover, it is not a component that is shipped with the RHOAI product, but an internal pipeline that supplies confidence in RH artifacts and augmented data.

### Platform Architecture

Model Validation Pipeline, also known as JBenchmark, is a Kubernetes-native monorepo (`apps/jbenchmark/`) built from
10 microservices and 6 shared libraries, deployed with Helm and orchestrated by
Argo Workflows. A central FastAPI service (`api_server`) manages experiment
definitions and lifecycle; nine fire-and-exit CLI services run as Argo Workflow
step containers. The API image also runs a separate gateway-protected visibility
Model Context Protocol (MCP) server that exposes read-only benchmark, experiment,
release, and model data to tooling clients over `/mcp`.

**Infrastructure requirements:**

| Component | Minimum Version |
|---|---|
| OpenShift Container Platform | 4.19 (Kubernetes 1.32) |
| PostgreSQL | 16 |
| Argo Workflows | 3.6.2 |
| Argo Events | 2.4.7 |
| Helm | 3.0 |

**Tech stack:** Python 3.12+ (primary target 3.13), FastAPI, SQLAlchemy ORM with
Atlas migrations, `uv` dependency management.

### Experiment Types

Each experiment is typed at creation. Type determines which Argo WorkflowTemplate
DAG runs and which downstream services activate:

| Type | Workflow Template | Purpose |
|---|---|---|
| `VALIDATION` | `validator.yaml` | vLLM server health + inference smoke test → optional promote-trigger for the validated ModelCar |
| `PERFORMANCE` | `guidellm.yaml` | GuideLLM benchmarking → throughput/latency metrics |
| `EVALHUB_SECURITY` | `evalhub.yaml` | Garak safety evaluations via EvalHub |
| `EVALHUB_ACCURACY` | `evalhub.yaml` | inspect-ai quality evaluations via EvalHub, surfaced to consumers as EvalHub Quality |

### Service Architecture

| Service | Role |
|---|---|
| `api_server` | FastAPI REST API — experiment lifecycle, model management, plan execution, release promotion |
| `validator` | Validates vLLM server health and inference endpoints before benchmarks run |
| `deployment_ingestor` | Records cold-start metrics and machine metadata after the inference server starts |
| `guidellm_ingestor` | Loads GuideLLM benchmark reports (throughput, latency, token counts) into the database |
| `experiment_finalizer` | Finalizes experiment status after all client runs complete |
| `experiment_successful_validator` | Validates experiment completion status post-finalization |
| `promote_trigger` | Dispatches model promotion workflow to the production release pipeline via GitHub App |
| `slack_notify` | Sends formatted Slack notifications for Argo workflow step events |
| `evalhub_client` | Submits security/safety evaluation jobs to EvalHub |
| `vllm_logs_analysis` | Analyzes vLLM error logs via LLM for root-cause analysis |

The visibility MCP server is deployed as a separate process from the same API
image rather than as an Argo Workflow step service. Helm exposes it through an
HAProxy bearer-token gateway when `mcp.enabled` is set.

### Shared Libraries

| Library | Purpose |
|---|---|
| `sql` | Database DAL, ORM entities (`ExperimentPlan`, `Experiment`, `Run`, `Deployment`, `PerformanceMetrics`, etc.), Atlas migrations |
| `common` | Shared utilities: HTTP client, GCS operations, HuggingFace API utils, dict ops |
| `config_generator` | Experiment configuration generation for Argo Workflows |
| `run_estimator` | GPU memory viability estimation; marks infeasible RunPlans as skipped at planning time |

### Experiment Lifecycle

```text
ExperimentPlan  →  Experiment  →  Deployment  →  Run
                       │              │
                       │              └── 1 Argo Workflow per Deployment
                       └── many Deployments (one per model × gpu_count combination)
```

An Experiment is not a Workflow. One experiment fans out to many Deployments;
each Deployment is exactly one Argo Workflow running a live inference server.
A single `gpu_count: [1,2,4,8]` configuration produces four workflows.
Each workflow has multiple Runs based on the Scenarios and the RPS_VALUES

**Status lifecycle:** `CREATED → SUBMITTED / PARTIALLY_SUBMITTED → RUNNING → COMPLETED / PARTIALLY_FAILED / FAILED / CANCELLED`.
Experiment status is derived only after every Deployment's Runs are terminal.

### External Integrations

External systems are outside the JBenchmark deployment and are reached through
their supported APIs, SDKs, or Kubernetes resources. They do not connect directly
to the JBenchmark PostgreSQL database. JBenchmark owns the orchestration and
persists the resulting experiment state locally; the integration adapters below
are the boundary through which data or control crosses into or out of the
platform.

#### External API consumed by External Clients

The Model Validation Platform exposes an external API for consumers outside the
Model Validation Pipeline deployment, including AI Hub, downstream platform teams,
and automated AI systems. These consumers use the API as the supported access
boundary for model-validation data rather than connecting directly to internal
services or databases.

The External API serves curated, released model-validation data from a separate
external database. This includes released model packaging information,
performance benchmarks such as throughput and latency, security and safety
evaluations, quality evaluations, and related metadata. AI Hub and other
consumers use these results to compare and validate models.

The internal `api_server` manages release state and promotion. Its promotion
services select and transform internal results, compare them with the external
database, and apply the approved release changes to that database. Release state
and manifests remain in the internal JBenchmark PostgreSQL database.

Publication and consumption follow separate paths:

```text
Publication:
Internal JBenchmark PostgreSQL
  │  Selected results
  ▼
Internal api_server release/promotion process
  │  Finalized release changes
  ▼
External database

Consumption:
AI Hub and other external API consumers
  │  REST/HTTP
  ▼
External API
  │  Read released data
  ▼
External database
```

External API requests reach the external database without passing through the
internal `api_server` or querying the internal JBenchmark PostgreSQL database.
The external data contract describes the released results; release-management
operations belong to the internal control plane.

#### Visibility MCP server for tooling clients

The visibility MCP server is a gateway-protected, read-only tooling interface for
authenticated developer and automation tools. It serves Streamable HTTP at
`/mcp`, shares the visibility service and SQL DAL with the internal API
implementation, and opens read-only transactions for tool calls.

A basic tool-discovery request lists top-level tools exposed by the server:

```bash
curl -sS "$MCP_URL" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  --data '{"jsonrpc":"2.0","id":"tools","method":"tools/list","params":{}}'
```

Top-level tools include among others `list_labels`, `search_runs`, `summarize_runs`,
`summarize_run_configs`, `list_task_deployments`, `get_run`, `list_experiments`,
`get_experiment`, `compare_performance`, `list_releases`,
`get_release_filter_funnel`, `get_release_manifest_summary`, and `list_models`.

#### External Dependencies

| Integration | Direction | What JBenchmark does |
|---|---|---|
| KServe InferenceService | Consumer through Kubernetes API | Creates or targets inference deployments and validates the resulting vLLM/RHAIIS endpoints |
| GuideLLM | Consumer through workflow container | Runs as the benchmarking client inside the experiment workflow and returns throughput, latency, and token metrics |
| EvalHub (Garak, InspectAI) | Consumer through EvalHub API | Submits `EVALHUB_*` evaluation jobs and reads back evaluation results |
| HuggingFace Hub | Consumer through HuggingFace API | Fetches model metadata and validates model availability and configuration before deployment |
| GitHub App (prod-release) | Producer through GitHub API | `promote_trigger` dispatches the production model release workflow |
| Slack | Producer through Slack API | `slack_notify` sends experiment and workflow event notifications |
| Google Cloud Storage | Producer/Consumer through GCS API | `common` handles benchmark reports and other GCS-backed artifacts |
| Konflux | Consumer through Konflux APIs and release artifacts | Tracks OCI and ModelCar production-release steps in the model packaging pipeline |

### Internal Interfaces and Data Stores

The internal boundary contains the JBenchmark control plane and its authoritative
data store. The internal `api_server` validates control-plane requests and
coordinates work, while the worker services run
inside Argo Workflows and use the shared SQL data-access layer. No external
integration is expected to bypass this boundary and write directly to PostgreSQL.

```text
Internal control-plane consumers
        │ REST/HTTP
        ▼
    api_server ────── internal service calls / Argo events ──────► worker services
        │                                                         │
        │ SQLAlchemy DAL                                          │ SQLAlchemy DAL
        ▼                                                         ▼
                         JBenchmark PostgreSQL
```

| Interface or store | Boundary and access | What JBenchmark does |
|---|---|---|
| `api_server` REST API | Internal control-plane interface; platform consumers access it over REST/HTTP | Validates requests and exposes experiment, run, deployment, metrics, and evaluation data |
| Argo Workflows and Events | Internal orchestration interface; worker services access it in-cluster | Starts experiment workflows, fans out deployments and runs, and delivers workflow events to JBenchmark services |
| Worker services | Internal service boundary; deployed in the JBenchmark namespace | Validate deployments, ingest benchmark/evaluation output, finalize experiments, notify Slack, and trigger promotion |
| PostgreSQL | Internal authoritative data store; accessed through the `sql` library and SQLAlchemy DAL | Persists experiment plans, experiments, deployments, runs, metrics, and evaluation results |
| Visibility MCP server | Gateway-protected read-only tool interface; authenticated tooling clients access Streamable HTTP at `/mcp` | Exposes visibility tools for labels, runs, experiments, releases, and models through the shared visibility service and SQL DAL |
| `benchmark_visibility` | Internal read-oriented consumer of JBenchmark data | Builds operational and historical views without becoming a second system of record |

The distinction is therefore both architectural and operational: APIs and
Kubernetes resources belonging to KServe, EvalHub, HuggingFace, GitHub, Slack,
GCS, and Konflux are external integration points. The internal `api_server`, Argo
control plane, worker services, and internal PostgreSQL database form the
JBenchmark control plane. The External API and its separate database serve
released results. The visibility MCP server is a separate read-only tooling
surface over JBenchmark visibility data, not the External API release path.
Changes to the internal schema must be handled through the data-access layer and
release transformations while preserving the external data contract.

## Impact on Strategies

- Treat Model Packaging & Validation as a AIPCC platform component that provides data for internal platform consumers.
  Absence from the generated component inventory does not indicate
  unclear ownership or unshipped status — it reflects a pipeline discovery gap,
  not a product gap.
- Feasibility reviewers must not flag Jounce/JBenchmark ownership as unclear; it
  is owned and maintained by the Model Validation team within AIPCC.
- RFEs that involve Models for HuggingFace packaged as ModelCars, GuideLLM benchmark data, vLLM inference performance
  measurement, model promotion pipelines, or EvalHub providers (Garak/InspectAI)
  evaluation results should reference this component as the platform
  integration point.
- RFEs proposing changes to KServe InferenceService APIs, vLLM CLI flags, Konflux APIs or
  RHAIIS deployment contracts must account for Model Validation Pipeline (JBenchmark) as a downstream
  consumer: the `validator` service probes deployed inference servers, and the
  `deployment_ingestor` records cold-start and machine metadata from KServe
  events.
- The `promote_trigger` service is the automated gate that dispatches model
  promotion to the production release pipeline after a successful VALIDATION
  experiment. Strategies proposing changes to model promotion flows must trace
  this integration.
- Model Validation Pipeline (aka JBenchmark) is Kubernetes-native and targets KServe or standalone deployments on top of OpenShift. Strategies
  proposing infrastructure changes (GPU scheduling, Argo Workflows version bumps,
  KServe CRD changes) must account for JBenchmark's declared minimum requirements
  (see "Infrastructure requirements" section).
- Benchmark data (throughput, latency, token counts) and evaluation
  results (EvalHub jobs) are stored in JBenchmark's PostgreSQL instance and
  exposed via the `api_server` REST API and `benchmark_visibility` dashboards.
  Internal analysis uses these interfaces for historical benchmark data and
  evaluation results. Consumers of released results, including AI Hub, use the
  External API backed by the separate external database.

## Context

The RHOAI architecture generation pipeline discovers components via manifest
parsing and org-scoped repo enumeration (`red-hat-data-services` and
`opendatahub-io`). `Jounce-IO/jounce` is outside the enumerated orgs and has
no upstream or downstream mirror in either. The Phase 5 aggregation agent
therefore does not include Model Validation & Benchmarking in the component
inventory.

This overlay is an interim patch so that rfe-creator feasibility reviews,
architecture consumers, and strategy pipelines have accurate component
visibility. It should be superseded once `Jounce-IO/jounce` migrates to a
discoverable org or `platforms.yaml` is updated with an `extra_repos` entry
pointing to the Jounce repository.

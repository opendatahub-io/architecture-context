# Adjudicated-to-Zero Mutation Component Approval

Date: 2026-07-20

## Summary

Evaluated three components whose historical agent corrections were all
adjudicated as invalid evidence. Two approved for analyzer-only routing; one
deferred.

## Source Audit Results

### caikit-tgis-serving — Approved

Container image build repository with no application source code. Ships two
Dockerfiles and a pyproject.toml declaring three PyPI dependencies. The
container CMD is `python -m caikit.runtime` — the entire runtime is an imported
third-party package. No production deployment manifests exist; all Kubernetes
manifests live under `demo/kserve/custom-manifests/`.

| Category | Empty | Legitimate | Reason |
|----------|:-----:|:----------:|--------|
| authentication | yes | yes | No auth code in shipped artifacts; delegated to Istio sidecar and KServe infrastructure. |
| integration_points | yes | yes | No integration code; caikit.yml configures a third-party library only. |
| internal_dependencies | yes | yes | Consumed as a container image reference by KServe ServingRuntime CRs. |

### distributed-workloads — Approved

Image factory and test harness. Produces container images (training runtimes,
Ray runtimes, universal training images) consumed by reference in other
components' CRs. No operator, no controller, no deployed service, no
Kubernetes deployment manifests. All Go code is e2e test code under `tests/`.

| Category | Empty | Legitimate | Reason |
|----------|:-----:|:----------:|--------|
| authentication | yes | yes | Passive container images with no application-level auth code. |
| internal_dependencies | yes | yes | No production code imports platform component APIs; go.mod deps are test-only. |

### vllm-cpu — Deferred

Shipped FastAPI server (`python -m vllm.entrypoints.openai.api_server`) with a
real `AuthenticationMiddleware` at `vllm/entrypoints/openai/server_utils.py:38-86`.
The middleware validates Bearer tokens with SHA-256 hash comparison and
timing-safe `secrets.compare_digest()`. Configured via `--api-key` CLI arg or
`VLLM_API_KEY` env var.

| Category | Empty | Legitimate | Reason |
|----------|:-----:|:----------:|--------|
| authentication | yes | **no** | Server implements ASGI AuthenticationMiddleware with Bearer token validation. |
| integration_points | yes | **no** | Runtime uses aiohttp/requests/httpx for HuggingFace Hub, MCP tool servers, distributed KV transfer. |
| internal_dependencies | yes | **no** | ~25 critical Python runtime dependencies not captured by Dockerfile-only analysis. |

Blocker: Python runtime extraction task
(`docs/tasks/pending/extract-python-runtime-source-surfaces.md`).

## Implementation

Added `source_audited_empty_categories` mechanism to
`lib/analyzer_correction_adjudications.json` and
`lib/architecture_routing.py`. Source-audited category entries follow the same
evidence requirements as accepted analyzer absences: component name, category,
reason, and evidence paths.

The `analyzer_only_eligibility` function now accepts a `source_audited`
parameter that supplements contract-complete empty categories. Both the routing
policy and the eligibility replay script pass source audit data.

## Validation

- 90-component eligibility replay: 0 false nominations (39 eligible, up from 37)
- caikit-tgis-serving production matrix: analyzer-only route, 0 agent
  invocations, 0.03s wall time
- distributed-workloads production matrix: analyzer-only route, 0 agent
  invocations, 0.03s wall time
- All 126 unit tests pass

## Artifacts

- Eligibility replay: `tmp/eligibility-post-approval.json`
- caikit-tgis-serving matrix: `tmp/architecture-corpus-runs/rhoai.next-20260721T010117Z-271074/`
- distributed-workloads matrix: `tmp/architecture-corpus-runs/rhoai.next-20260721T010125Z-271333/`

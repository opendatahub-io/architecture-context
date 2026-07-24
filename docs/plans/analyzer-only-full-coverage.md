# Analyzer-Only Full Coverage

**Status**: Active

Expand analyzer-only routing from 39/90 to the maximum achievable coverage
by resolving the 79 extraction-targetable mutations across 19
analyzer-sufficient components. Task 1 (adjudicated-to-zero approval) and
Task 2 (permanent residual classification) are complete.

## Scope

This plan covers the 21 remaining non-approved components from the residual
register (`docs/notes/analyzer-residual-agent-gaps.md`). Of these, 4 are
permanent agent residuals (classified, no further action), and the remaining
21 are extraction-targetable with 79 unresolved mutations.

A second population of 26 components (18 evidence-gated partial + 8 legacy)
is NOT analyzer-sufficient and requires separate scoping. That work is out of
scope for this plan.

## Starting Point

The v1 baseline (commit `0920cf3b`, 2026-07-20) established 37 approved
components. After Task 1 (adjudicated-to-zero approval) and Task 2
(permanent residual classification), the current state is:

| Tier | Components |
|------|:----------:|
| Analyzer-only (approved) | 39 |
| Permanent agent residual | 4 |
| Evidence-gated sufficient | 21 |
| Evidence-gated partial | 18 |
| Legacy | 8 |

The 21 extraction-targetable sufficient components decompose into:

| Disposition | Components | Mutations |
|-------------|:----------:|----------:|
| Adjudicated invalid evidence — deferred | 1 | 0 (3 adjudicated) |
| Empty categories, pending extraction | 1 | 0 |
| Python runtime extraction | 3 | 13 |
| Go runtime source | 7 | 16 |
| Manifest/deployment | 4 | 18 |
| Python dependency declaration | 4 | 24 |
| Go gRPC | 1 | 8 |

## Permanent Residuals

Four components cannot be made analyzer-only for structural reasons:

| Component | Reason |
|-----------|--------|
| `rhods-operator` | Deliberate prose residual. Hierarchical lifecycle, fan-out provisioning, and cross-component data-flow narrative are not represented by deterministic structured facts. |
| `ogx` | Unsupported languages. Internal Dependencies blocked by shell (12 build/CI scripts) and iOS Swift (5 files). Auth resolved (5 facts). |
| `notebooks` | Bundled-library inventory. 19 mutations from requirements.txt represent user-available tools, not runtime service integration. No shipped application entrypoint. |
| `notebooks-downstream` | Same as `notebooks`. 1 mutation from pinned library versions. |

## Task Sequence

### Phase 1: Zero-Code Wins (COMPLETE)

#### Task 1: Approve adjudicated-to-zero components (DONE)

caikit-tgis-serving and distributed-workloads approved via source-audited
empty category mechanism. vllm-cpu deferred — real `AuthenticationMiddleware`
requires Python runtime extraction (depends on Task 3).

**Task file:** `docs/tasks/done/approve-adjudicated-zero-mutation-components.md`
**Yield:** 2 components approved. See [validation note](../notes/adjudicated-zero-mutation-approval-2026-07-20.md).

#### Task 2: Classify permanent residuals (DONE)

`notebooks`, `notebooks-downstream`, `ogx`, and `rhods-operator` formally
classified as permanent agent residuals. 20 mutations removed from extraction
backlog (99 → 79).

**Task file:** `docs/tasks/done/classify-permanent-residual-components.md`
**Yield:** 0 approvals (scope cleanup).

### Phase 2: Python Runtime Extraction

#### Task 3: Extract Python runtime source surfaces (EXISTS)

Already specified at `docs/tasks/pending/extract-python-runtime-source-surfaces.md`.

Targets: `mlflow` (5 mutations), `NeMo-Guardrails` (4), `llm-d-latency-predictor`
(4), `lm-evaluation-harness` (0 mutations, empty categories).

Two extraction contracts in `src/arch-analyzer/internal/pythonsource/`:
1. FastAPI route absence-of-auth
2. Outbound SDK client construction

**Expected yield:** 3-4 components. **Effort:** Medium.

### Phase 3: Go Runtime Source Extraction

#### Task 4: Extract Go runtime source surfaces

Extends existing Go extractors in `src/arch-analyzer/internal/gosource/` for
patterns not yet covered by prior extraction tasks.

| Component | Mutations | Pattern |
|-----------|----------:|---------|
| `ai-gateway-payload-processing` | 7 | Controller-runtime reconciler; CRD auth enum patterns |
| `argo-workflows` | 3 | Go OIDC/OAuth2 middleware; DSP operator config injection |
| `rhaii-cluster-validation` | 2 | CLI controller with CRD inspection and GPU discovery |
| `eval-hub` | 1 | Go interface dispatch for KubernetesHelper.GetHardwareProfile |
| `llm-d-async` | 1 | Go module dependency with runtime import (gateway-api types) |
| `llm-d-kv-cache` | 1 | Runtime import (post-adjudication residual from examples/) |
| `kube-auth-proxy` | 1 | TokenReview client construction at `pkg/authentication/` |

Required contracts:
- Controller-runtime reconciler registration with CRD watch patterns
- OIDC/OAuth2 middleware chain detection
- CLI controller component patterns with CRD inspection
- Go module dependency-with-runtime-import verification
- Go interface dispatch resolution for typed client operations (stretch)

**Task file:** `docs/tasks/pending/extract-go-runtime-source-surfaces.md`
**Expected yield:** 4-6 components. **Effort:** Medium-high.

### Phase 4: Manifest/Deployment Residuals

#### Task 5: Resolve manifest/deployment residuals

The original manifest extraction task is done (`docs/tasks/done/extract-kubernetes-manifest-authentication-dependencies.md`,
3/27 by analyzer, 24/27 adjudicated). These 18 remaining mutations need
capabilities beyond the generic manifest contracts.

| Component | Mutations | Blocker |
|-----------|----------:|---------|
| `trustyai-explainability` | 7 | Java/Quarkus probe handlers (unsupported language); init container behavior; annotation-based Prometheus |
| `llm-d-planner` | 6 | Python env-var service bindings (PostgreSQL, Ollama); optional credentials (Vertex, OpenAI, HF, Model Catalog) |
| `rhoai-mcp` | 3 | Python MCP framework handler-to-probe correlation |
| `llm-d-routing-sidecar` | 2 | Unresolved kustomize template variables; absence-only TLS evidence |

Notes:
- `trustyai-explainability` has Java/Quarkus source. Some gaps (probe handlers)
  are permanent unsupported-language residuals.
- `llm-d-planner` benefits from Task 3's Python runtime extraction for env-var
  to client correlation.

**Task file:** `docs/tasks/pending/resolve-manifest-deployment-residuals.md`
**Expected yield:** 2-3 components. **Effort:** Medium.
**Dependency:** Benefits from Task 3.

### Phase 5: Go gRPC Residuals

#### Task 6: Resolve Go gRPC residuals

Single component: `modelmesh-runtime-adapter` (8 mutations). Original task
done (`docs/tasks/done/extract-modelmesh-runtime-relationships.md`, 6/10 by
analyzer, 4/10 adjudicated).

Remaining gaps:
- Caller-identity knowledge for inbound gRPC (modelmesh as caller)
- Module path self-reference vs. modelmesh-serving dependency
- Product-semantic integration point naming

These are structural limitations: the analyzer cannot derive caller identity
or product-level naming from the adapter's source alone.

**Task file:** `docs/tasks/pending/resolve-go-grpc-residuals.md`
**Expected yield:** 0-1 components. **Effort:** High.

### Phase 6: Python Dependency Declaration (DEFERRED)

#### Task 7: Extract Python dependency-import relationships

Highest-complexity tranche. Requires building Python import resolution
capability comparable to the Go AST analysis in `gosource/`.

| Component | Mutations | Pattern |
|-----------|----------:|---------|
| `MLServer` | 8 | gRPC service registration from proto; pyproject.toml dependency-with-import |
| `caikit` | 8 | gRPC service from proto; optional pyproject.toml group analysis |
| `kubeflow-sdk` | 5 | Python import-and-construction for pyproject.toml optional extras |
| `codeflare-sdk` | 3 | Python import-and-construction for pyproject.toml deps |

Required infrastructure:
- Python AST parsing or regex-based import tracing
- Resolution of optional extras vs. required dependencies
- Call graph from shipped entrypoints through import chains to client
  construction sites
- Proto-to-Python gRPC service registration correlation

**Recommendation:** Defer. Classify these 4 components as "justified agent
residual pending Python import analysis capability." Revisit after Tasks 1-6
are complete. The infrastructure investment may be warranted if the remaining
partial/legacy scoping (26 additional components) also needs Python analysis.

**Task file:** `docs/tasks/pending/extract-python-dependency-import-relationships.md`
**Expected yield:** 0-2 components. **Effort:** Very high.
**Dependency:** Requires Task 3.

## Projected Outcomes

| Phase | Target | Likely approvals | Running total |
|-------|:------:|:----------------:|:-------------:|
| v1 Baseline | - | - | 37 |
| Task 1: Adjudicated-to-zero | 3 | 2 (done) | 39 |
| Task 2: Permanent residual | 4 | 0 (done, classify) | 39 |
| Task 3: Python runtime | 4 (+vllm-cpu) | 3-5 | 42-44 |
| Task 4: Go runtime source | 7 | 4-6 | 46-50 |
| Task 5: Manifest residual | 4 | 2-3 | 48-53 |
| Task 6: Go gRPC | 1 | 0-1 | 48-54 |
| Task 7: Python dependency | 4 | 0-2 | 48-56 |

**Ceiling:** 60/90 (67%) — 4 permanent residuals set the maximum at 86
minus the 26 partial/legacy components that are out of scope.
**Realistic without Task 7:** 50-54/90 (56-60%)
**Realistic with Task 7:** 50-56/90 (56-62%)
**After partial/legacy scoping:** up to 86/90 (96%)

## Dependencies

```
Task 1 (adjudicated-to-zero) ──── no dependencies
Task 2 (permanent residual) ───── no dependencies
Task 3 (Python runtime) ────────── no dependencies
Task 4 (Go runtime) ──────────── no dependencies
Task 5 (manifest residual) ────── benefits from Task 3
Task 6 (Go gRPC) ──────────────── no dependencies
Task 7 (Python dependency) ────── requires Task 3
```

Tasks 1-4 and 6 can proceed in parallel. Task 5 benefits from Task 3
completing first (llm-d-planner env-var correlation). Task 7 requires
Task 3's Python source analysis infrastructure.

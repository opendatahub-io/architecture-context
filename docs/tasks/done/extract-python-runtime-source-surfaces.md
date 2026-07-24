# Task: Extract Python Runtime Source Surfaces

## Goal

Extract Python FastAPI route authentication surfaces and outbound SDK client
construction patterns from shipped Python entrypoints, enabling analyzer-only
routing for components where the only remaining gaps are Python runtime source
evidence.

## Motivation

After the v1 adjudication pass, 13 unresolved mutations remain across 3
components (mlflow, NeMo-Guardrails, llm-d-latency-predictor) with strong
evidence from shipped Python source. A fourth component (lm-evaluation-harness)
has zero mutations but empty Authentication and Internal Dependencies categories
whose gaps are Python outbound client credentials. A fifth component (vllm-cpu)
was deferred from the adjudicated-to-zero approval because it implements a real
`AuthenticationMiddleware` at `vllm/entrypoints/openai/server_utils.py:38-86`
with Bearer token validation and SHA-256 timing-safe comparison.

The Python dynamic authentication middleware contract (ASGI registration,
provider factory, ABAC enforcement) already exists. This tranche extends Python
extraction to cover:

1. FastAPI route registration with explicit absence-of-auth middleware.
2. Outbound SDK client construction (credential env-var sourcing, typed client
   instantiation, and API call execution).

## Bounded Start

- Eligibility report:
  `tmp/architecture-corpus-runs/rhoai.next-20260720T173035Z-static/reports/eligibility-v1.json`
- Prioritization: Cluster E in
  `docs/notes/analyzer-remaining-candidate-prioritization-2026-07-19.md`
- Existing Python auth contract:
  `docs/notes/python-dynamic-authentication-middleware-validation-2026-07-20.md`

## Scope

### Target Components

| Component | Mutations | Evidence quality | Pattern |
|-----------|----------:|------------------|---------|
| `mlflow` | 5 | Strong: `mlflow/gateway/app.py` shipped source | FastAPI routes without auth middleware |
| `NeMo-Guardrails` | 4 | Medium: `nemoguardrails/embeddings/providers/azureopenai.py`, `actions_server.py` | Azure OpenAI SDK client, ActionDispatcher |
| `llm-d-latency-predictor` | 4 | Strong: `src/llm_d_latency_predictor/prediction_server.py` | FastAPI + HTTP client construction |
| `lm-evaluation-harness` | 0 | Strong: `lm_eval/models/anthropic_llms.py`, `openai_completions.py` | Outbound client credentials (empty category) |
| `vllm-cpu` | 0 | Strong: `vllm/entrypoints/openai/server_utils.py:38-86` | ASGI AuthenticationMiddleware, Bearer token validation, outbound HTTP clients |

### Extraction Contracts

1. **FastAPI route absence-of-auth**: Detect FastAPI `app = FastAPI()` with route
   registration (`@app.get`, `@app.post`, `app.include_router`) where no auth
   middleware or dependency injection is present.
2. **Outbound SDK client construction**: Detect `os.environ.get("*_API_KEY")` or
   `os.getenv("*_KEY")` fed into typed SDK client constructors
   (`openai.OpenAI(api_key=...)`, `anthropic.Anthropic(api_key=...)`) with
   downstream API call execution.

### Negative Controls

- Must not conflate rate limiter (slowapi) with authentication.
- Must not treat optional HF_TOKEN as required authentication surface.
- Must not promote configurable external services as guaranteed platform
  dependencies.
- Must not accept dynamic action loading (ActionDispatcher) inventory without
  concrete runtime evidence per action.
- Must not accept analyzer baseline output as source evidence.

## Acceptance Criteria

- [ ] Each new extraction contract has unit tests with positive and negative cases.
- [ ] The 90-component static replay produces zero false nominations.
- [ ] Target components gain structured facts reducing or eliminating their
  empty high-value categories.
- [ ] No non-target component's facts change.

## Likely Files

- `src/arch-analyzer/internal/pythonsource/authposture.go` (auth posture detection)
- `src/arch-analyzer/internal/pythonsource/sdkclients.go` (SDK client extraction)
- `src/arch-analyzer/internal/pythonsource/authentication.go` (starlette + regex fixes)
- `src/arch-analyzer/internal/pythonsource/routes.go` (wiring)
- `src/arch-analyzer/internal/pythonsource/pythonsource_test.go` (12 new tests)

## Status

Done. Completed 2026-07-21.

Validation: [python-runtime-source-surfaces-validation-2026-07-21.md](../../notes/python-runtime-source-surfaces-validation-2026-07-21.md)

## Acceptance Criteria Results

- [x] Each new extraction contract has unit tests with positive and negative cases (12 new tests, 24 total pass).
- [x] The 90-component static replay produces zero false nominations (39 nominations, 0 false).
- [x] Target components gain structured facts reducing their empty high-value categories (auth facts for mlflow, llm-d-latency-predictor, vllm-cpu; SDK connection for NeMo-Guardrails).
- [ ] Target components not yet eligible — remaining `internal_dependencies` and `integration_points` gaps require separate tasks.

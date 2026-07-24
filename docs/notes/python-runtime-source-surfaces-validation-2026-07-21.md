# Python Runtime Source Surfaces Validation

Date: 2026-07-21

Task: [Extract Python runtime source surfaces](../tasks/done/extract-python-runtime-source-surfaces.md)

## Summary

Implemented two new Python source extraction contracts in `src/arch-analyzer/internal/pythonsource/`:

1. **FastAPI auth posture detection** (`authposture.go`): Post-processing step
   that emits an absence-of-auth fact when Python HTTP endpoints exist but no
   Python-sourced auth facts are found. Also handles the positive case via
   widened regex patterns in `authentication.go` for Starlette
   `AuthenticationMiddleware` detection.

2. **Outbound SDK client construction** (`sdkclients.go`): Two-phase regex
   extraction matching known SDK constructors (OpenAI, Anthropic, Azure OpenAI,
   IBM Watsonx) with environment-variable credential arguments. Emits
   `ExternalConnection` facts with `Type: "SDK client"`.

## New Files

| File | Lines | Purpose |
|------|------:|---------|
| `authposture.go` | 50 | Absence-of-auth / presence-of-auth post-processing |
| `sdkclients.go` | 82 | SDK client constructor + env-var credential extraction |

## Modified Files

| File | Change |
|------|--------|
| `authentication.go` | Added starlette `AuthenticationMiddleware` handling (library-defined class), widened `pyDenialRe` to match `status_code=401\|403`, widened `pyTokenValRe` to match `verify_token` |
| `routes.go` | Extended `authMarker` for `Depends(get_current_user\|verify_token\|...)`, wired SDK client + auth posture calls |
| `pythonsource.go` | Updated Coverage string |

## Test Results

24 tests pass (12 existing + 12 new):

| Test | Scenario | Result |
|------|----------|--------|
| `TestAuthPostureNoAuth` | FastAPI routes, no auth | Absence-of-auth fact emitted |
| `TestAuthPostureWithAuthMarker` | Routes + OAuth2PasswordBearer | No absence fact |
| `TestAuthPostureWithMiddleware` | testdata/auth_app | No absence fact (5 auth facts) |
| `TestStarletteAuthMiddleware` | Starlette library import + add_middleware | Starlette auth fact emitted |
| `TestSlowAPINotAuth` | FastAPI + SlowAPI rate limiter | Absence-of-auth (rate limiter ≠ auth) |
| `TestDependsAuth` | Depends(get_current_user) | Auth marker, no absence |
| `TestSDKClientOpenAI` | openai.OpenAI(api_key=os.environ.get) | 1 connection: OpenAI |
| `TestSDKClientAnthropic` | Anthropic(api_key=os.getenv) | 1 connection: Anthropic |
| `TestSDKClientAzure` | AzureOpenAI(api_key=...) | 1 connection: Azure OpenAI |
| `TestSDKClientMultiple` | OpenAI + Anthropic in same file | 2 connections |
| `TestSDKClientNoEnvVar` | OpenAI(api_key=config.key) | No connection |
| `TestHFTokenNotSDKClient` | os.environ.get("HF_TOKEN") without SDK | Secret only, no connection |

## Corpus Validation

90-component static replay (`rhoai.next-20260721T015309Z-static-v2`):

| Measure | Result |
|---------|-------:|
| Components extracted | 90 |
| Extraction failures | 0 |
| Analyzer-only nominations | 39 |
| False nominations | 0 |

## Target Component Results

| Component | Auth facts | SDK connections | Auth posture | Eligible |
|-----------|:----------:|:--------------:|--------------|----------|
| mlflow | 1 | 0 | Absence-of-auth (mlflow/gateway/app.py:301) | No (internal_dependencies gap) |
| NeMo-Guardrails | 1 | 1 (Azure OpenAI) | Auth marker detected | No (internal_dependencies gap) |
| llm-d-latency-predictor | 1 | 0 | Absence-of-auth (prediction_server.py:1171) | No (integration_points, internal_dependencies gaps) |
| lm-evaluation-harness | 0 | 0 | N/A (no Python endpoints) | No (authentication, internal_dependencies gaps) |
| vllm-cpu | 1 | 0 | Bearer token (ASGI middleware AuthenticationMiddleware) | No (integration_points, internal_dependencies gaps) |

## Why Target Components Are Not Yet Eligible

All five target components have `sufficient` readiness and the Python extraction
contracts resolved the authentication category gaps. However, they remain
ineligible due to bounded correction gaps in `internal_dependencies` and/or
`integration_points` — pre-existing gaps unrelated to Python source extraction.

These require separate work tracked in:
- [Extract Go runtime source surfaces](../tasks/pending/extract-go-runtime-source-surfaces.md)
- [Resolve manifest/deployment residuals](../tasks/pending/resolve-manifest-deployment-residuals.md)
- [Extract Python dependency-import relationships](../tasks/pending/extract-python-dependency-import-relationships.md)

## Negative Controls Verified

- **SlowAPI rate limiter**: Not matched by auth patterns; absence-of-auth correctly fires.
- **HF_TOKEN**: Detected as Secret only; no SDK constructor match.
- **Dynamic ActionDispatcher**: No extraction (no concrete constructor or ABAC gating).
- **Configurable external services**: SDK connections emit as `ExternalConnection`, not `InternalDependency`.

## vllm-cpu Regex Fix

The existing `authentication.go` regexes were too narrow for vllm-cpu's
`AuthenticationMiddleware`:
- `pyDenialRe`: Added `status_code=401|403` (was only matching quoted "401").
- `pyTokenValRe`: Added `verify_token` (was only matching `validate_token`).
These fixes are general improvements that apply to any Python middleware using
these common patterns.

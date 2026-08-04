# Architecture Changes: guardrails-detectors

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | integration_points | vLLM Inference Server :: HTTP client | * | <empty> | <empty> | LLM Judge detector makes outbound HTTP calls to a vLLM server configured via VLLM_BASE_URL environment variable | detectors/llm_judge/detector.py:25-37 |
| add | integration_points | FMS Guardrails Orchestrator :: HTTP server | * | <empty> | <empty> | Detectors are designed as backend services for the FMS Guardrails Orchestrator, which calls /api/v1/text/contents and /api/v1/text/generation | detectors/pyproject.toml:5, detectors/built_in/app.py:42, detectors/llm_judge/app.py:36 |
| add | internal_dependencies | vLLM Serving Infrastructure | * | <empty> | <empty> | LLM Judge detector requires a running vLLM inference server as a runtime dependency | detectors/llm_judge/detector.py:25-37 |
| add | internal_dependencies | FMS Guardrails Orchestrator | * | <empty> | <empty> | All detector variants are designed to be invoked by the guardrails orchestrator pipeline | detectors/pyproject.toml:5 |

# Architecture Changes: vllm-cpu

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| delete | authentication | HTTP API :: All | * | <empty> | <empty> | Replace with prefix-specific authentication rows reflecting conditional enforcement and guarded prefix behavior | vllm/entrypoints/serve/utils/server_utils.py:41, vllm/entrypoints/openai/api_server.py:258 |
| add | authentication | /v1/*, /v2/*, /inference/* :: All (except OPTIONS) | * | <empty> | <empty> | Authentication is conditionally enforced via ASGI middleware only for guarded prefix paths when API key is configured | vllm/entrypoints/serve/utils/server_utils.py:41-92, vllm/entrypoints/openai/api_server.py:258-261 |
| add | authentication | /health, /ready, /readyz, /load, /docs :: All | * | <empty> | <empty> | Health and status endpoints are outside the GUARDED_PREFIX and are always unauthenticated for probe accessibility | vllm/entrypoints/serve/utils/server_utils.py:41-92 |
| add | integration_points | S3-compatible storage :: REST API (boto3) | * | <empty> | <empty> | S3 integration for model weight storage via boto3 client with path-based access | vllm/transformers_utils/s3_utils.py:13-15 |
| add | integration_points | HuggingFace Hub :: REST API (huggingface_hub) | * | <empty> | <empty> | Model and LoRA adapter downloading via HuggingFace Hub API, registered as plugin entrypoints | pyproject.toml:46-48 |

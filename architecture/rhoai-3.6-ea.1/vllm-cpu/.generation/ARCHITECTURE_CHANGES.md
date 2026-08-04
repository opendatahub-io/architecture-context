# Architecture Changes: vllm-cpu

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | grpc_services | VllmEngine | * | <empty> | <empty> | gRPC server entrypoint registers VllmEngine service via smg-grpc-servicer on default port 50051 | vllm/entrypoints/grpc_server.py:101 |
| add | grpc_services | grpc.health.v1.Health | * | <empty> | <empty> | gRPC health service registered for Kubernetes probe support | vllm/entrypoints/grpc_server.py:104-105 |
| update | authentication | HTTP API :: All | Endpoint | HTTP API | HTTP API (/v1, /v2, /inference prefixed paths) | Authentication middleware only guards paths starting with GUARDED_PREFIX; non-prefixed paths bypass auth | vllm/entrypoints/serve/utils/server_utils.py:41, vllm/entrypoints/serve/utils/server_utils.py:89 |
| update | authentication | HTTP API :: All | Auth Mechanism | Bearer token | Bearer token (SHA-256 constant-time comparison) | Token verification uses hashlib.sha256 with secrets.compare_digest for constant-time comparison | vllm/entrypoints/serve/utils/server_utils.py:58, vllm/entrypoints/serve/utils/server_utils.py:69-73 |
| update | authentication | HTTP API :: All | Policy | Source-defined authentication | Conditional — only enforced when --api-key or VLLM_API_KEY is set | Middleware is only added when tokens list is non-empty from CLI arg or env var | vllm/entrypoints/openai/api_server.py:258-261 |
| add | authentication | HTTP API (non-prefixed paths: /health, /ready, /readyz, /load, /docs) :: All | * | <empty> | <empty> | Health and operational endpoints are not guarded by AuthenticationMiddleware due to GUARDED_PREFIX check | vllm/entrypoints/serve/utils/server_utils.py:41, vllm/entrypoints/serve/utils/server_utils.py:89 |
| add | authentication | gRPC API :: All | * | <empty> | <empty> | gRPC server binds insecure port with no authentication middleware | vllm/entrypoints/grpc_server.py:118 |
| add | integration_points | HuggingFace Hub :: HTTPS client | * | <empty> | <empty> | vLLM downloads model weights and tokenizers from HuggingFace Hub at startup; controllable via HF_HUB_OFFLINE env var | Dockerfile.cpu.ubi:153, Dockerfile.konflux.cpu:76 |
| add | integration_points | RHOAI Usage Stats :: HTTPS client | * | <empty> | <empty> | Konflux Dockerfile configures usage stats reporting to console.redhat.com RHOAI stats endpoint | Dockerfile.konflux.cpu:78 |
| add | internal_dependencies | KServe / ModelMesh | * | <empty> | <empty> | vllm-cpu is deployed as a serving runtime container managed by the RHOAI serving infrastructure | Dockerfile.konflux.cpu:106, Dockerfile.cpu.ubi:106 |

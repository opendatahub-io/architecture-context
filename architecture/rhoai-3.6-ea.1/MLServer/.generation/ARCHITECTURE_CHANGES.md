# Architecture Changes: MLServer

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | http_endpoints | GET :: /v2/health/live | * | <empty> | <empty> | V2 Inference Protocol liveness endpoint registered in FastAPI router | mlserver/rest/app.py:141 |
| add | http_endpoints | GET :: /v2/health/ready | * | <empty> | <empty> | V2 Inference Protocol readiness endpoint registered in FastAPI router | mlserver/rest/app.py:142 |
| add | http_endpoints | GET :: /v2 | * | <empty> | <empty> | V2 Inference Protocol server metadata endpoint | mlserver/rest/app.py:154 |
| add | http_endpoints | GET :: /v2/models/{model_name}/ready | * | <empty> | <empty> | V2 Inference Protocol model readiness endpoint | mlserver/rest/app.py:63 |
| add | http_endpoints | GET :: /v2/models/{model_name} | * | <empty> | <empty> | V2 Inference Protocol model metadata endpoint | mlserver/rest/app.py:117 |
| add | http_endpoints | POST :: /v2/models/{model_name}/infer | * | <empty> | <empty> | V2 Inference Protocol core inference endpoint | mlserver/rest/app.py:72 |
| add | http_endpoints | POST :: /v2/models/{model_name}/infer_stream | * | <empty> | <empty> | V2 Inference Protocol streaming inference endpoint returning SSE | mlserver/rest/app.py:94 |
| add | http_endpoints | POST :: /v2/models/{model_name}/generate | * | <empty> | <empty> | V2 generate endpoint (alias for infer handler) | mlserver/rest/app.py:83 |
| add | http_endpoints | POST :: /v2/models/{model_name}/generate_stream | * | <empty> | <empty> | V2 streaming generate endpoint (alias for infer_stream handler) | mlserver/rest/app.py:105 |
| add | http_endpoints | GET :: /v2/runtimes | * | <empty> | <empty> | Runtime security information endpoint | mlserver/rest/app.py:159 |
| add | http_endpoints | POST :: /v2/repository/index | * | <empty> | <empty> | V2 model repository index endpoint | mlserver/rest/app.py:167 |
| add | http_endpoints | POST :: /v2/repository/models/{model_name}/load | * | <empty> | <empty> | V2 model repository load endpoint | mlserver/rest/app.py:172 |
| add | http_endpoints | POST :: /v2/repository/models/{model_name}/unload | * | <empty> | <empty> | V2 model repository unload endpoint | mlserver/rest/app.py:177 |
| add | http_endpoints | GET :: /metrics | * | <empty> | <empty> | Prometheus metrics endpoint on dedicated metrics port 8082 | mlserver/settings.py:445, mlserver/rest/app.py:226 |
| add | authentication | V2 REST API :: GET, POST | * | <empty> | <empty> | REST API authentication is platform-delegated via kube-rbac-proxy sidecar, same mechanism as gRPC surface; no application-level auth middleware in FastAPI app | mlserver/rest/app.py:52-238 |

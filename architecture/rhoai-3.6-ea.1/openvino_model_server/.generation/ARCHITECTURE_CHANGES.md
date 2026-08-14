# Architecture Changes: openvino_model_server

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | http_endpoints | POST :: /v1/models/{model_name}:predict | * | <empty> | <empty> | TFS V1 inference endpoint defined in REST API handler regex | src/http_rest_api_handler.cpp:102-103 |
| add | http_endpoints | GET :: /v1/models/{model_name}/metadata | * | <empty> | <empty> | TFS V1 model metadata endpoint defined in REST API handler regex | src/http_rest_api_handler.cpp:104-105 |
| add | http_endpoints | GET :: /v1/models/{model_name} | * | <empty> | <empty> | TFS V1 model status endpoint defined in REST API handler regex | src/http_rest_api_handler.cpp:104-105 |
| add | http_endpoints | POST :: /v1/config/reload | * | <empty> | <empty> | Config reload endpoint defined in REST API handler regex | src/http_rest_api_handler.cpp:106 |
| add | http_endpoints | GET :: /v1/config | * | <empty> | <empty> | Config status endpoint defined in REST API handler regex | src/http_rest_api_handler.cpp:107 |
| add | http_endpoints | POST :: /v2/models/{model_name}/infer | * | <empty> | <empty> | KServe V2 inference endpoint defined in REST API handler regex | src/http_rest_api_handler.cpp:113-114 |
| add | http_endpoints | GET :: /v2/models/{model_name}/ready | * | <empty> | <empty> | KServe V2 model readiness endpoint defined in REST API handler regex | src/http_rest_api_handler.cpp:109-110 |
| add | http_endpoints | GET :: /v2/models/{model_name} | * | <empty> | <empty> | KServe V2 model metadata endpoint defined in REST API handler regex | src/http_rest_api_handler.cpp:111-112 |
| add | http_endpoints | GET :: /v2/health/ready | * | <empty> | <empty> | Server readiness probe endpoint, used as KServe startup probe | src/http_rest_api_handler.cpp:115-116, extras/openshift_AI/ServingRuntime.yaml:28 |
| add | http_endpoints | GET :: /v2/health/live | * | <empty> | <empty> | Server liveness probe endpoint defined in REST API handler regex | src/http_rest_api_handler.cpp:117-118 |
| add | http_endpoints | GET :: /v2 | * | <empty> | <empty> | KServe V2 server metadata endpoint defined in REST API handler regex | src/http_rest_api_handler.cpp:119-120 |
| add | http_endpoints | GET :: /v3/models | * | <empty> | <empty> | OpenAI-compatible model listing endpoint defined in REST API handler regex | src/http_rest_api_handler.cpp:122-123 |
| add | http_endpoints | GET :: /v3/models/{name} | * | <empty> | <empty> | OpenAI-compatible model retrieval endpoint defined in REST API handler regex | src/http_rest_api_handler.cpp:124-125 |
| add | http_endpoints | POST :: /v3/* | * | <empty> | <empty> | OpenAI-compatible API catch-all (chat completions, embeddings) defined in REST API handler regex | src/http_rest_api_handler.cpp:126-127 |
| add | http_endpoints | GET :: /metrics | * | <empty> | <empty> | Prometheus metrics endpoint defined in REST API handler regex | src/http_rest_api_handler.cpp:129 |
| add | authentication | REST/gRPC API (default) :: All | * | <empty> | <empty> | Core OVMS binary does not enforce authentication by default | src/http_rest_api_handler.hpp:250-251 |
| add | authentication | REST/gRPC API (nginx-mtls sidecar) :: All | * | <empty> | <empty> | Optional nginx sidecar provides mTLS with client cert verification and TLS 1.2 | extras/nginx-mtls-auth/model_server.conf.template:27-35 |
| add | authentication | REST/gRPC API (API key) :: All | * | <empty> | <empty> | Optional in-process API key validation via isAuthorized method | src/http_rest_api_handler.hpp:250-251 |
| add | internal_dependencies | KServe | * | <empty> | <empty> | OVMS is deployed as a KServe ServingRuntime, managed via serving.kserve.io CRDs | extras/openshift_AI/ServingRuntime.yaml:1-2 |
| add | internal_dependencies | Model Storage | * | <empty> | <empty> | Models loaded from /mnt/models path provisioned by KServe storage initializer | extras/openshift_AI/ServingRuntime.yaml:21 |
| add | integration_points | KServe :: ServingRuntime CR | * | <empty> | <empty> | OVMS acts as inference backend receiving requests via KServe model serving | extras/openshift_AI/ServingRuntime.yaml:1-61 |
| add | integration_points | Prometheus :: metrics-scrape | * | <empty> | <empty> | OVMS exposes /metrics endpoint configured for Prometheus scraping via pod annotations | extras/openshift_AI/ServingRuntime.yaml:14-15 |

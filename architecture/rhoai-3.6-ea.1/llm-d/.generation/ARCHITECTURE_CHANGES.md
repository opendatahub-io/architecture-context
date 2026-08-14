# Architecture Changes: llm-d

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | http_endpoints | /health :: GET | Port | modelserver | 8000/TCP | Deployment manifest specifies containerPort 8000 for the modelserver named port | guides/recipes/modelserver/base/single-host/default/decode-deployment.yaml:24-26 |
| update | http_endpoints | /health :: GET | Encryption | Unknown | None | No TLS configuration in decode deployment; plain HTTP | guides/recipes/modelserver/base/single-host/default/decode-deployment.yaml:28-30 |
| update | http_endpoints | /health :: GET | Auth | Unknown | None | No authentication mechanism configured on model server endpoints | guides/recipes/modelserver/base/single-host/default/decode-deployment.yaml:17-39 |
| update | http_endpoints | /v1/models :: GET | Port | modelserver | 8000/TCP | Deployment manifest specifies containerPort 8000 for the modelserver named port | guides/recipes/modelserver/base/single-host/default/decode-deployment.yaml:24-26 |
| update | http_endpoints | /v1/models :: GET | Encryption | Unknown | None | No TLS configuration in decode deployment; plain HTTP | guides/recipes/modelserver/base/single-host/default/decode-deployment.yaml:32-35 |
| update | http_endpoints | /v1/models :: GET | Auth | Unknown | None | No authentication mechanism configured on model server endpoints | guides/recipes/modelserver/base/single-host/default/decode-deployment.yaml:17-39 |
| add | grpc_services | modelexpress-server | * | <empty> | <empty> | ModelExpress metadata broker exposes gRPC on port 8001 with Istio mTLS | guides/modelexpress-p2p/modelexpress/modelexpress-server.yaml:55-59, guides/modelexpress-p2p/security/istio-mtls-authz.yaml:8-21 |
| add | grpc_services | MX worker gRPC | * | <empty> | <empty> | Decode workers expose gRPC port 6555 for P2P tensor transfer coordination | guides/modelexpress-p2p/modelserver/gpu/vllm/base/patch-vllm.yaml:32-33 |
| add | grpc_services | MX metadata | * | <empty> | <empty> | Decode workers expose gRPC port 5555 for per-pod metadata advertisement | guides/modelexpress-p2p/modelserver/gpu/vllm/base/patch-vllm.yaml:30-31 |
| add | internal_dependencies | llm-d-router (EPP) | * | <empty> | <empty> | EPP routes inference requests to model server pods via InferencePool | guides/recipes/router/base.values.yaml:1-21, guides/workload-autoscaling/multi-inference-pool/guide.yaml:20-26 |
| add | internal_dependencies | Gateway API (InferencePool/InferenceModel CRDs) | * | <empty> | <empty> | CRDs define model-to-pool routing consumed by the EPP | guides/workload-autoscaling/multi-inference-pool/guide.yaml:31-33 |
| add | internal_dependencies | ModelExpress server | * | <empty> | <empty> | Optional gRPC metadata broker for P2P KV cache sharing | guides/modelexpress-p2p/modelexpress/modelexpress-server.yaml:47-59 |
| add | authentication | Model server HTTP API (port 8000) :: All | * | <empty> | <empty> | No built-in auth on vLLM HTTP endpoints; platform-delegated | guides/recipes/modelserver/base/single-host/default/decode-deployment.yaml:17-39 |
| add | authentication | ModelExpress gRPC API (port 8001) :: All | * | <empty> | <empty> | Istio mTLS STRICT with AuthorizationPolicy restricting to decode SA | guides/modelexpress-p2p/security/istio-mtls-authz.yaml:8-42 |
| add | integration_points | llm-d-router (EPP + Envoy) :: HTTP proxy | * | <empty> | <empty> | Routes inference requests to decode pods via InferencePool | guides/recipes/router/base.values.yaml:1-21 |
| add | integration_points | ModelExpress server :: gRPC | * | <empty> | <empty> | Metadata broker for P2P KV cache coordination | guides/modelexpress-p2p/modelexpress/modelexpress-server.yaml:47-59 |
| add | integration_points | HuggingFace Hub :: HTTPS | * | <empty> | <empty> | Model download via HF_TOKEN secret | guides/modelexpress-p2p/modelserver/gpu/vllm/base/patch-vllm.yaml:41-44 |
| add | integration_points | OpenTelemetry Collector :: gRPC (OTLP) | * | <empty> | <empty> | Distributed tracing export | guides/recipes/router/base.values.yaml:60-62 |

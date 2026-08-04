# Architecture Changes: llm-d

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | http_endpoints | GET :: /health | Port | modelserver | 8000/TCP | Resolve named port to numeric container port from deployment spec | guides/recipes/modelserver/base/single-host/default/decode-deployment.yaml:23 |
| update | http_endpoints | GET :: /health | Encryption | Unknown | None | No TLS configured on model server container port | guides/recipes/modelserver/base/single-host/default/decode-deployment.yaml:17-39 |
| update | http_endpoints | GET :: /health | Auth | Unknown | None | No authentication configured at model server level | guides/recipes/modelserver/base/single-host/default/decode-deployment.yaml:17-39 |
| update | http_endpoints | GET :: /v1/models | Port | modelserver | 8000/TCP | Resolve named port to numeric container port from deployment spec | guides/recipes/modelserver/base/single-host/default/decode-deployment.yaml:23 |
| update | http_endpoints | GET :: /v1/models | Encryption | Unknown | None | No TLS configured on model server container port | guides/recipes/modelserver/base/single-host/default/decode-deployment.yaml:17-39 |
| update | http_endpoints | GET :: /v1/models | Auth | Unknown | None | No authentication configured at model server level | guides/recipes/modelserver/base/single-host/default/decode-deployment.yaml:17-39 |
| add | http_endpoints | POST :: /v1/completions | * | <empty> | <empty> | OpenAI-compatible completion endpoint verified in guide test step | guides/optimized-baseline/guide.yaml:127 |
| add | integration_points | gateway-api-inference-extension :: CRD Install | * | <empty> | <empty> | InferencePool and InferenceModel CRDs installed as prerequisite | guides/optimized-baseline/guide.yaml:42 |
| add | integration_points | llm-d-router (EPP) :: Helm Install | * | <empty> | <empty> | EPP deployed via Helm for ext_proc request routing at port 9002 | guides/optimized-baseline/guide.yaml:77-82, guides/no-kubernetes-deployment/router/envoy/envoy.yaml:63 |
| add | integration_points | Envoy proxy :: Sidecar/Standalone | * | <empty> | <empty> | Envoy reverse proxy routing to model servers via ORIGINAL_DST on port 8081 | guides/no-kubernetes-deployment/router/envoy/envoy.yaml:30 |
| add | integration_points | nixl :: P2P Transfer | * | <empty> | <empty> | KV cache transfer on port 5600 for P/D disaggregation | guides/recipes/modelserver/base/single-host/pd/base/kustomization.yaml:27 |
| add | integration_points | OpenTelemetry Collector :: Telemetry Export | * | <empty> | <empty> | Distributed tracing export from EPP to OTel collector | guides/recipes/router/base.values.yaml:52 |
| add | internal_dependencies | vLLM | * | <empty> | <empty> | OpenAI-compatible model serving engine built into container images | docker/Dockerfile.cpu:142 |
| add | internal_dependencies | gateway-api-inference-extension | * | <empty> | <empty> | InferencePool and InferenceModel CRDs for inference routing | guides/optimized-baseline/guide.yaml:42 |
| add | internal_dependencies | llm-d-router | * | <empty> | <empty> | EPP and Envoy proxy Helm chart for inference request routing | guides/optimized-baseline/guide.yaml:77-82 |
| add | authentication | Model Server API :: All | * | <empty> | <empty> | No application-level auth; delegated to gateway/mesh layer | guides/recipes/modelserver/base/single-host/default/decode-deployment.yaml:17-39 |

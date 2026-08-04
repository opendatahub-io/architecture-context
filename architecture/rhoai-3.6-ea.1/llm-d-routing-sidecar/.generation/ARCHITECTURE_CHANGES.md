# Architecture Changes: llm-d-routing-sidecar

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | http_endpoints | POST :: /v1/chat/completions | * | <empty> | <empty> | OpenAI chat completions endpoint registered in Go HTTP mux with P/D routing handler | internal/proxy/proxy.go:243, internal/proxy/chat_completions.go:24 |
| add | http_endpoints | POST :: /v1/completions | * | <empty> | <empty> | Legacy completions endpoint registered in Go HTTP mux with P/D routing handler | internal/proxy/proxy.go:244, internal/proxy/chat_completions.go:28 |
| add | http_endpoints | GET :: /health | * | <empty> | <empty> | Health check endpoint registered in Go HTTP mux | internal/proxy/proxy.go:240-242 |
| delete | http_endpoints | Unknown :: / | * | <empty> | <empty> | Row key migration: method changed from Unknown to ALL based on source evidence of catch-all mux.Handle registration | internal/proxy/proxy.go:276 |
| add | http_endpoints | ALL :: / | * | <empty> | <empty> | Catch-all passthrough route registered via mux.Handle for decoder reverse proxy; method, port, encryption, and auth resolved from source | internal/proxy/proxy.go:276, cmd/llm-d-routing-sidecar/main.go:31, internal/proxy/proxy.go:189-199 |
| add | authentication | Proxy HTTP endpoints :: POST, GET, ALL | * | <empty> | <empty> | Proxy endpoints have no application-level auth; relies on sidecar network isolation | internal/proxy/proxy.go:235-278, internal/proxy/chat_completions.go:31-58 |
| add | internal_dependencies | vLLM | * | <empty> | <empty> | Co-located decoder inference engine targeted by reverse proxy on localhost | cmd/llm-d-routing-sidecar/main.go:32, internal/proxy/proxy.go:247-276 |
| add | internal_dependencies | InferencePool (Gateway API) | * | <empty> | <empty> | Watches inference.networking.x-k8s.io/v1alpha2 InferencePool CRD for SSRF allowlisting | internal/proxy/allowlist.go:41-44, internal/proxy/allowlist.go:111-148 |
| add | integration_points | vLLM Decoder (localhost) :: HTTP reverse proxy | * | <empty> | <empty> | Reverse proxy forwards all inference requests to co-located vLLM decoder | internal/proxy/proxy.go:247-276, cmd/llm-d-routing-sidecar/main.go:84 |
| add | integration_points | vLLM Prefiller Pods :: HTTP reverse proxy | * | <empty> | <empty> | Disaggregated prefill requests forwarded to remote pods via x-prefiller-host-port header | internal/proxy/proxy.go:281-316, internal/proxy/chat_completions.go:31-58 |

# Architecture Changes: llm-d-routing-sidecar

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | http_endpoints | / :: Unknown | Method | Unknown | ALL | Catch-all mux.Handle("/") forwards all HTTP methods to vLLM decoder | internal/proxy/proxy.go:276 |
| update | http_endpoints | / :: Unknown | Port | (empty) | 8000/TCP | Sidecar listens on configurable port, default 8000 | cmd/llm-d-routing-sidecar/main.go:31 |
| update | http_endpoints | / :: Unknown | Encryption | Unknown | TLS 1.2+ (when --secure-proxy) | Secure proxy enabled by default with TLS 1.2+ and curated cipher suites | internal/proxy/proxy.go:189-200 |
| update | http_endpoints | / :: Unknown | Auth | Unknown | None | No caller authentication middleware; TLS provides transport encryption only | internal/proxy/proxy.go:148-276 |
| update | http_endpoints | / :: Unknown | Purpose | Registered Go HTTP route | Catch-all reverse proxy to co-located vLLM decoder; P/D connector intercepts prefill-routed requests | Handler forwards all traffic to vLLM and connector protocol intercepts prefill-targeted requests | internal/proxy/proxy.go:276, cmd/llm-d-routing-sidecar/main.go:30-109 |
| add | internal_dependencies | vLLM | * | <empty> | <empty> | Co-located vLLM inference engine is the sidecar's primary proxy target at localhost:8001 | cmd/llm-d-routing-sidecar/main.go:32, internal/proxy/proxy.go:84 |
| add | internal_dependencies | InferencePool CRD (Gateway API) | * | <empty> | <empty> | SSRF protection watches InferencePool resources from inference.networking.x-k8s.io/v1alpha2 | internal/proxy/allowlist.go:40-44 |
| add | authentication | Proxy endpoint (/) :: ALL | * | <empty> | <empty> | Proxy endpoint has no caller authentication; TLS is transport-only | internal/proxy/proxy.go:148-276 |
| update | integration_points | Kubernetes API :: REST + WebSocket | Role | (empty) | control-plane | Kubernetes API is used for InferencePool/Pod watch in SSRF protection | internal/proxy/allowlist.go:85, internal/proxy/allowlist.go:110-114 |
| update | integration_points | Kubernetes API :: REST + WebSocket | Purpose | Kubernetes resource operations | Kubernetes resource operations; InferencePool/Pod watch for SSRF allowlist | Kubernetes client is specifically used to watch InferencePool and Pod resources for SSRF allowlisting | internal/proxy/allowlist.go:40-44, internal/proxy/allowlist.go:85 |
| add | integration_points | vLLM (local decoder) :: HTTP reverse proxy | * | <empty> | <empty> | Sidecar reverse-proxies decode requests to co-located vLLM at localhost:8001 | cmd/llm-d-routing-sidecar/main.go:32, internal/proxy/proxy.go:84, internal/proxy/proxy.go:276 |
| add | integration_points | Remote prefillers :: HTTP reverse proxy | * | <empty> | <empty> | Sidecar proxies prefill requests to remote prefiller pods identified by x-prefiller-url/x-prefiller-host-port headers | internal/proxy/proxy.go:38-39, internal/proxy/proxy.go:281-310 |

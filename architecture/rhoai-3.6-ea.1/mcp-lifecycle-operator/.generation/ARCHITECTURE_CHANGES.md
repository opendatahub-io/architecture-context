# Architecture Changes: mcp-lifecycle-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | http_endpoints | GET :: /healthz | Encryption | Unknown | None | Source confirms health probe on port 8081 uses plain HTTP with no TLS | cmd/main.go:205 |
| update | http_endpoints | GET :: /healthz | Auth | Unknown | None | Source confirms health probe is unauthenticated by design | cmd/main.go:205 |
| update | http_endpoints | GET :: /healthz | Owner | (empty) | cmd | Health check registered in cmd/main.go main function | cmd/main.go:205 |
| update | http_endpoints | GET :: /healthz | Purpose | httpGet probe | Kubernetes liveness probe | Clarifies probe role as liveness check | cmd/main.go:205 |
| update | http_endpoints | GET :: /readyz | Encryption | Unknown | None | Source confirms readiness probe on port 8081 uses plain HTTP with no TLS | cmd/main.go:209 |
| update | http_endpoints | GET :: /readyz | Auth | Unknown | None | Source confirms readiness probe is unauthenticated by design | cmd/main.go:209 |
| update | http_endpoints | GET :: /readyz | Owner | (empty) | cmd | Readiness check registered in cmd/main.go main function | cmd/main.go:209 |
| update | http_endpoints | GET :: /readyz | Purpose | httpGet probe | Kubernetes readiness probe | Clarifies probe role as readiness check | cmd/main.go:209 |
| update | services | mcp-lifecycle-operator-controller-manager-metrics-service | Encryption | Unknown | TLS (self-signed) | Source confirms metrics server uses SecureServing with self-signed TLS certificates by default | cmd/main.go:133-136, cmd/main.go:147-162 |
| update | services | mcp-lifecycle-operator-controller-manager-metrics-service | Auth | Unknown | TokenReview + SubjectAccessReview | Source confirms metrics endpoint uses controller-runtime WithAuthenticationAndAuthorization filter | cmd/main.go:139-145 |
| update | services | mcp-lifecycle-operator-controller-manager-metrics-service | Protocol | TCP | HTTPS | Metrics endpoint serves HTTPS with TLS, not plain TCP | cmd/main.go:133-136 |
| add | integration_points | MCP Server Endpoints :: Outbound HTTP handshake | * | <empty> | <empty> | Operator acts as MCP client connecting to managed MCP server pods via HTTP to perform protocol handshake verification | internal/controller/mcpserver_controller_handshake.go:99-131 |

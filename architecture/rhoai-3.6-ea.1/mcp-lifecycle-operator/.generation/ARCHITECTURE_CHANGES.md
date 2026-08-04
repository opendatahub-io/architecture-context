# Architecture Changes: mcp-lifecycle-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | http_endpoints | GET :: /healthz | Encryption | Unknown | None | Source confirms health probe on port 8081 uses plain HTTP with no TLS | cmd/main.go:205 |
| update | http_endpoints | GET :: /healthz | Auth | Unknown | None | Source confirms health probe is registered via healthz.Ping with no authentication | cmd/main.go:205 |
| update | http_endpoints | GET :: /readyz | Encryption | Unknown | None | Source confirms readiness probe on port 8081 uses plain HTTP with no TLS | cmd/main.go:209 |
| update | http_endpoints | GET :: /readyz | Auth | Unknown | None | Source confirms readiness probe is registered via healthz.Ping with no authentication | cmd/main.go:209 |
| update | services | mcp-lifecycle-operator-controller-manager-metrics-service | Encryption | Unknown | TLS (self-signed) | Metrics server uses controller-runtime self-signed TLS certificate by default, with optional external cert path | cmd/main.go:133-162 |
| update | services | mcp-lifecycle-operator-controller-manager-metrics-service | Auth | Unknown | TokenReview + SubjectAccessReview | Metrics endpoint protected by controller-runtime WithAuthenticationAndAuthorization filter when secureMetrics is enabled | cmd/main.go:139-144 |

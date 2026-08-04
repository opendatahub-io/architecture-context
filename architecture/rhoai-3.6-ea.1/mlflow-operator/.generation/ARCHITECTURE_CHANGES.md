# Architecture Changes: mlflow-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | http_endpoints | GET :: /healthz | Encryption | Unknown | None | Health probe on port 8081 uses plain HTTP with no TLS; probeAddr defaults to :8081 | cmd/main.go:175, cmd/main.go:542 |
| update | http_endpoints | GET :: /healthz | Auth | Unknown | None | Health probe uses healthz.Ping, unauthenticated by design | cmd/main.go:542 |
| update | http_endpoints | GET :: /healthz | Owner | (empty) | cmd | Health check registered in main() function | cmd/main.go:542 |
| update | http_endpoints | GET :: /healthz | Purpose | httpGet probe | Health check (healthz.Ping) | Source confirms healthz.Ping handler, not a generic httpGet probe | cmd/main.go:542 |
| update | http_endpoints | GET :: /readyz | Encryption | Unknown | None | Readiness probe on port 8081 uses plain HTTP with no TLS | cmd/main.go:175, cmd/main.go:546 |
| update | http_endpoints | GET :: /readyz | Auth | Unknown | None | Readiness probe uses healthz.Ping, unauthenticated by design | cmd/main.go:546 |
| update | http_endpoints | GET :: /readyz | Owner | (empty) | cmd | Readiness check registered in main() function | cmd/main.go:546 |
| update | http_endpoints | GET :: /readyz | Purpose | httpGet probe | Readiness check (healthz.Ping) | Source confirms healthz.Ping handler, not a generic httpGet probe | cmd/main.go:546 |
| update | services | mlflow-operator-controller-manager-metrics-service | Encryption | Unknown | TLS (self-signed default) | Metrics server uses controller-runtime SecureServing with self-signed TLS by default; configurable via --metrics-cert-path | cmd/main.go:263, cmd/main.go:275-284 |
| update | services | mlflow-operator-controller-manager-metrics-service | Auth | Unknown | TokenReview + SubjectAccessReview | Metrics server uses controller-runtime WithAuthenticationAndAuthorization filter when secureMetrics=true (default) | cmd/main.go:267-272 |
| update | services | mlflow-operator-controller-manager-metrics-service | Protocol | TCP | HTTPS | Metrics endpoint serves HTTPS when secureMetrics=true (default) | cmd/main.go:187, cmd/main.go:261-263 |

# Architecture Changes: ai-gateway-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | http_endpoints | GET :: /metrics | * | <empty> | <empty> | Controller-runtime exposes Prometheus metrics on the configured bind address; port overridden to 8443 via kustomize patch env var | cmd/operator/operator.go:85-87, config/default/manager_metrics_patch.yaml:6-7, pkg/config/config.go:44 |
| update | http_endpoints | GET :: /healthz | Encryption | Unknown | None | Health probe endpoint on port 8081 uses plain HTTP; no TLS configuration in controller-runtime HealthProbeBindAddress | cmd/operator/operator.go:88, pkg/config/config.go:45 |
| update | http_endpoints | GET :: /healthz | Auth | Unknown | None | Health probe is unauthenticated healthz.Ping handler registered via controller-runtime | cmd/operator/operator.go:146-148 |
| update | http_endpoints | GET :: /readyz | Encryption | Unknown | None | Ready probe endpoint on port 8081 uses plain HTTP; no TLS configuration in controller-runtime HealthProbeBindAddress | cmd/operator/operator.go:88, pkg/config/config.go:45 |
| update | http_endpoints | GET :: /readyz | Auth | Unknown | None | Ready probe is unauthenticated healthz.Ping handler registered via controller-runtime | cmd/operator/operator.go:149-151 |
| add | authentication | Metrics endpoint (:8443) :: GET | * | <empty> | <empty> | Metrics endpoint auth depends on controller-runtime v0.24.1 defaults; RBAC scaffolding for TokenReview/SubjectAccessReview exists via ai-gateway-metrics-auth-role | cmd/operator/operator.go:85-87, config/rbac/metrics_auth_role.yaml:1 |

# Architecture Changes: ai-gateway-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | http_endpoints | GET :: /metrics | * | <empty> | <empty> | Metrics endpoint served by controller-runtime on port 8443 (HTTPS) with TokenReview/SubjectAccessReview authentication; port patched via ODH_MODULE_OPERATOR_METRICS_BIND_ADDRESS env var | config/default/manager_metrics_patch.yaml:1, config/default/metrics_service.yaml:10-15, cmd/operator/operator.go:84-87 |
| update | http_endpoints | GET :: /healthz | Auth | Unknown | None | Health probe uses healthz.Ping with no authentication; standard Kubernetes liveness probe pattern | cmd/operator/operator.go:146 |
| update | http_endpoints | GET :: /healthz | Encryption | Unknown | None | Health probe on port 8081 is plain HTTP; no TLS configured for probe endpoint | pkg/config/config.go:45 |
| update | http_endpoints | GET :: /healthz | Purpose | httpGet probe | Liveness probe (healthz.Ping) | More specific purpose from source: uses controller-runtime healthz.Ping handler | cmd/operator/operator.go:146 |
| update | http_endpoints | GET :: /readyz | Auth | Unknown | None | Readiness probe uses healthz.Ping with no authentication; standard Kubernetes readiness probe pattern | cmd/operator/operator.go:149 |
| update | http_endpoints | GET :: /readyz | Encryption | Unknown | None | Readiness probe on port 8081 is plain HTTP; no TLS configured for probe endpoint | pkg/config/config.go:45 |
| update | http_endpoints | GET :: /readyz | Purpose | httpGet probe | Readiness probe (healthz.Ping) | More specific purpose from source: uses controller-runtime healthz.Ping handler | cmd/operator/operator.go:149 |
| add | authentication | Metrics endpoint (:8443) :: GET | * | <empty> | <empty> | Metrics endpoint uses controller-runtime built-in authn/authz via TokenReview and SubjectAccessReview APIs; confirmed by ai-gateway-metrics-auth-role RBAC granting tokenreviews and subjectaccessreviews | config/rbac/metrics_auth_role.yaml:1, config/default/manager_metrics_patch.yaml:1, config/default/metrics_service.yaml:12 |

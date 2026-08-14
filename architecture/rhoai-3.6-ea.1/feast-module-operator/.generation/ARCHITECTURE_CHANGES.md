# Architecture Changes: feast-module-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | http_endpoints | GET :: /healthz | Encryption | Unknown | None | Health probe on port 8081 uses plain HTTP with no encryption | pkg/manager/manager.go:95, pkg/config/config.go:51 |
| update | http_endpoints | GET :: /healthz | Auth | Unknown | None | Health probe endpoints are unauthenticated by design | pkg/manager/manager.go:143-144 |
| update | http_endpoints | GET :: /readyz | Encryption | Unknown | None | Readiness probe on port 8081 uses plain HTTP with no encryption | pkg/manager/manager.go:95, pkg/config/config.go:51 |
| update | http_endpoints | GET :: /readyz | Auth | Unknown | None | Readiness probe endpoints are unauthenticated by design | pkg/manager/manager.go:146-147 |
| add | http_endpoints | GET :: /metrics | * | <empty> | <empty> | Metrics endpoint served by controller-runtime metrics server on port 8443 with TLS and TokenReview/SubjectAccessReview authentication | pkg/manager/manager.go:92-93, config/default/manager_metrics_patch.yaml:7, config/default/metrics_service.yaml:13-14 |
| add | authentication | Metrics (:8443) :: GET | * | <empty> | <empty> | Controller-runtime metrics server authenticates via TokenReview/SubjectAccessReview, backed by metrics-auth-role ClusterRole | pkg/manager/manager.go:92-93, config/rbac/metrics_auth_role.yaml:1-17 |
| add | authentication | Health probes (:8081) :: GET | * | <empty> | <empty> | Health and readiness probes are unauthenticated, standard for Kubernetes liveness/readiness checks | pkg/manager/manager.go:143-147, pkg/config/config.go:51 |

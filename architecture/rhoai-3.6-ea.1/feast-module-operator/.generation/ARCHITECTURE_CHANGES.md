# Architecture Changes: feast-module-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | http_endpoints | GET :: /metrics | * | <empty> | <empty> | Metrics endpoint served by controller-runtime metricsserver on port 8443 with RBAC authentication; confirmed by RBAC annotations and manager configuration | internal/controller/feastoperator/feastoperator_controller.go:75, pkg/manager/manager.go:92-93, config/default/manager_metrics_patch.yaml:6-7, config/default/metrics_service.yaml:11-14 |
| add | authentication | Metrics API (/metrics:8443) :: GET | * | <empty> | <empty> | Metrics endpoint uses controller-runtime secure metrics serving with RBAC-based TokenReview and SubjectAccessReview authentication | pkg/manager/manager.go:92-93, config/rbac/metrics_auth_role.yaml:1, config/rbac/metrics_reader_role.yaml:1, config/default/manager_metrics_patch.yaml:6-7 |
| add | authentication | Health Probes (/healthz, /readyz:8081) :: GET | * | <empty> | <empty> | Health and readiness probes are unauthenticated standard controller-runtime healthz endpoints | pkg/manager/manager.go:143-148, pkg/config/config.go:51 |
| add | internal_dependencies | odh-platform-utilities | * | <empty> | <empty> | Go library dependency providing cache utility functions for controller informers; imported directly in manager setup | pkg/manager/manager.go:43, go.mod:80 |
| update | http_endpoints | GET :: /healthz | Auth | Unknown | None | Health probe confirmed as unauthenticated by controller-runtime healthz.Ping implementation | pkg/manager/manager.go:143 |
| update | http_endpoints | GET :: /healthz | Encryption | Unknown | None | Health probe served on plain HTTP port 8081 without TLS | pkg/config/config.go:51, pkg/manager/manager.go:95 |
| update | http_endpoints | GET :: /healthz | Purpose | httpGet probe | Liveness probe | Clarified as liveness probe based on healthz check registration | pkg/manager/manager.go:143 |
| update | http_endpoints | GET :: /readyz | Auth | Unknown | None | Readiness probe confirmed as unauthenticated by controller-runtime healthz.Ping implementation | pkg/manager/manager.go:146 |
| update | http_endpoints | GET :: /readyz | Encryption | Unknown | None | Readiness probe served on plain HTTP port 8081 without TLS | pkg/config/config.go:51, pkg/manager/manager.go:95 |
| update | http_endpoints | GET :: /readyz | Purpose | httpGet probe | Readiness probe | Clarified as readiness probe based on readyz check registration | pkg/manager/manager.go:146 |
| update | services | opendatahub-feast-metrics-service | Encryption | Unknown | TLS | Metrics service port named "https" and serves controller-runtime secure metrics | config/default/metrics_service.yaml:11, pkg/manager/manager.go:92-93 |
| update | services | opendatahub-feast-metrics-service | Auth | Unknown | RBAC (TokenReview + SubjectAccessReview) | Metrics endpoint authenticated via controller-runtime RBAC middleware using TokenReview and SubjectAccessReview | config/rbac/metrics_auth_role.yaml:1, config/rbac/metrics_reader_role.yaml:1 |
| update | services | opendatahub-feast-metrics-service | Protocol | TCP | HTTPS | Metrics service port named "https" indicating HTTPS protocol | config/default/metrics_service.yaml:11 |

# Architecture Changes: data-science-pipelines-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | services | service | * | <empty> | <empty> | Operator metrics Service defined in manager-service.yaml; ClusterIP on port 8080 for Prometheus metrics scraping | config/manager/manager-service.yaml:1-13 |
| add | authentication | DSPA CRD API (datasciencepipelinesapplications.opendatahub.io) :: Kubernetes API | * | <empty> | <empty> | DSPA CRD API access governed by RBAC aggregation via aggregate-dspa-admin-edit and aggregate-dspa-admin-view ClusterRoles | config/rbac/aggregate_dspa_role_edit.yaml:1, config/rbac/aggregate_dspa_role_view.yaml:1 |
| update | http_endpoints | GET :: /healthz | Port |  | 8081 | Port 8081 established by analyzer authentication evidence for :8081/healthz | main.go:376 |
| update | http_endpoints | GET :: /healthz | Auth | Unknown | None | Health probe uses healthz.Ping handler; unauthenticated by design per analyzer authentication evidence | main.go:376 |
| update | http_endpoints | GET :: /healthz | Encryption | Unknown | None | Health probe server on port 8081 uses plain HTTP | main.go:376 |
| update | http_endpoints | GET :: /healthz | Purpose | Controller manager health endpoint | Controller manager health endpoint | No change; retaining existing value | main.go:376 |
| update | http_endpoints | GET :: /readyz | Port |  | 8081 | Port 8081 established by analyzer authentication evidence for :8081/readyz | main.go:380 |
| update | http_endpoints | GET :: /readyz | Auth | Unknown | None | Readiness probe uses healthz.Ping handler; unauthenticated by design per analyzer authentication evidence | main.go:380 |
| update | http_endpoints | GET :: /readyz | Encryption | Unknown | None | Readiness probe server on port 8081 uses plain HTTP | main.go:380 |
| update | http_endpoints | GET :: /readyz | Purpose | Controller manager health endpoint | Controller manager readiness endpoint | Corrects purpose to distinguish readiness from health endpoint | main.go:380 |

# Architecture Changes: trainer-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | http_endpoints | GET :: /healthz | Encryption | Unknown | None | Source confirms no TLS on probe endpoint; probeAddr binds plaintext HTTP | cmd/main.go:73, 183 |
| update | http_endpoints | GET :: /healthz | Auth | Unknown | None | Health probe uses healthz.Ping; unauthenticated by design | cmd/main.go:183 |
| update | http_endpoints | GET :: /healthz | Owner | (empty) | cmd | Handler registered in cmd/main.go main() | cmd/main.go:183 |
| update | http_endpoints | GET :: /healthz | Transport | (empty) | HTTP/1.1 | Controller-runtime health endpoint serves HTTP/1.1 | cmd/main.go:183 |
| update | http_endpoints | GET :: /healthz | Purpose | httpGet probe | Liveness probe (healthz.Ping) | Clarifies probe type and handler function | cmd/main.go:183 |
| update | http_endpoints | GET :: /readyz | Encryption | Unknown | None | Source confirms no TLS on probe endpoint; probeAddr binds plaintext HTTP | cmd/main.go:73, 187 |
| update | http_endpoints | GET :: /readyz | Auth | Unknown | None | Readiness probe uses healthz.Ping; unauthenticated by design | cmd/main.go:187 |
| update | http_endpoints | GET :: /readyz | Owner | (empty) | cmd | Handler registered in cmd/main.go main() | cmd/main.go:187 |
| update | http_endpoints | GET :: /readyz | Transport | (empty) | HTTP/1.1 | Controller-runtime health endpoint serves HTTP/1.1 | cmd/main.go:187 |
| update | http_endpoints | GET :: /readyz | Purpose | httpGet probe | Readiness probe (healthz.Ping) | Clarifies probe type and handler function | cmd/main.go:187 |
| update | services | trainer-operator-controller-manager-metrics-service | Encryption | Unknown | None | SecureServing explicitly disabled in manager options; metrics served over plaintext HTTP | cmd/main.go:94-95 |
| update | services | trainer-operator-controller-manager-metrics-service | Auth | Unknown | None | No authentication middleware on metrics endpoint; RBAC metrics-reader role provides Kubernetes-level access control only | cmd/main.go:93-95, config/rbac/metrics_reader_role.yaml:1 |
| add | integration_points | JobSet Operator (operator.openshift.io) :: Dependency check | * | <empty> | <empty> | Controller verifies JobSet Operator installation, CR, and health as a hard prerequisite before reconciliation on OpenShift | internal/controller/trainer_controller.go:245-257 |
| add | internal_dependencies | odh-platform-utilities/framework | * | <empty> | <empty> | Separate Go module providing ReconcilerFor builder, deploy actions, condition management, and GC for reconciliation pipeline | go.mod:10, internal/controller/trainer_controller.go:180 |

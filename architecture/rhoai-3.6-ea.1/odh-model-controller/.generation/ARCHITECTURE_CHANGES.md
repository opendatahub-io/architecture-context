# Architecture Changes: odh-model-controller

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| delete | authentication | /metrics :: Unknown | * | <empty> | <empty> | Row-key migration: Methods updated from Unknown to GET based on source evidence showing promhttp.Handler() serves GET requests | server/observability/observability.go:87 |
| add | authentication | /metrics (model-serving-api) :: GET | * | <empty> | <empty> | Prometheus metrics endpoint on model-serving-api; source shows TLS-protected ListenAndServeTLS with no authentication middleware on the metrics mux | server/observability/observability.go:87, server/observability/observability.go:101 |
| add | authentication | /metrics (controller) :: GET | * | <empty> | <empty> | Controller-runtime metrics endpoint; source shows secureMetrics defaults to false (HTTP, unauthenticated); when enabled, uses WithAuthenticationAndAuthorization filter | cmd/main.go:101, cmd/main.go:240 |
| add | authentication | /api/v1/gateways :: GET | * | <empty> | <empty> | Gateway discovery API endpoint; source shows Bearer token authentication via middleware.Auth with downstream SelfSubjectAccessReview authorization | server/server.go:23, server/middleware/auth.go:24 |
| add | authentication | /api/v1/samples/llm-d :: GET | * | <empty> | <empty> | Static sample templates endpoint; source comment explicitly states no auth required for public YAML templates | server/server.go:27 |
| update | internal_dependencies | Gateway API | Role | unknown | runtime-transport | RBAC evidence shows gateway and httproute management verbs (get, list, patch, update, watch) establishing transport-layer role | config/rbac/role.yaml:3 |
| update | internal_dependencies | HardwareProfile CR | Interaction Type | CRD CRUD | CRD Watch | RBAC evidence shows read-only verbs (get, list, watch) for hardwareprofiles, not full CRUD | config/rbac/role.yaml:3 |
| update | internal_dependencies | HardwareProfile CR | Role | unknown | runtime-integration | HardwareProfile is a platform integration resource read by the controller for hardware profile awareness | config/rbac/role.yaml:3 |
| update | internal_dependencies | HardwareProfile CR | Purpose | Manage hardware profile resources | Read hardware profile resources | RBAC shows read-only access (get, list, watch), not management | config/rbac/role.yaml:3 |
| update | internal_dependencies | prometheus-operator | Role | unknown | runtime-observability | prometheus-operator CRDs (podmonitors, servicemonitors) are observability resources managed by the controller | config/rbac/role.yaml:3 |

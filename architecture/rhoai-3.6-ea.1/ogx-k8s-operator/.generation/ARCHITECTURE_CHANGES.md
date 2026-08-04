# Architecture Changes: ogx-k8s-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | internal_dependencies | prometheus-operator | Role | unknown | runtime-observability | RBAC role grants full CRUD on monitoring.coreos.com/prometheusrules and servicemonitors, establishing observability as the integration role | config/rbac/role.yaml:94-106 |
| update | integration_points | prometheus-operator :: CRD CRUD | Role | unknown | runtime-observability | RBAC role grants full CRUD on monitoring.coreos.com/prometheusrules and servicemonitors, establishing observability as the integration role | config/rbac/role.yaml:94-106 |

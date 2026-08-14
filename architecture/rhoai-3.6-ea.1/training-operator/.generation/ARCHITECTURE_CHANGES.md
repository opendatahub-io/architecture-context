# Architecture Changes: training-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | :8080/metrics :: GET | * | <empty> | <empty> | Metrics endpoint serves Prometheus metrics with TLS encryption but no application-level authentication; documents the full authentication surface | cmd/training-operator.v1/main.go:280, cmd/training-operator.v1/main.go:330-333, manifests/base/service.yaml:5-7 |
| delete | internal_dependencies | Kubeflow Notebooks (kubeflow.org) | * | <empty> | <empty> | RBAC role at kubeflow.org API group covers only training job CRDs (jaxjobs, mpijobs, paddlejobs, pytorchjobs, tfjobs, xgboostjobs), not notebook CRDs; no "notebook" reference exists in manifests | manifests/base/rbac/role.yaml:87-129 |
| delete | integration_points | Kubeflow Notebooks :: CRD CRUD | * | <empty> | <empty> | No notebook CRD references exist in RBAC rules or source; kubeflow.org rules cover training job CRDs only | manifests/base/rbac/role.yaml:87-129 |
| delete | integration_points | Kubeflow Notebooks (kubeflow.org) :: CRD CRUD | * | <empty> | <empty> | Duplicate of Kubeflow Notebooks entry; no notebook CRD references in RBAC or source | manifests/base/rbac/role.yaml:87-129 |
| update | integration_points | Prometheus :: Inbound scrape | Role | unknown | target | Prometheus scrapes the operator's metrics endpoint; service annotations confirm this is a scrape target, not an initiator | manifests/base/service.yaml:5-7 |
| update | integration_points | Prometheus :: Inbound scrape | Protocol | HTTP | HTTPS | Metrics server binds with TLS options derived from OpenShift TLS profile or hardened defaults | cmd/training-operator.v1/main.go:330-333 |
| update | integration_points | Prometheus :: Inbound scrape | Encryption | Unknown | TLS 1.2+ | Metrics server applies TLS 1.2+ minimum version from cluster profile or hardened intermediate defaults | cmd/training-operator.v1/main.go:109-111, cmd/training-operator.v1/main.go:164 |
| update | internal_dependencies | Prometheus | Role | unknown | target | Operator is the scrape target; Prometheus initiates the connection | manifests/base/service.yaml:5-7 |

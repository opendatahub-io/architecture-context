# Architecture Changes: training-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| delete | integration_points | Kubeflow Notebooks :: CRD CRUD | * | <empty> | <empty> | RBAC role.yaml contains only kubeflow.org training job CRDs (jaxjobs, mpijobs, paddlejobs, pytorchjobs, tfjobs, xgboostjobs), not notebook resources; label is incorrect | manifests/base/rbac/role.yaml:87-241 |
| delete | integration_points | Kubeflow Notebooks (kubeflow.org) :: CRD CRUD | * | <empty> | <empty> | Same RBAC evidence confirms no notebook resources; duplicate incorrect label | manifests/base/rbac/role.yaml:87-241 |
| add | integration_points | Kubeflow Training CRDs (kubeflow.org) :: CRD lifecycle | * | <empty> | <empty> | Training-operator owns and reconciles six kubeflow.org CRDs as the primary controller | manifests/base/rbac/role.yaml:87-241, cmd/training-operator.v1/main.go:286-287 |
| delete | internal_dependencies | Kubeflow Notebooks (kubeflow.org) :: CRD CRUD | * | <empty> | <empty> | RBAC role contains only training job CRDs; no notebook dependency exists | manifests/base/rbac/role.yaml:87-241 |
| add | internal_dependencies | Volcano Scheduler :: gang scheduling | * | <empty> | <empty> | RBAC grants scheduling.volcano.sh/podgroups CRUD; gang-scheduler-name flag enables integration | manifests/base/rbac/role.yaml:260-271, cmd/training-operator.v1/main.go:288-289 |
| add | internal_dependencies | Kubernetes Scheduler Plugins :: gang scheduling | * | <empty> | <empty> | RBAC grants scheduling.x-k8s.io/podgroups CRUD; alternative gang scheduler | manifests/base/rbac/role.yaml:272-283, cmd/training-operator.v1/main.go:288-289 |
| add | http_endpoints | GET :: /metrics | * | <empty> | <empty> | Metrics endpoint bound at :8080 via --metrics-bind-address flag with prometheus.io/scrape annotation | cmd/training-operator.v1/main.go:280, manifests/base/service.yaml:4-7 |
| add | authentication | :8080/metrics :: GET | * | <empty> | <empty> | Metrics endpoint has no authentication; relies on network-level access control | cmd/training-operator.v1/main.go:280, manifests/base/service.yaml:4-7 |

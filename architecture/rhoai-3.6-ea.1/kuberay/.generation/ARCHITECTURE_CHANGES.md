# Architecture Changes: kuberay

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | Ray Dashboard :: All | * | <empty> | <empty> | AuthenticationController injects kube-rbac-proxy sidecar (port 8443) for OIDC/OAuth-based dashboard authentication on RayCluster head pods | ray-operator/controllers/ray/authentication_controller.go:45-54, ray-operator/controllers/ray/authentication_controller.go:204-214 |
| add | internal_dependencies | kube-rbac-proxy :: Sidecar injection | * | <empty> | <empty> | Operator injects kube-rbac-proxy sidecar container into RayCluster head pods for runtime OIDC/OAuth authentication enforcement | ray-operator/controllers/ray/authentication_controller.go:47-53, ray-operator/controllers/ray/authentication_controller.go:65-74 |

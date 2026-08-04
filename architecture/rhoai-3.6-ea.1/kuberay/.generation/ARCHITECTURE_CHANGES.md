# Architecture Changes: kuberay

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | Ray Dashboard :: HTTPS | * | <empty> | <empty> | AuthenticationController injects kube-rbac-proxy sidecar for OIDC-based dashboard access on port 8443 | ray-operator/controllers/ray/authentication_controller.go:45-53, ray-operator/controllers/ray/authentication_controller.go:76-84 |

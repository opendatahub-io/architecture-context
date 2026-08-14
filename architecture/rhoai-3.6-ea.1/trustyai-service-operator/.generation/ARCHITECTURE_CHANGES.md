# Architecture Changes: trustyai-service-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | TrustyAI Service API :: All | * | <empty> | <empty> | kube-rbac-proxy sidecar enforces SubjectAccessReview on port 8443 with TLS; proxies to localhost:8080 | controllers/tas/templates/service/deployment.tmpl.yaml:153-168 |
| update | authentication | :9443/healthz :: GET | Policy | Unauthenticated Kubernetes liveness probe endpoint | kube-rbac-proxy health endpoint; unauthenticated HTTPS probe | Clarified that :9443 is the kube-rbac-proxy proxy-endpoints-port health endpoint, not a generic liveness probe | controllers/tas/templates/service/deployment.tmpl.yaml:161, 170-189 |
| add | internal_dependencies | OpenDataHub operator | * | <empty> | <empty> | DSCConfigReader reads trustyai-dsc-config ConfigMap provisioned by the OpenDataHub operator for evaluation policy (permitOnline, permitCodeExecution) | controllers/dsc/config.go:17-22, controllers/dsc/config.go:49 |

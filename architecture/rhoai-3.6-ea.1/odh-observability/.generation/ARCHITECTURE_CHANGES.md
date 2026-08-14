# Architecture Changes: odh-observability

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | :8443/metrics (cluster-proxy) :: GET | * | <empty> | <empty> | kube-rbac-proxy enforces SubjectAccessReview for metrics.k8s.io/nodes/get with TLS and mTLS to upstream Prometheus | internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:51-56, internal/controller/resources/data-science-prometheus-cluster-proxy.tmpl.yaml:82-93 |
| add | authentication | :9443/mutate-prometheus-monitors :: POST | * | <empty> | <empty> | Admission webhook uses cert-manager provisioned TLS; requests authenticated by Kubernetes API server | cmd/main.go:97-100, internal/controller/actions.go:582-585 |

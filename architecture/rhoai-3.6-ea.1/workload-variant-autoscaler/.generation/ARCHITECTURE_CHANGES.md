# Architecture Changes: workload-variant-autoscaler

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| update | http_endpoints | GET :: /healthz | Encryption | Unknown | None | Source confirms plain HTTP health probe on port 8081 with no TLS | cmd/main.go:664 |
| update | http_endpoints | GET :: /healthz | Auth | Unknown | None | Health check uses healthz.Ping with no authentication middleware | cmd/main.go:664 |
| update | http_endpoints | GET :: /healthz | Owner |  | cmd | Health check registered in cmd/main.go main function | cmd/main.go:664 |
| update | http_endpoints | GET :: /healthz | Purpose | httpGet probe | Health check (healthz.Ping) | Source shows standard healthz.Ping handler | cmd/main.go:664 |
| update | http_endpoints | GET :: /readyz | Encryption | Unknown | None | Source confirms plain HTTP readiness probe on port 8081 with no TLS | cmd/main.go:668 |
| update | http_endpoints | GET :: /readyz | Auth | Unknown | None | Readiness check uses ConfigMap bootstrap status with no authentication | cmd/main.go:668-676 |
| update | http_endpoints | GET :: /readyz | Owner |  | cmd | Readiness check registered in cmd/main.go main function | cmd/main.go:668 |
| update | http_endpoints | GET :: /readyz | Purpose | httpGet probe | Readiness check (ConfigMap bootstrap status) | Source shows custom readiness handler gated on ConfigMapsBootstrapComplete | cmd/main.go:668-676 |
| update | internal_dependencies | prometheus-operator | Role | unknown | runtime-integration | Watches ServiceMonitor CRDs for monitoring configuration | config/base/rbac/manager-clusterrole.yaml:2 |
| update | internal_dependencies | prometheus-operator | Purpose | Manage Prometheus monitoring resources | Manage Prometheus monitoring resources (ServiceMonitor watch) | Clarified interaction is ServiceMonitor CRD watch | config/base/rbac/manager-clusterrole.yaml:2 |
| update | internal_dependencies | Kubernetes API (nodes) | Role | unknown | runtime-integration | Lists nodes for GPU operator discovery in autoscaling topology | config/base/rbac/manager-clusterrole.yaml:2 |
| update | internal_dependencies | Kubernetes API (nodes) | Purpose | nodes resource access via RBAC | GPU node discovery for autoscaling topology | Source-backed purpose from K8sWithGpuOperator node lister | internal/discovery/k8s_with_gpu_operator.go:83 |
| update | internal_dependencies | Prometheus | Role | unknown | runtime-integration | Core metrics source with TLS 1.2+ and bearer token/mTLS auth | internal/prometheus/prometheus_transport.go:38-72, internal/prometheus/tls.go:48-53 |
| update | internal_dependencies | Prometheus | Purpose | Required Prometheus API client used for runtime metrics queries | Prometheus HTTP API client for saturation metrics queries; TLS 1.2+, bearer token or mTLS auth | Source confirms TLS minimum version, bearer token injection, and mTLS client cert support | internal/prometheus/tls.go:48-53, internal/prometheus/prometheus_transport.go:49-67 |
| update | integration_points | Prometheus :: Metrics source | Encryption | Unknown | TLS 1.2+ (configurable) | Prometheus client enforces MinVersion tls.VersionTLS12 for HTTPS endpoints with optional mTLS via client certificates | internal/prometheus/tls.go:51 |
| update | integration_points | Prometheus :: Metrics source | Protocol |  | HTTP/HTTPS | Prometheus client supports both HTTP (when explicitly allowed) and HTTPS with TLS configuration | internal/prometheus/prometheus_transport.go:24-31, internal/prometheus/tls.go:118-135 |
| update | integration_points | Prometheus :: Metrics source | Role |  | runtime-integration | Core metrics source for autoscaling decisions | cmd/main.go:446-458 |
| update | integration_points | Prometheus :: Metrics source | Purpose | Required Prometheus API client used for runtime metrics queries | Prometheus HTTP API client for saturation metrics queries; bearer token or mTLS auth | Source confirms bearer token and mTLS authentication support | internal/prometheus/prometheus_transport.go:49-67, internal/prometheus/tls.go:76-85 |

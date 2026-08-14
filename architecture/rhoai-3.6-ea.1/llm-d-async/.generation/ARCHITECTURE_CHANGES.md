# Architecture Changes: llm-d-async

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | /metrics :: HTTP | * | <empty> | <empty> | Metrics endpoint uses controller-runtime WithAuthenticationAndAuthorization filter, enabled by default | pkg/server/runner.go:340-342, pkg/server/options.go:97, pkg/server/options.go:131 |
| add | integration_points | Redis :: TCP client | * | <empty> | <empty> | Redis is the default message broker transport for async inference request/result flow | pkg/server/runner.go:289-300, pkg/server/options.go:75-77, pkg/server/options.go:104-106 |
| add | integration_points | GCP Pub/Sub :: HTTPS client | * | <empty> | <empty> | GCP Pub/Sub is an alternative cloud message broker transport | pkg/server/runner.go:301-311, pkg/server/options.go:78 |
| add | integration_points | Prometheus :: HTTP client | * | <empty> | <empty> | Prometheus is queried for metric-based flow-control gate decisions | pkg/server/runner.go:97-98, pkg/server/options.go:111-113, pkg/server/options.go:157 |
| add | integration_points | Inference Gateway :: HTTP client | * | <empty> | <empty> | Downstream model-serving endpoint for inference dispatch with configurable TLS/mTLS | pkg/server/runner.go:121, pkg/server/runner.go:357-375, pkg/server/options.go:150-153 |

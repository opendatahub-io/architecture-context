# Architecture Changes: llm-d-async

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | /metrics :: HTTP | * | <empty> | <empty> | Metrics endpoint uses controller-runtime WithAuthenticationAndAuthorization filter requiring Kubernetes API bearer token | pkg/server/runner.go:340-344, pkg/server/options.go:21 |
| add | integration_points | Redis :: TCP client | * | <empty> | <empty> | Redis is a primary message queue transport for async request consumption and result publishing | pkg/server/runner.go:289-300, pkg/redis/redisimpl.go:13-14 |
| add | integration_points | GCP Pub/Sub :: gRPC client | * | <empty> | <empty> | GCP Pub/Sub is an alternative message queue transport for async request flow | pkg/server/runner.go:301-311, pkg/pubsub/pubsubimpl.go:7 |
| add | integration_points | Model server :: HTTP client | * | <empty> | <empty> | HTTP inference client forwards requests to model serving backends with optional mTLS | pkg/server/runner.go:357-375, pkg/server/runner.go:393-432 |
| add | integration_points | Prometheus :: HTTP client | * | <empty> | <empty> | Prometheus is queried for flow control gate metric evaluation and backpressure | pkg/server/runner.go:97-98, pkg/server/options.go:51-54 |

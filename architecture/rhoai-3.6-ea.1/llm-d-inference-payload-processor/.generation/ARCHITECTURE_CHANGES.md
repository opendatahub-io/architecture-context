# Architecture Changes: llm-d-inference-payload-processor

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | http_endpoints | GET :: /metrics | * | <empty> | <empty> | Metrics HTTP endpoint exposed by controller-runtime metrics server on port 9090 with bearer-token authentication | cmd/runner/runner.go:173, pkg/server/options.go:65 |
| update | grpc_services | ExternalProcessor | Port | | 9004 | Default ExtProc gRPC port defined in options and exposed in Dockerfile | pkg/server/options.go:28, Dockerfile:51 |
| update | grpc_services | Health | Port | | 9005 | Default Health gRPC port defined in options and exposed in Dockerfile | pkg/server/options.go:29, Dockerfile:52 |
| add | authentication | Metrics HTTP :: GET | * | <empty> | <empty> | Metrics endpoint uses controller-runtime filters.WithAuthenticationAndAuthorization for bearer-token auth enabled by default | cmd/runner/runner.go:176-178, pkg/server/options.go:47 |

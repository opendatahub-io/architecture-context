# Architecture Changes: llm-d-kv-cache

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | HTTP Scoring API :: GET, POST | * | <empty> | <empty> | HTTP scoring endpoints have no authentication middleware configured; platform-level auth expected | examples/kv_events/online/main.go:306-316 |
| add | authentication | gRPC IndexerService :: All | * | <empty> | <empty> | gRPC server created without authentication interceptors; only OpenTelemetry stats handler configured | examples/kv_cache_index_service/server/main.go:98-101 |
| add | authentication | gRPC TokenizationService :: All | * | <empty> | <empty> | gRPC tokenizer uses UDS with filesystem permissions (directory mode 0700) for access control | services/uds_tokenizer/run_grpc_server.py:37-56 |
| add | internal_dependencies | vLLM | * | <empty> | <empty> | Component subscribes to vLLM KV cache events via ZeroMQ for block indexing | examples/kv_events/online/main.go:45-50 |
| add | services | kv-cache-manager HTTP | * | <empty> | <empty> | HTTP listener on port 8080 serving metrics and scoring endpoints | examples/kv_events/online/main.go:300-316 |
| add | services | tokenizer-probe HTTP | * | <empty> | <empty> | HTTP health probe server on port 8082 for Kubernetes liveness/readiness checks | services/uds_tokenizer/run_grpc_server.py:39-91 |
| add | services | tokenizer-grpc UDS | * | <empty> | <empty> | gRPC tokenization service over Unix Domain Socket at /tmp/tokenizer/tokenizer-uds.socket | services/uds_tokenizer/run_grpc_server.py:37-60 |
| add | integration_points | vLLM Engine :: ZMQ subscriber | * | <empty> | <empty> | ZeroMQ event subscription for KV cache block lifecycle events from vLLM engines | examples/kv_events/online/main.go:45-50 |

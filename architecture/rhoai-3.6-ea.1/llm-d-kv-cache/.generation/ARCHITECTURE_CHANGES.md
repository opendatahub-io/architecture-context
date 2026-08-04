# Architecture Changes: llm-d-kv-cache

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | HTTP Scoring API :: All | * | <empty> | <empty> | HTTP endpoints have no auth middleware or TLS; plain HTTP server with no enforcement | examples/kv_events/online/main.go:248, examples/kv_events/online/main.go:306-316 |
| add | authentication | gRPC IndexerService :: All | * | <empty> | <empty> | gRPC server created with only OTel stats handler, no TLS credentials or auth interceptors | examples/kv_cache_index_service/server/main.go:98 |
| add | authentication | UDS Tokenizer gRPC :: All | * | <empty> | <empty> | Tokenizer gRPC runs over Unix domain socket, pod boundary provides access control | services/uds_tokenizer/Dockerfile.konflux:57 |
| add | internal_dependencies | vLLM | * | <empty> | <empty> | Component consumes KV cache lifecycle events from vLLM engines via ZeroMQ pub/sub | examples/kv_events/online/main.go:49 |
| add | internal_dependencies | KServe | * | <empty> | <empty> | UDS tokenizer sidecar runs within KServe inference pods using emptyDir UDS mount | services/uds_tokenizer/Dockerfile.konflux:71 |
| add | integration_points | vLLM Engines :: ZMQ Pub/Sub subscriber | * | <empty> | <empty> | Receives KV cache lifecycle events from vLLM engines via ZeroMQ pub/sub on default port 5557 | examples/kv_events/online/main.go:49-50 |
| update | integration_points | Redis/Valkey :: Exchange client | Port | Configured by runtime | 6379 | Default Redis/Valkey port extracted from config default address redis://127.0.0.1:6379 | pkg/kvcache/kvblock/redis.go:45 |
| update | integration_points | Redis/Valkey :: Exchange client | Encryption | Configured by runtime | TLS via rediss:// scheme | TLS is supported via rediss:// or valkeys:// URL scheme; default is unencrypted TCP | pkg/kvcache/kvblock/redis.go:74-89 |
| update | integration_points | Redis/Valkey :: Exchange client | Purpose | Runtime queue and key-value data store | KV cache block index storage and retrieval | Purpose clarified from source evidence showing KV block indexing operations | pkg/kvcache/kvblock/redis.go:136-143 |

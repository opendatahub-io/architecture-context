workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and serves LLM models on OpenShift AI"

        kvCache = softwareSystem "llm-d-kv-cache" "Pluggable KV-cache management suite for cache-aware routing and cross-node cache coordination" {
            indexer = container "KV-Cache Indexer" "Core indexer library — tracks KV-block residency across pods, scores pods for cache-aware routing" "Go Library (pkg/kvcache)"
            eventPool = container "KV-Event Processing" "Sharded ZMQ subscriber pool that ingests KV-cache events from model servers" "Go Library (pkg/kvevents)"
            tokenProcessor = container "Token Processor" "Chained FNV-64a over CBOR hashing for content-addressable block keys" "Go Library (pkg/kvcache/kvblock)"
            blockIndex = container "Block Index" "Pluggable block residency store: in-memory LRU, Ristretto, or Redis" "Go Library (pkg/kvcache/kvblock)"
            udsTokenizer = container "UDS Tokenizer" "gRPC tokenization and chat template rendering sidecar over Unix Domain Socket" "Python gRPC Service"
            fsBackend = container "llmd-fs-backend" "vLLM plugin for KV-cache offloading between GPU and shared storage" "Python vLLM Plugin"
            pvcEvictor = container "PVC Evictor" "Manages PVC disk space via automated hysteresis-based eviction" "Python Utility Container"
        }

        epp = softwareSystem "llm-d EPP" "Inference scheduler that embeds the KV-cache indexer for cache-aware pod routing" "Internal llm-d"
        vllm = softwareSystem "vLLM" "High-throughput LLM inference engine with prefix caching" "Internal Platform"
        sglang = softwareSystem "SGLang" "Alternative LLM inference engine (experimental)" "Internal Platform"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        redis = softwareSystem "Redis / Valkey" "Optional distributed block index backend" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and tokenizer hosting platform" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for KV-cache block offloading" "External"
        otlp = softwareSystem "OTLP Collector" "OpenTelemetry trace collection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Relationships
        epp -> kvCache "Embeds indexer for pod scoring" "Go API (in-process)"
        vllm -> kvCache "Publishes KV-cache events" "ZMQ PUB/SUB 5557/TCP"
        sglang -> kvCache "Publishes KV-cache events (experimental)" "ZMQ PUB/SUB 5557/TCP"
        kvCache -> kubernetes "Discovers vLLM pods" "HTTPS 443/TCP"
        kvCache -> redis "Stores block index (optional)" "Redis 6379/TCP"
        kvCache -> huggingface "Downloads tokenizer models" "HTTPS 443/TCP"
        kvCache -> s3 "Offloads KV-cache blocks (optional)" "HTTPS 443/TCP"
        kvCache -> otlp "Exports traces" "gRPC 4317/TCP"
        kvCache -> prometheus "Exposes metrics" "HTTP"

        # Internal container relationships
        eventPool -> tokenProcessor "Passes parsed events"
        tokenProcessor -> blockIndex "Updates block residency"
        indexer -> blockIndex "Queries block locations"
        indexer -> udsTokenizer "Tokenizes prompts" "gRPC over UDS"
        udsTokenizer -> huggingface "Downloads tokenizer files" "HTTPS 443/TCP"
        fsBackend -> s3 "Stores/retrieves blocks" "HTTPS 443/TCP"
        pvcEvictor -> fsBackend "Evicts stale cache files" "POSIX filesystem"
    }

    views {
        systemContext kvCache "SystemContext" {
            include *
            autoLayout
        }

        container kvCache "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal llm-d" {
                background #e74c3c
                color #ffffff
            }
            element "Internal Platform" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

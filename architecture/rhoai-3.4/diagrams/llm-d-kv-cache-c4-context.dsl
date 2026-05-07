workspace {
    model {
        scheduler = person "llm-d-inference-scheduler" "Distributes inference requests across vLLM pods using cache-aware routing"

        llmdKVCache = softwareSystem "llm-d-kv-cache" "Pluggable KV-cache indexing and management service enabling cache-aware routing for distributed LLM inference" {
            indexer = container "KV-Cache Indexer" "Tokenizes prompts, computes KV-block keys, queries block index, and scores pods based on cache hit rates" "Go Library"
            eventPool = container "KV Events Pool" "Sharded worker pool that ingests ZMQ event streams from inference pods and updates block index in near-real-time" "Go Library"
            tokenProcessor = container "Token Processor" "FNV-64a hashing for block key computation from tokenized prompts" "Go Library"
            kvBlockScorer = container "KV Block Scorer" "Computes pod scores based on cache hit rates for routing decisions" "Go Library"
            inMemoryIndex = container "In-Memory LRU Index" "hashicorp/golang-lru based block index for single-node deployments" "Go Library"
            costAwareIndex = container "Cost-Aware Memory Index" "dgraph-io/ristretto based index with byte-level cost tracking" "Go Library"
            redisIndex = container "Redis/Valkey Index" "Distributed block index using HSET/HKEYS with Lua script atomic operations" "Go Library + Redis Client"
            udsTokenizer = container "UDS Tokenizer Service" "gRPC tokenization and chat template rendering service via Unix Domain Socket" "Python 3.12 gRPC Service"
            healthCheck = container "Health Check" "HTTP health probe endpoint for Kubernetes liveness/readiness" "HTTP 8082/TCP"
        }

        vllmPods = softwareSystem "vLLM/SGLang Inference Pods" "LLM serving framework pods that generate and stream KV-cache events" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for pod auto-discovery via controller-runtime watches" "External"
        redis = softwareSystem "Redis/Valkey" "Optional distributed KV-block index backend with RDMA support" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Tokenizer model file repository" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection via OTLP" "External"

        fsBackend = softwareSystem "llmd_fs_backend" "vLLM plugin for KV-cache offloading to shared filesystem with optional GPU Direct Storage" "Upstream Only"
        pvcEvictor = softwareSystem "PVC Evictor" "Automated disk space management for KV-cache PVCs" "Upstream Only"

        # Relationships
        scheduler -> llmdKVCache "Calls GetPodScores() for cache-aware routing" "Go Library API"
        vllmPods -> llmdKVCache "Streams KV-cache events (BlockStored, BlockRemoved, AllBlocksCleared)" "ZMQ PUB/SUB 5557/TCP, MessagePack"
        llmdKVCache -> kubernetesAPI "Auto-discovers vLLM pods for ZMQ subscriber management" "HTTPS 6443/TCP, mTLS"
        llmdKVCache -> redis "Stores/queries distributed block index" "RESP 6379/TCP, optional TLS"
        llmdKVCache -> huggingfaceHub "Downloads tokenizer model files" "HTTPS 443/TCP, Bearer Token"
        prometheus -> llmdKVCache "Scrapes metrics (admissions, evictions, latency)" "HTTP 8080/TCP"
        llmdKVCache -> otelCollector "Exports distributed traces" "gRPC OTLP 4317/TCP"

        # Internal container relationships
        scheduler -> indexer "GetPodScores(prompt, model)" "Go API"
        indexer -> tokenProcessor "Compute block keys" "In-process"
        indexer -> kvBlockScorer "Score pods" "In-process"
        indexer -> udsTokenizer "Tokenize prompts" "gRPC over UDS"
        indexer -> inMemoryIndex "Lookup/Add blocks" "In-process"
        indexer -> costAwareIndex "Lookup/Add blocks" "In-process"
        indexer -> redisIndex "Lookup/Add blocks" "In-process"
        eventPool -> inMemoryIndex "Update index on events" "In-process"
        eventPool -> costAwareIndex "Update index on events" "In-process"
        eventPool -> redisIndex "Update index on events" "In-process"
        udsTokenizer -> huggingfaceHub "Download tokenizer (first call)" "HTTPS 443/TCP"
        vllmPods -> eventPool "KV-cache events" "ZMQ SUB 5557/TCP"
        redisIndex -> redis "HSET, HKEYS, Lua scripts" "RESP 6379/TCP"
    }

    views {
        systemContext llmdKVCache "SystemContext" {
            include *
            autoLayout
        }

        container llmdKVCache "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Upstream Only" {
                background #cccccc
                color #333333
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}

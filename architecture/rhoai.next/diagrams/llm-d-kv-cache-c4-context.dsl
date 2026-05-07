workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and queries LLM inference models"
        platformengineer = person "Platform Engineer" "Configures inference platform and scheduling"

        llmdkvcache = softwareSystem "llm-d-kv-cache" "Pluggable KV-Cache indexing library and tooling for cache-aware routing in LLM inference platforms" {
            indexer = container "KV-Cache Indexer" "Core indexer library: block-key computation, index lookup, pod scoring for cache-aware routing" "Go Library (embedded in EPP)"
            eventsPool = container "KV-Events Pool" "Sharded worker pool consuming ZMQ messages from inference engines, maintaining index state" "Go Library"
            tokenPool = container "Tokenization Pool" "Client library providing gRPC-based tokenization via UDS socket" "Go Library"
            udsTokenizer = container "UDS Tokenizer Service" "Async gRPC sidecar for tokenization and chat template rendering using vLLM CPU-mode" "Python gRPC Sidecar" "Sidecar"
            fsBackend = container "llmd_fs_backend" "vLLM OffloadingConnector storage backend for GPU-to-storage KV-cache block transfers" "Python/C++/CUDA Plugin"
            pvcEvictor = container "PVC Evictor" "Multi-process disk space manager for KV-cache PVC storage with threshold-based eviction" "Python Sidecar Utility"
            indexBackend = container "Block Index Backend" "Pluggable storage: InMemory LRU, Ristretto, Redis, or Valkey" "Go"
        }

        epp = softwareSystem "llm-d Inference Scheduler (EPP)" "Envoy Processing Plugin that embeds the Indexer library for cache-aware request routing" "Internal llm-d"
        vllm = softwareSystem "vLLM / SGLang" "LLM inference engine pods publishing KV-Events and serving model predictions" "Internal Platform"
        k8sapi = softwareSystem "Kubernetes API" "Pod discovery and RBAC management" "Infrastructure"
        redis = softwareSystem "Redis / Valkey" "Optional external block index storage backend" "Infrastructure"
        hfhub = softwareSystem "HuggingFace Hub" "Model tokenizer file downloads" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection for block index operations" "Infrastructure"
        otel = softwareSystem "OpenTelemetry Collector" "OTLP trace export for distributed tracing" "Infrastructure"
        sharedstorage = softwareSystem "Shared Storage (NFS/PVC)" "Persistent storage for offloaded KV-cache blocks" "Infrastructure"

        # Relationships
        epp -> indexer "Embeds library, calls ScoreTokens() for cache-aware routing" "Go API (in-process)"
        vllm -> eventsPool "Publishes KV-Events (BlockStored, BlockRemoved, AllBlocksCleared)" "ZMQ PUB/SUB 5557/TCP msgpack"
        eventsPool -> indexer "Updates block index with ingested events" "Go API (in-process)"
        indexer -> tokenPool "Tokenizes prompts for block key computation" "Go API (in-process)"
        tokenPool -> udsTokenizer "gRPC tokenization requests" "gRPC over UDS socket"
        indexer -> indexBackend "Lookup, Add, Evict block entries" "Go interface (in-process)"
        indexBackend -> redis "Optional external storage" "Redis protocol 6379/TCP, optional TLS"
        udsTokenizer -> hfhub "Downloads tokenizer model files" "HTTPS 443/TCP, HF Token"
        indexer -> k8sapi "Pod discovery for ZMQ subscriber management" "HTTPS 443/TCP, Bearer token"
        indexer -> prometheus "Exposes kvcache metrics" "HTTP metrics scrape"
        indexer -> otel "Exports distributed traces" "gRPC OTLP 4317/TCP"
        vllm -> fsBackend "OffloadingConnector API for KV-cache transfers" "Python API (in-process)"
        fsBackend -> sharedstorage "Reads/writes KV-cache block files" "POSIX I/O or NIXL"
        pvcEvictor -> sharedstorage "Manages disk space via threshold-based eviction" "POSIX I/O"

        platformengineer -> epp "Configures inference scheduling and cache-aware routing"
        datascientist -> vllm "Sends inference requests to deployed models"
    }

    views {
        systemContext llmdkvcache "SystemContext" {
            include *
            autoLayout
        }

        container llmdkvcache "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal llm-d" {
                background #4a90e2
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Sidecar" {
                background #9b59b6
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys LLM models and sends inference requests"
        platformEngineer = person "Platform Engineer" "Configures llm-d routing and KV-cache policies"

        kvCache = softwareSystem "llm-d-kv-cache" "Pluggable KV-cache indexing library and sidecar services for cache-aware routing in vLLM-based LLM inference" {
            indexer = container "kvcache.Indexer" "Orchestrates block-key computation, index lookup, and pod scoring" "Go Library"
            eventPool = container "kvevents.Pool" "Sharded worker pool consuming ZMQ event streams from inference pods" "Go Library"
            blockIndex = container "kvblock.Index" "Pluggable block index backend (in-memory LRU, Ristretto, Redis)" "Go Library"
            tokenProcessor = container "kvblock.TokenProcessor" "FNV-1a hash computation for block content addressing" "Go Library"
            udsTokenizer = container "UDS Tokenizer" "Sidecar tokenization service over Unix Domain Socket" "Python 3.12 gRPC Service"
            fsBackend = container "llmd-fs-backend" "Storage backend for KV-cache offloading between GPU and shared storage" "Python vLLM Plugin"
            pvcEvictor = container "PVC Evictor" "Multi-process disk space manager for KV-cache storage on PVCs" "Python Utility"
        }

        eppRouter = softwareSystem "llm-d-router (EPP)" "Envoy Processing Policy router that embeds the KV-cache indexer" "Internal RHOAI"
        vllm = softwareSystem "vLLM / SGLang" "LLM inference engine pods emitting KV-cache events" "Internal RHOAI"
        redis = softwareSystem "Redis / Valkey" "Optional persistent block index backend" "External"
        hfHub = softwareSystem "Hugging Face Hub" "Tokenizer model downloads" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Pod discovery for ZMQ subscriber management" "External"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping for KV-cache statistics" "External"
        sharedPVC = softwareSystem "Shared PVC" "Persistent storage for offloaded KV-cache blocks" "External"

        # Relationships
        eppRouter -> kvCache "Embeds kvcache.Indexer for cache-aware routing" "Go module import"
        eppRouter -> udsTokenizer "Tokenizes prompts before scoring" "gRPC/UDS"
        vllm -> kvCache "Emits KV-cache block lifecycle events" "ZMQ/5557"
        kvCache -> redis "Optional persistent block index" "Redis/6379, TLS optional"
        udsTokenizer -> hfHub "Downloads tokenizer models" "HTTPS/443"
        kvCache -> k8sAPI "Pod discovery for ZMQ subscriptions" "HTTPS/443"
        kvCache -> otlpCollector "Exports distributed traces" "gRPC/4317"
        kvCache -> prometheus "Exposes kvcache metrics" "HTTP scrape"
        fsBackend -> sharedPVC "Writes offloaded KV-cache blocks" "POSIX I/O"
        pvcEvictor -> sharedPVC "Manages disk space for cached blocks" "POSIX I/O"
        vllm -> fsBackend "GPU-to-storage KV-cache offloading" "CUDA/DMA"

        dataScientist -> eppRouter "Sends inference requests"
        platformEngineer -> kvCache "Configures cache policies and index backends"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}

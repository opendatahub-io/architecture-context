workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys LLM models for inference with KV-cache-aware routing"

        kvCacheSystem = softwareSystem "llm-d-kv-cache" "Pluggable KV-cache indexing and event-processing library with companion tokenizer sidecar and storage management utilities" {
            indexerLib = container "KV-Cache Indexer Library" "Tracks KV-cache block locality across vLLM/SGLang pods; provides ScoreTokens() API for cache-aware routing" "Go Library"
            udsTokenizer = container "UDS Tokenizer" "gRPC sidecar providing tokenization and chat template rendering via Unix Domain Socket" "Python gRPC Service"
            fsBackend = container "llmd-fs-backend" "vLLM plugin offloading KV-cache blocks between GPU memory and shared storage" "Python/C++/CUDA vLLM Plugin"
            pvcEvictor = container "PVC Evictor" "Multi-process utility monitoring and evicting stale KV-cache files from PVCs" "Python Kubernetes Utility"
        }

        llmdRouter = softwareSystem "llm-d-router (EPP)" "Inference routing gateway that embeds the KV-cache indexer for cache-aware request routing" "Internal llm-d"
        vllm = softwareSystem "vLLM" "High-throughput LLM inference engine emitting KV-cache events via ZMQ" "Internal llm-d"
        sglang = softwareSystem "SGLang" "Alternative LLM inference engine with KV-cache event support" "Internal llm-d"
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster orchestration; used for pod discovery" "Infrastructure"
        redis = softwareSystem "Redis / Valkey" "Optional external block index backend for persistent/shared state" "External (optional)"
        hfHub = softwareSystem "HuggingFace Hub" "Model tokenizer artifact storage" "External"
        sharedStorage = softwareSystem "Shared Storage (NFS/PVC)" "Persistent storage for offloaded KV-cache blocks" "Infrastructure"
        otlp = softwareSystem "OpenTelemetry Collector" "Distributed trace collection endpoint" "Infrastructure (optional)"
        prometheus = softwareSystem "Prometheus" "Metrics scraping and alerting" "Infrastructure (optional)"

        # Relationships
        llmdRouter -> indexerLib "Embeds library; calls ScoreTokens()" "Go function call (in-process)"
        llmdRouter -> udsTokenizer "Tokenizes prompts before scoring" "gRPC over UDS"

        vllm -> indexerLib "Emits KV-cache events (BlockStored/BlockRemoved)" "ZMQ PUB/SUB 5557/TCP"
        sglang -> indexerLib "Emits KV-cache events (alternative engine)" "ZMQ PUB/SUB 5557/TCP"

        vllm -> fsBackend "Loads as vLLM general plugin for KV offloading" "Python entry point (in-process)"
        fsBackend -> sharedStorage "Offloads/loads KV-cache blocks" "POSIX filesystem"
        fsBackend -> indexerLib "Publishes storage events" "ZMQ PUSH"

        pvcEvictor -> sharedStorage "Monitors and evicts stale cache files" "POSIX filesystem"

        indexerLib -> k8sApi "Watches pods for auto-discovery mode" "HTTPS/443 TLS 1.2+"
        indexerLib -> redis "Optional external block index" "Redis protocol/6379"
        indexerLib -> otlp "Exports distributed traces" "gRPC/4317 OTLP"
        indexerLib -> prometheus "Exposes kvcache_index_* metrics" "HTTP scrape"

        udsTokenizer -> hfHub "Downloads model tokenizer files" "HTTPS/443 TLS 1.2+"

        datascientist -> llmdRouter "Sends inference requests" "HTTP/HTTPS"
    }

    views {
        systemContext kvCacheSystem "SystemContext" {
            include *
            autoLayout
        }

        container kvCacheSystem "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External (optional)" {
                background #bbbbbb
                color #ffffff
            }
            element "Internal llm-d" {
                background #4a90e2
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Infrastructure (optional)" {
                background #f5c573
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
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

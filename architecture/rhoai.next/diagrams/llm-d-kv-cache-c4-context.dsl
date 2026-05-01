workspace {
    model {
        scheduler = person "Inference Scheduler" "llm-d-inference-scheduler that routes inference requests to optimal pods"
        datascientist = person "Data Scientist" "Deploys and queries LLM inference services"

        kvCache = softwareSystem "llm-d-kv-cache" "Pluggable KV-cache management system for cache-aware routing and cross-node cache coordination in distributed LLM inference" {
            indexer = container "KV-Cache Indexer" "Core indexer: tokenizes prompts, computes block keys, queries index, scores pods for cache-aware routing" "Go Library (pkg/kvcache/)"
            eventsPool = container "KV Events Pool" "Sharded worker pool ingesting ZMQ-streamed KV-cache events from vLLM/SGLang engines" "Go Library (pkg/kvevents/)"
            blockIndex = container "KV Block Index" "Pluggable backend (in-memory LRU, Ristretto, Redis/Valkey) mapping block hashes to pod locations" "Go Library (pkg/kvcache/kvblock/)"
            tokenPool = container "Tokenization Pool" "Multi-strategy tokenizer with fallback chain: local file, UDS gRPC, HuggingFace download" "Go Library (pkg/tokenization/)"
            udsTokenizer = container "UDS Tokenizer Service" "Async gRPC server over Unix Domain Socket providing tokenization and chat template rendering" "Python 3.12 Sidecar"
            fsBackend = container "Filesystem Backend" "Shared storage KV-cache offloading manager with async GPU-to-storage transfers and NVIDIA GDS support" "Python/C++ vLLM Plugin"
            pvcEvictor = container "PVC Evictor" "Multi-process (N+2) autonomous disk usage monitoring and cache eviction service" "Python 3.12 Service"
            telemetry = container "Telemetry" "OpenTelemetry tracing and Prometheus metrics" "Go Library"
        }

        vllm = softwareSystem "vLLM Inference Pods" "vLLM-based model serving engines running distributed LLM inference" "External"
        sglang = softwareSystem "SGLang Pods" "Alternative inference engine with SGLang event format" "External"
        k8sApi = softwareSystem "Kubernetes API" "Kubernetes control plane for pod discovery and RBAC" "External"
        redis = softwareSystem "Redis / Valkey" "Optional distributed KV-block index backend" "External"
        sharedStorage = softwareSystem "Shared Storage (NFS/PVC)" "Persistent storage for KV-cache block files" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model and tokenizer artifact repository" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace collection endpoint" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Relationships - External
        scheduler -> kvCache "Embeds KV-cache indexer for cache-aware pod scoring" "Go library (in-process)"
        vllm -> kvCache "Streams KV-cache events (BlockStored/BlockRemoved)" "ZMQ PUB/SUB 5557/TCP"
        sglang -> kvCache "Streams KV-cache events (alternative format)" "ZMQ PUB/SUB 5557/TCP"
        kvCache -> k8sApi "Watches pods for dynamic ZMQ subscriber management" "HTTPS/443 TLS"
        kvCache -> redis "Stores/queries distributed block index" "RESP/6379"
        kvCache -> sharedStorage "Reads/writes KV-cache block files" "POSIX filesystem"
        kvCache -> hfHub "Downloads tokenizer models" "HTTPS/443 TLS 1.2+"
        kvCache -> otlpCollector "Exports distributed traces" "gRPC/4317"
        prometheus -> kvCache "Scrapes metrics" "HTTP/8080"

        # Relationships - Internal
        indexer -> tokenPool "Tokenizes prompts" "In-process"
        indexer -> blockIndex "Queries block locations" "In-process"
        eventsPool -> blockIndex "Updates block index" "In-process"
        tokenPool -> udsTokenizer "gRPC tokenization requests" "UDS socket"
        udsTokenizer -> hfHub "Downloads tokenizer models on first use" "HTTPS/443"
        fsBackend -> sharedStorage "Async GPU-to-storage transfers" "POSIX/GDS"
        pvcEvictor -> sharedStorage "Monitors and evicts cache files" "POSIX filesystem"
        telemetry -> otlpCollector "OTLP trace export" "gRPC/4317"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

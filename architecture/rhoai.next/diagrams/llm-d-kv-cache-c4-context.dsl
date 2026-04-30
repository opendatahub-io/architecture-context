workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys and manages LLM inference workloads"
        sre = person "SRE / Platform Admin" "Monitors and maintains the inference platform"

        kvCacheSystem = softwareSystem "llm-d-kv-cache" "Pluggable KV-cache management system enabling cache-aware routing and cross-node cache coordination for distributed LLM inference" {
            kvCacheIndexer = container "KV-Cache Indexer" "Core indexer that tokenizes prompts, computes block keys, queries the index, and scores pods for cache-aware routing" "Go Library (pkg/kvcache/)"
            kvEventsPool = container "KV Events Pool" "Sharded worker pool that ingests ZMQ-streamed KV-cache events from vLLM/SGLang engines and updates the block index in near-real-time" "Go Library (pkg/kvevents/)"
            kvBlockIndex = container "KV Block Index" "Pluggable backend (in-memory LRU, Ristretto, Redis/Valkey) mapping block hashes to pod locations" "Go Library (pkg/kvcache/kvblock/)"
            tokenizationSystem = container "Tokenization System" "Multi-strategy tokenizer pool with fallback chain: local file, UDS gRPC, HuggingFace download" "Go Library (pkg/tokenization/)"
            udsTokenizer = container "UDS Tokenizer Service" "Async gRPC server over Unix Domain Socket providing tokenization and chat template rendering via vLLM/HuggingFace" "Python 3.12 gRPC Sidecar"
            fsBackend = container "Filesystem Backend" "Shared storage KV-cache offloading manager with async GPU-to-storage transfers and NVIDIA GDS support" "Python/C++ vLLM Plugin"
            pvcEvictor = container "PVC Evictor" "Multi-process (N+2) autonomous disk usage monitoring and cache eviction service" "Python 3.12 Service"
            telemetry = container "Telemetry" "OTLP gRPC trace exporter and Prometheus metrics collector" "Go Library"
        }

        vllmPods = softwareSystem "vLLM Inference Pods" "LLM inference engine pods running vLLM or SGLang" "Internal Platform"
        scheduler = softwareSystem "llm-d-inference-scheduler" "Inference scheduler that embeds KV-cache indexer for cache-aware pod routing" "Internal Platform"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for pod discovery and RBAC" "External"
        redis = softwareSystem "Redis / Valkey" "Optional distributed key-value store for shared KV-block index" "External"
        sharedStorage = softwareSystem "Shared Storage (NFS/PVC)" "Persistent storage for KV-cache block offloading" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and tokenizer artifact repository" "External"
        modelscope = softwareSystem "ModelScope API" "Alternative model download source (optional)" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace collection endpoint" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping and storage system" "External"

        # External relationships
        dataScientist -> scheduler "Submits inference requests"
        sre -> prometheus "Monitors KV-cache metrics"
        sre -> otlpCollector "Reviews distributed traces"

        # System-level relationships
        vllmPods -> kvCacheSystem "Streams KV-cache events" "ZMQ PUB/SUB 5557/TCP"
        scheduler -> kvCacheSystem "Embeds for cache-aware routing" "Go library embedding"
        kvCacheSystem -> k8sAPI "Watches pods for ZMQ subscriber management" "HTTPS/443"
        kvCacheSystem -> redis "Optional distributed index backend" "RESP/6379"
        kvCacheSystem -> sharedStorage "KV-cache block offloading" "POSIX filesystem"
        kvCacheSystem -> huggingface "Downloads tokenizer models" "HTTPS/443"
        kvCacheSystem -> modelscope "Alternative model downloads" "HTTPS/443"
        kvCacheSystem -> otlpCollector "Exports distributed traces" "gRPC/4317"
        prometheus -> kvCacheSystem "Scrapes metrics" "HTTP/8080"

        # Container-level relationships
        kvEventsPool -> kvBlockIndex "Updates block locations"
        kvCacheIndexer -> kvBlockIndex "Queries block locations"
        kvCacheIndexer -> tokenizationSystem "Tokenizes prompts"
        tokenizationSystem -> udsTokenizer "gRPC tokenization" "gRPC over UDS"
        udsTokenizer -> huggingface "Downloads tokenizers" "HTTPS/443"
        fsBackend -> sharedStorage "Read/write cache files" "POSIX/GDS"
        pvcEvictor -> sharedStorage "Evicts stale cache files" "POSIX filesystem"
        kvCacheIndexer -> telemetry "Exports traces and metrics"
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
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and operates LLM inference workloads"
        sre = person "SRE / Platform Operator" "Manages inference platform and observability"

        llmdKVCache = softwareSystem "llm-d-kv-cache" "Pluggable KV-Cache indexing library and tooling for cache-aware routing and cross-node cache coordination in LLM inference platforms" {
            indexer = container "KV-Cache Indexer" "Core indexer orchestrating block-key computation, index lookup, and pod scoring for KV-cache-aware routing" "Go Library (pkg/kvcache)"
            eventPool = container "KV-Events Pool" "Sharded worker pool consuming ZMQ messages from inference engines and maintaining index state" "Go Library (pkg/kvevents)"
            tokenPool = container "Tokenization Pool" "Client library providing gRPC-based tokenization via UDS socket connection to sidecar service" "Go Library (pkg/tokenization)"
            udsTokenizer = container "UDS Tokenizer Service" "Async gRPC service for tokenization and chat template rendering using vLLM CPU-mode renderer" "Python gRPC Sidecar"
            fsBackend = container "llmd_fs_backend" "vLLM OffloadingConnector storage backend moving KV-cache blocks between GPU and shared storage" "Python/C++/CUDA Connector"
            pvcEvictor = container "PVC Evictor" "Multi-process disk space manager for KV-cache PVC storage with threshold-based eviction" "Python Utility"
        }

        eppScheduler = softwareSystem "llm-d Inference Scheduler (EPP)" "Envoy Processing Plugin that embeds the KV-Cache Indexer for cache-aware request routing" "Internal"
        vllmPods = softwareSystem "vLLM Inference Pods" "Model serving pods running vLLM with ZMQ event publishing and optional KV-cache offloading" "Internal"
        sglangPods = softwareSystem "SGLang Inference Pods" "Model serving pods running SGLang with ZMQ event publishing" "Internal"
        kubeAPI = softwareSystem "Kubernetes API" "Kubernetes control plane API server for pod discovery" "External"
        redis = softwareSystem "Redis / Valkey" "External key-value store for block index storage backend (optional)" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model and tokenizer file hosting service" "External"
        sharedStorage = softwareSystem "Shared Storage (NFS/PVC)" "Network-attached storage for KV-cache block offloading" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace collection service" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring system" "External"

        # Relationships - System Context
        eppScheduler -> llmdKVCache "Embeds indexer library for cache-aware pod scoring" "Go API (in-process)"
        vllmPods -> llmdKVCache "Publishes KV-Events (BlockStored, BlockRemoved, AllBlocksCleared)" "ZMQ msgpack/5557"
        sglangPods -> llmdKVCache "Publishes KV-Events" "ZMQ msgpack/5557"
        llmdKVCache -> redis "Stores/retrieves block index entries (optional)" "Redis/6379"
        llmdKVCache -> hfHub "Downloads tokenizer model files" "HTTPS/443"
        llmdKVCache -> kubeAPI "Pod discovery for subscriber management (optional)" "HTTPS/443"
        llmdKVCache -> sharedStorage "Reads/writes KV-cache blocks (fs_backend)" "POSIX I/O"
        llmdKVCache -> otlpCollector "Exports distributed traces (optional)" "gRPC/4317"
        llmdKVCache -> prometheus "Exposes metrics (admissions, evictions, latency)" "HTTP scrape"

        datascientist -> eppScheduler "Submits inference requests"
        sre -> prometheus "Monitors KV-cache performance"

        # Relationships - Container
        indexer -> eventPool "Receives indexed block state"
        indexer -> tokenPool "Requests tokenization"
        tokenPool -> udsTokenizer "gRPC over Unix Domain Socket"
        eventPool -> vllmPods "Subscribes to ZMQ events" "ZMQ SUB/5557"
        eventPool -> sglangPods "Subscribes to ZMQ events" "ZMQ SUB/5557"
        indexer -> redis "Block index CRUD (optional)" "Redis/6379"
        udsTokenizer -> hfHub "Downloads tokenizer files" "HTTPS/443"
        fsBackend -> sharedStorage "Offloads KV-cache blocks" "POSIX I/O"
        pvcEvictor -> sharedStorage "Evicts old cache blocks" "POSIX I/O"
        eventPool -> kubeAPI "Pod watch (optional)" "HTTPS/443"
        indexer -> otlpCollector "Trace export (optional)" "gRPC/4317"
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
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            relationship "Relationship" {
                dashed false
            }
        }
    }
}

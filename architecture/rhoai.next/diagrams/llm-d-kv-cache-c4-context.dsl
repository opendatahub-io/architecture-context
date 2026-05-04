workspace {
    model {
        scheduler = person "llm-d EPP (Inference Scheduler)" "Envoy Processing Plugin that routes inference requests with cache-aware scheduling"

        llmdKvCache = softwareSystem "llm-d-kv-cache" "Pluggable KV-Cache indexing library and tooling for cache-aware routing and cross-node cache coordination" {
            indexer = container "KV-Cache Indexer" "Core indexer: block-key computation, index lookup, pod scoring for KV-cache-aware routing" "Go Library (pkg/kvcache)"
            kveventsPool = container "KV-Events Pool" "Sharded worker pool consuming ZMQ messages from inference engines, maintaining index state" "Go Library (pkg/kvevents)"
            tokenizationPool = container "Tokenization Pool" "Client library providing gRPC-based tokenization via UDS socket connection" "Go Library (pkg/tokenization)"
            udsTokenizer = container "UDS Tokenizer Service" "Async gRPC service for tokenization and chat template rendering using vLLM CPU-mode renderer" "Python 3.12 gRPC Sidecar"
            fsBackend = container "llmd_fs_backend" "vLLM OffloadingConnector storage backend: GPU <-> shared storage KV-cache block transfer" "Python/C++/CUDA"
            pvcEvictor = container "PVC Evictor" "Multi-process disk space manager for KV-cache PVC storage with threshold-based eviction" "Python Utility"
        }

        vllmPods = softwareSystem "vLLM / SGLang Inference Pods" "LLM inference engines publishing KV-Events and serving model predictions" "Internal Platform"
        k8sAPI = softwareSystem "Kubernetes API" "Kubernetes API server for pod discovery and RBAC" "External"
        redis = softwareSystem "Redis / Valkey" "Optional external block index storage backend" "External Optional"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and tokenizer file hosting service" "External"
        sharedStorage = softwareSystem "Shared Storage (NFS/PVC)" "Shared filesystem for KV-cache block offloading" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection for block index operations" "External Optional"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "OTLP trace export for distributed tracing" "External Optional"

        # Relationships - Scheduler to library
        scheduler -> llmdKvCache "Embeds indexer library, calls ScoreTokens()" "Go API (in-process)"
        scheduler -> indexer "Calls ScoreTokens() for cache-aware routing" "Go API (in-process)"
        scheduler -> tokenizationPool "Tokenizes prompts for block-key computation" "Go API (in-process)"

        # Internal relationships
        indexer -> kveventsPool "Receives index updates (Add/Evict)" "Go interface (in-process)"
        tokenizationPool -> udsTokenizer "Tokenize requests" "gRPC over UDS"

        # External data flows
        vllmPods -> kveventsPool "Publishes KV-Events (BlockStored, BlockRemoved, AllBlocksCleared)" "ZMQ PUB/SUB 5557/TCP msgpack"
        vllmPods -> fsBackend "Offloads KV-cache blocks via OffloadingConnector" "Python/C++ API (in-process)"
        fsBackend -> sharedStorage "Reads/writes KV-cache block files" "POSIX I/O"
        pvcEvictor -> sharedStorage "Manages disk space with threshold-based eviction" "POSIX I/O"
        udsTokenizer -> huggingfaceHub "Downloads tokenizer model files" "HTTPS/443 TLS 1.2+"
        indexer -> redis "Stores/retrieves block index (optional)" "Redis/6379 optional TLS"
        kveventsPool -> k8sAPI "Pod discovery for ZMQ subscriber management (optional)" "HTTPS/443 Bearer Token"
        indexer -> prometheus "Exposes kvcache metrics (admissions, evictions, latency)" "HTTP metrics"
        indexer -> otlpCollector "Exports distributed traces" "gRPC/4317 OTLP"
    }

    views {
        systemContext llmdKvCache "SystemContext" {
            include *
            autoLayout
        }

        container llmdKvCache "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #bbbbbb
                color #ffffff
                shape RoundedBox
            }
            element "Internal Platform" {
                background #7ed321
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
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

workspace {
    model {
        dataSci = person "Data Scientist / ML Engineer" "Deploys inference services and models"
        sre = person "SRE / Platform Engineer" "Manages llm-d infrastructure"

        llmDKvCache = softwareSystem "llm-d-kv-cache" "Go library and Python sidecar services for KV-cache-aware routing in distributed LLM inference" {
            indexer = container "kvcache.Indexer" "KV-cache indexer orchestrating block-key computation, index lookup, and pod scoring via longest-prefix matching" "Go Library"
            eventPool = container "kvevents.Pool" "Sharded ZMQ event processing pool consuming KV-block lifecycle events from model servers" "Go Library"
            engineAdapter = container "engineadapter" "Engine-specific msgpack event parsers for vLLM and SGLang wire formats" "Go Library"
            blockIndex = container "kvblock.Index" "Pluggable block index backends: in-memory LRU, cost-aware Ristretto, Redis/Valkey" "Go Library"
            tokenProcessor = container "kvblock.TokenProcessor" "Token-to-block-key hashing using chained FNV-64a over CBOR-encoded content" "Go Library"
            tokenClient = container "tokenization.Client" "gRPC client for external tokenization via UDS" "Go Library"
            udsTokenizer = container "UDS Tokenizer" "Sidecar tokenizer and chat template renderer using vLLM's tokenization engine" "Python gRPC Service"
            fsBackend = container "llmd-fs-backend" "vLLM OffloadingConnector backend for GPU-to-shared-storage KV-cache block transfers" "Python Library / vLLM Plugin"
            pvcEvictor = container "PVC Evictor" "Multi-process utility for managing PVC disk space by evicting stale KV-cache blocks" "Python CLI"
        }

        llmDRouter = softwareSystem "llm-d-router (EPP)" "Envoy Processing Plugin for KV-aware request routing" "Internal llm-d"
        vllm = softwareSystem "vLLM Model Server" "High-throughput LLM inference engine with KV-cache management" "Internal llm-d"
        sglang = softwareSystem "SGLang Model Server" "Alternative LLM inference engine" "External"
        redis = softwareSystem "Redis / Valkey" "Optional external block index backend for cross-replica consistency" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and tokenizer artifact registry" "External"
        s3 = softwareSystem "S3 / Object Store" "KV-cache block storage for NIXL OBJ backend" "External"
        sharedFS = softwareSystem "Shared Filesystem (NFS/PVC)" "KV-cache block storage for POSIX backend" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Pod discovery for ZMQ subscriber management" "External"
        otlp = softwareSystem "OTLP Collector" "OpenTelemetry trace export" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping (kvcache_index_* metrics)" "External"

        # Relationships
        llmDRouter -> llmDKvCache "Embeds Indexer library for KV-aware routing decisions" "in-process"
        vllm -> llmDKvCache "Publishes KV-block lifecycle events" "ZMQ PUB/SUB msgpack 5557/TCP"
        sglang -> llmDKvCache "Publishes KV-block lifecycle events (alternative)" "ZMQ PUB/SUB msgpack 5557/TCP"
        llmDKvCache -> redis "Optional external block index" "Redis wire 6379/TCP"
        llmDKvCache -> huggingface "Downloads tokenizer model files" "HTTPS 443/TCP"
        llmDKvCache -> s3 "Offloads KV-cache blocks (OBJ backend)" "HTTPS 443/TCP"
        llmDKvCache -> sharedFS "Offloads KV-cache blocks (POSIX backend)" "POSIX I/O"
        llmDKvCache -> k8sAPI "Discovers model server pods" "HTTPS 443/TCP mTLS"
        llmDKvCache -> otlp "Exports OpenTelemetry traces" "gRPC 4317/TCP"
        llmDKvCache -> prometheus "Exposes kvcache_index_* metrics" "HTTP scrape"

        # Container relationships
        indexer -> tokenClient "Tokenize prompts" "in-process"
        indexer -> tokenProcessor "Compute block keys" "in-process"
        indexer -> blockIndex "Lookup block residency" "in-process"
        eventPool -> engineAdapter "Parse events" "in-process"
        engineAdapter -> blockIndex "Update index" "in-process"
        tokenClient -> udsTokenizer "gRPC over UDS" "/tmp/tokenizer/tokenizer-uds.socket"
        udsTokenizer -> huggingface "Download tokenizer files" "HTTPS 443/TCP"
        fsBackend -> s3 "Write/read KV blocks" "HTTPS 443/TCP"
        fsBackend -> sharedFS "Write/read KV blocks" "POSIX I/O"
        pvcEvictor -> sharedFS "Evict stale blocks" "POSIX I/O"
    }

    views {
        systemContext llmDKvCache "SystemContext" {
            include *
            autoLayout
        }

        container llmDKvCache "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal llm-d" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Go Library" {
                background #4a90e2
                color #ffffff
            }
            element "Python gRPC Service" {
                background #50c878
                color #ffffff
            }
            element "Python Library / vLLM Plugin" {
                background #50c878
                color #ffffff
            }
            element "Python CLI" {
                background #50c878
                color #ffffff
            }
        }
    }
}

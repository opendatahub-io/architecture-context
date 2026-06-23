workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and queries LLM inference models"

        kvCacheSystem = softwareSystem "llm-d-kv-cache" "KV-Cache indexing library and supporting services for KV-cache-aware routing in distributed LLM inference" {
            indexer = container "kvcache.Indexer" "Orchestrates block-key computation, index lookup, and scoring for KV-cache-aware routing" "Go Library"
            eventPool = container "kvevents.Pool" "Sharded worker pool consuming ZMQ events from inference engines, updating block index" "Go Library"
            blockIndex = container "kvblock.Index" "Pluggable block index backends (InMemory LRU, CostAwareMemory Ristretto, Redis/Valkey)" "Go Library"
            tokenProcessor = container "kvblock.TokenProcessor" "Converts token sequences to deterministic block keys via chained FNV-64a over CBOR" "Go Library"
            udsTokenizer = container "uds_tokenizer" "Sidecar tokenization service over UDS — Tokenize, RenderChatCompletion, InitializeTokenizer RPCs" "Python gRPC Service"
            fsBackend = container "llmd_fs_backend" "vLLM plugin — moves KV-cache blocks between GPU memory and shared storage (POSIX/S3)" "Python vLLM Plugin"
            pvcEvictor = container "pvc_evictor" "Multi-process PVC eviction service managing disk space for KV-cache storage" "Python Utility"
        }

        epp = softwareSystem "llm-d EPP" "Envoy Processing Policy — embeds kvcache.Indexer for KV-cache-aware routing decisions" "Internal llm-d"
        vllm = softwareSystem "vLLM / SGLang" "LLM inference engine pods that serve model predictions and emit KV-Events" "Internal llm-d"
        kubernetes = softwareSystem "Kubernetes API" "Cluster API server for pod discovery" "External"
        redis = softwareSystem "Redis / Valkey" "Optional external KV-block index persistence backend" "External"
        otlp = softwareSystem "OTLP Collector" "OpenTelemetry trace export destination" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        hfhub = softwareSystem "HuggingFace Hub" "Model tokenizer file downloads" "External"
        s3 = softwareSystem "S3 / Object Store" "Model artifact and KV-cache block storage" "External"
        sharedPVC = softwareSystem "Shared PVC" "POSIX filesystem for KV-cache block offloading" "External"

        # System-level relationships
        epp -> kvCacheSystem "Embeds kvcache.Indexer for KV-cache-aware routing" "Go API (in-process)"
        vllm -> kvCacheSystem "Emits KV-Events (BlockStored, BlockRemoved, AllBlocksCleared)" "ZMQ PUB/SUB 5557/TCP"
        kvCacheSystem -> kubernetes "Pod discovery — list/watch pods by label" "HTTPS/443"
        kvCacheSystem -> redis "External block index persistence" "Redis/6379"
        kvCacheSystem -> otlp "Distributed trace export" "gRPC/4317"
        prometheus -> kvCacheSystem "Scrapes metrics endpoint" "HTTP"
        kvCacheSystem -> hfhub "Downloads tokenizer model files" "HTTPS/443"
        kvCacheSystem -> s3 "KV-cache block storage (NIXL OBJ backend)" "HTTPS/443"
        kvCacheSystem -> sharedPVC "KV-cache block offloading (POSIX backend)" "POSIX I/O"

        # Container-level relationships
        epp -> indexer "ScoreTokens / ScorePrompt API" "Go function call"
        epp -> udsTokenizer "RenderChatCompletion, Tokenize" "gRPC over UDS"
        indexer -> tokenProcessor "Compute block keys from tokens" "Go function call"
        indexer -> blockIndex "Lookup cached blocks per pod" "Go function call"
        eventPool -> blockIndex "Add / Evict / Clear blocks" "Go function call"
        vllm -> eventPool "KV-Events stream" "ZMQ PUB/SUB 5557/TCP msgpack"
        eventPool -> kubernetes "Pod watch for ZMQ endpoint management" "HTTPS/443 ServiceAccount Token"
        blockIndex -> redis "External index backend" "Redis protocol 6379/TCP"
        udsTokenizer -> hfhub "Download tokenizer on first request" "HTTPS/443 Bearer Token"
        fsBackend -> sharedPVC "Write/read KV-cache blocks" "POSIX file I/O"
        fsBackend -> s3 "Write/read KV-cache blocks (NIXL)" "HTTPS/443 Access Key"
        pvcEvictor -> sharedPVC "Evict cold KV-cache files" "POSIX file I/O (delete)"
        indexer -> otlp "Export traces" "gRPC/4317 insecure"
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
                shape person
                background #08427B
                color #ffffff
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
                background #9b59b6
                color #ffffff
            }
            element "Python vLLM Plugin" {
                background #e67e22
                color #ffffff
            }
            element "Python Utility" {
                background #27ae60
                color #ffffff
            }
        }
    }
}

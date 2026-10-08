workspace {
    model {
        scheduler = person "Scheduler / llm-d-router" "Routes inference requests using KV-Cache-aware pod scoring"

        kvCacheSystem = softwareSystem "llm-d-kv-cache" "Pluggable KV-Cache management library and service suite for cache-aware routing in distributed LLM inference" {
            kvCacheManager = container "kv-cache-manager" "HTTP scoring service with /score_completions and /score_chat_completions endpoints" "Go Service, 8080/TCP"
            indexer = container "kvcache.Indexer" "Orchestrates block key computation, index lookup, and pod scoring" "Go Library"
            tokenProcessor = container "kvblock.TokenProcessor" "Converts token sequences into deterministic block keys using chained FNV-64a over CBOR" "Go Library"
            blockIndex = container "kvblock.Index" "Pluggable block index with LRU, Redis, Valkey, and cost-aware memory backends" "Go Library"
            scorer = container "kvblock.Scorer" "Computes per-pod cache-hit ratios using longest-consecutive-prefix algorithm" "Go Library"
            eventPool = container "kvevents.Pool" "Sharded ZMQ worker pool for ingesting KV-Events from vLLM engines" "Go Library"
            udsTokenizer = container "UDS Tokenizer" "Sidecar tokenization service wrapping vLLM Python tokenizer over Unix Domain Socket" "Python gRPC Service"
            pvcEvictor = container "PVC Evictor" "Multi-process disk space manager for KV-Cache offloading PVCs" "Python Service"
            indexService = container "IndexerService" "Example gRPC server for remote pod scoring" "Go gRPC Service, 50051/TCP"
        }

        redis = softwareSystem "Redis / Valkey" "KV-block index storage for block-to-pod mappings" "External"
        vllm = softwareSystem "vLLM / SGLang" "LLM inference engines streaming KV-Cache events" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"
        k8sApi = softwareSystem "Kubernetes API" "Pod discovery and cluster orchestration" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model and tokenizer artifact storage" "External"
        llmdRouter = softwareSystem "llm-d-router" "Inference gateway / EPP — primary consumer of kvcache libraries" "Internal llm-d"

        # External relationships
        scheduler -> kvCacheSystem "Scores pods for cache-aware routing" "HTTP/8080"
        llmdRouter -> kvCacheSystem "Embeds kvcache/kvevents libraries" "Go library embedding"

        # Internal container relationships
        kvCacheManager -> indexer "Delegates scoring requests"
        indexer -> tokenProcessor "Tokenizes prompts to block keys"
        indexer -> blockIndex "Looks up block-to-pod mappings"
        indexer -> scorer "Computes per-pod cache-hit scores"
        eventPool -> blockIndex "Updates index from KV-Events"
        kvCacheManager -> udsTokenizer "Chat template rendering" "gRPC/UDS"

        # Egress relationships
        blockIndex -> redis "Read/write block index" "TCP/6379"
        eventPool -> vllm "Subscribe to KV-Events" "ZMQ/5557"
        kvCacheManager -> otel "Export traces" "gRPC OTLP/4317"
        kvCacheManager -> k8sApi "Pod discovery" "HTTPS/6443"
        udsTokenizer -> hfHub "Download tokenizer models" "HTTPS/443"
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
            element "Internal llm-d" {
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

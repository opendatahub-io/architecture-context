workspace {
    model {
        router = person "llm-d-router" "Go routing service that bundles KV-cache libraries for KV-cache-aware inference routing"

        kvcache = softwareSystem "llm-d-kv-cache" "KV-cache management library and services for KV-cache-aware routing in llm-d distributed LLM inference platform" {
            indexer = container "kvcache.Indexer" "Core KV-cache indexing and scoring engine — computes block hashes, queries index, returns pod scores" "Go Library"
            pool = container "kvevents.Pool" "ZMQ event subscriber pool — ingests KV-cache events from vLLM engines and updates the block index" "Go Library"
            blockIndex = container "kvblock.Index" "Pluggable block index interface with Redis/Valkey, in-memory, and cost-aware backends" "Go Library"
            tokenProcessor = container "TokenProcessor" "Computes deterministic block hashes from tokenized prompts" "Go Library"
            scorer = container "KVBlockScorer" "Scores pods based on KV-cache block locality (GPU=1.0, CPU=0.8)" "Go Library"
            udsTokenizer = container "UDS Tokenizer" "Sidecar tokenization service using vLLM rendering pipeline over Unix Domain Socket" "Python gRPC Service"
            pvcEvictor = container "PVC Evictor" "Sidecar utility that manages disk space for KV-cache offloading on PVCs" "Python Service"
            onlineService = container "online HTTP Service" "Reference HTTP service exposing scoring endpoints and Prometheus metrics" "Go HTTP Service"
            indexerService = container "IndexerService" "Reference gRPC wrapper around the Indexer library for standalone deployment" "Go gRPC Service"
        }

        vllm = softwareSystem "vLLM Pods" "LLM inference engine pods that publish KV-cache events" "Internal"
        redis = softwareSystem "Redis/Valkey" "Shared KV-block index storage for multi-replica deployments" "Internal"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model tokenizer download service" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server" "External"

        router -> kvcache "Bundles as Go library import"
        router -> udsTokenizer "Tokenization requests" "gRPC/UDS"
        pool -> vllm "Subscribes to KV-cache events" "ZMQ SUB/5557"
        blockIndex -> redis "KV-block index read/write" "TCP/6379"
        onlineService -> otelCollector "Trace export" "gRPC/4317"
        udsTokenizer -> hfHub "Downloads tokenizer models" "HTTPS/443"
        indexer -> tokenProcessor "Computes block hashes"
        indexer -> blockIndex "Queries block index"
        indexer -> scorer "Scores pods"
        pool -> blockIndex "Updates block index"
    }

    views {
        systemContext kvcache "SystemContext" {
            include *
            autoLayout
        }

        container kvcache "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #7ed321
                color #000000
                shape Person
            }
        }
    }
}

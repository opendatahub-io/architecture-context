workspace {
    model {
        router = person "llm-d-router" "Primary consumer -- embeds kvcache library for cache-aware routing"

        kvCache = softwareSystem "llm-d-kv-cache" "Go library and services for KV-cache-aware routing in distributed LLM inference" {
            indexer = container "kvcache.Indexer" "Orchestrates block-key computation, index lookup, and pod scoring" "Go Library"
            tokenProcessor = container "kvblock.TokenProcessor" "Converts token sequences to deterministic KV-block keys via chained FNV-64a/CBOR" "Go Library"
            blockIndex = container "kvblock.Index" "Pluggable block index with in-memory LRU, cost-aware memory, Redis, and Valkey backends" "Go Library"
            eventPool = container "kvevents.Pool" "Sharded worker pool consuming ZMQ events from model servers" "Go Library"
            kvCacheManager = container "kv-cache-manager" "Standalone HTTP service exposing scoring endpoints" "Go Service" "8080/TCP"
            indexerService = container "IndexerService" "gRPC wrapper around kvcache.Indexer for remote scoring" "Go gRPC Service" "50051/TCP"
            udsTokenizer = container "UDS Tokenizer" "Tokenization and chat template rendering sidecar" "Python gRPC Service" "UDS"
            pvcEvictor = container "PVC Evictor" "Multi-process utility managing disk space for KV-cache offloading" "Python Service"
            podReconciler = container "PodReconciler" "controller-runtime reconciler for dynamic ZMQ subscriber management" "Go Controller"
        }

        redis = softwareSystem "Redis / Valkey" "KV-block index backend storage" "External"
        vllm = softwareSystem "vLLM / SGLang" "Model servers publishing KV-events via ZeroMQ" "External"
        k8sApi = softwareSystem "Kubernetes API" "Pod discovery and reconciliation" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Tokenizer model downloads" "External"

        router -> kvCache "Embeds kvcache library for cache-aware routing" "Go API"
        kvCache -> redis "Reads/writes KV-block index" "TCP/6379"
        kvCache -> vllm "Subscribes to KV-events" "ZMQ SUB/5557"
        kvCache -> k8sApi "Watches Pods for subscriber management" "HTTPS/6443"
        kvCache -> otel "Exports distributed traces" "gRPC OTLP/4317"
        kvCache -> hfHub "Downloads tokenizer models" "HTTPS/443"

        kvCacheManager -> indexer "Delegates scoring"
        indexerService -> indexer "Wraps for remote access"
        indexer -> tokenProcessor "Computes block keys"
        indexer -> blockIndex "Lookup and scoring"
        eventPool -> blockIndex "Updates index"
        podReconciler -> eventPool "Manages ZMQ subscribers"
        kvCacheManager -> udsTokenizer "Tokenization" "gRPC/UDS"
        blockIndex -> redis "Backend storage" "TCP/6379"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #7ed321
                color #ffffff
                shape Person
            }
        }
    }
}

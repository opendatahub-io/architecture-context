workspace {
    model {
        scheduler = person "Inference Scheduler" "llm-d-inference-scheduler or Envoy Gateway EPP that embeds the KV-cache indexer library"

        kvCache = softwareSystem "llm-d-kv-cache" "KV-Cache indexing library and tokenization sidecar for KV-cache-aware routing in distributed LLM inference" {
            indexer = container "kvcache.Indexer" "Maintains global KV-cache block index, scores pods for cache-aware routing" "Go Library"
            eventPool = container "kvevents.Pool" "Sharded worker pool ingesting KVEvents from ZMQ subscribers, updates block index" "Go Library"
            blockIndex = container "kvblock.Index" "Pluggable KV-block storage backend (InMemory, Redis, Valkey, CostAwareMemory)" "Go Library"
            tokenPool = container "tokenization.Pool" "Worker pool for tokenization tasks, supporting UDS and embedded backends" "Go Library"
            tokenProcessor = container "TokenProcessor" "CBOR canonical encoding + FNV-64a hashing for token-to-block-key conversion" "Go Library"
            udsTokenizer = container "UDS Tokenizer" "Python gRPC sidecar providing tokenization and chat template rendering via Unix Domain Socket" "Python 3.12 / vLLM CPU"
            pvcEvictor = container "PVC Evictor" "Multi-process service managing disk usage for filesystem-based KV-cache storage" "Python 3.12"
            fsBackend = container "llmd_fs_backend" "CUDA-accelerated filesystem storage connector for vLLM KV-cache offloading" "Python/C++/CUDA"
        }

        vllm = softwareSystem "vLLM Pods" "Large Language Model inference engines publishing KV-cache events" "External"
        redis = softwareSystem "Redis / Valkey" "Optional external KV-block index backend" "External"
        k8sApi = softwareSystem "Kubernetes API" "Pod discovery and watch for dynamic subscriber management" "External"
        hfHub = softwareSystem "Hugging Face Hub" "Tokenizer model file downloads" "External"
        otlpCollector = softwareSystem "OTLP Collector" "Distributed tracing export" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection for index operations" "External"
        envoyGateway = softwareSystem "Envoy Gateway EPP" "Inference routing using KV-cache scoring" "Internal llm-d"
        inferenceScheduler = softwareSystem "llm-d-inference-scheduler" "Scheduling service embedding indexer for pod scoring" "Internal llm-d"

        # External relationships
        scheduler -> kvCache "Embeds as Go library for KV-cache-aware pod scoring"
        kvCache -> vllm "Subscribes to KVEvents" "ZMQ PUB/SUB 5557/TCP, msgpack, plaintext"
        kvCache -> redis "Optional external block index" "Redis 6379/TCP, optional TLS"
        kvCache -> k8sApi "Watches pods for ZMQ subscriber management" "HTTPS 443/TCP, TLS, SA Token"
        kvCache -> hfHub "Downloads tokenizer files" "HTTPS 443/TCP, TLS 1.2+"
        kvCache -> otlpCollector "Exports distributed traces" "gRPC 4317/TCP, insecure"
        kvCache -> prometheus "Exposes metrics" "HTTP"

        # Internal relationships
        inferenceScheduler -> kvCache "Imports indexer + event pool as Go library"
        envoyGateway -> kvCache "Uses ComputeBlockKeys + ScoreTokens for routing"

        # Container relationships
        indexer -> eventPool "Receives parsed KVEvents"
        indexer -> blockIndex "Queries and updates block data"
        indexer -> tokenPool "Requests tokenization"
        indexer -> tokenProcessor "Converts tokens to block keys"
        tokenPool -> udsTokenizer "gRPC over UDS" "Unix Domain Socket, plaintext"
        eventPool -> vllm "ZMQ SUB" "5557/TCP, msgpack"
        blockIndex -> redis "Optional backend" "6379/TCP, Redis protocol"
        pvcEvictor -> fsBackend "Manages disk eviction"
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

workspace {
    model {
        dataScientist = person "Data Scientist" "Submits inference requests to LLM models"
        platformEngineer = person "Platform Engineer" "Deploys and configures the llm-d inference platform"

        llmdKVCache = softwareSystem "llm-d-kv-cache" "KV-cache indexing and scoring library for cache-aware routing in vLLM-based LLM inference" {
            kvCacheIndexer = container "KV-Cache Indexer" "Maintains global index of KV-cache block locality; scores pods for cache-aware routing" "Go Library (pkg/kvcache/)"
            kvEventsProcessor = container "KV-Events Processor" "Ingests KVEvents from vLLM/SGLang via ZMQ; sharded worker pool with FNV-1a routing" "Go Library (pkg/kvevents/)"
            tokenizationPool = container "Tokenization Pool" "Tokenizes prompts for block key computation; CompositeTokenizer with fallback chain" "Go Library (pkg/tokenization/)"
            udsTokenizer = container "UDS Tokenizer Service" "Standalone gRPC tokenizer sidecar; chat template rendering and multimodal support" "Python 3.12 gRPC Service"
            indexerGRPC = container "Indexer gRPC Service" "Exposes KV-cache indexer as gRPC service for external consumers" "gRPC API (api/indexerpb/)"
            llmdFSBackend = container "llmd_fs_backend" "vLLM plugin for cross-node KV-cache offloading via shared filesystem" "Python vLLM Plugin"
            pvcEvictor = container "PVC Evictor" "Multi-process disk space management; evicts stale KV-cache files from PVCs" "Python Utility"

            inMemoryIndex = container "InMemory Index" "LRU-based in-memory KV-block index" "Go (hashicorp/golang-lru)"
            costAwareIndex = container "CostAware Memory Index" "Memory-bounded KV-block index with cost-based eviction" "Go (dgraph-io/ristretto)"
            redisIndex = container "Redis Index" "Distributed KV-block index with pipelined commands and Lua cleanup" "Go Redis Client"

            kvCacheIndexer -> tokenizationPool "Tokenizes prompts" "In-process Go API"
            kvCacheIndexer -> inMemoryIndex "Reads/writes block index" "In-process"
            kvCacheIndexer -> costAwareIndex "Reads/writes block index" "In-process"
            kvCacheIndexer -> redisIndex "Reads/writes block index" "In-process"
            kvEventsProcessor -> kvCacheIndexer "Updates block index with events" "In-process Go API"
            tokenizationPool -> udsTokenizer "Tokenization requests" "gRPC via UDS"
        }

        inferenceScheduler = softwareSystem "llm-d-inference-scheduler" "Distributes inference requests across vLLM pods using cache-aware scheduling" "Internal llm-d"

        vllmPods = softwareSystem "vLLM Pods" "LLM inference engine pods running vLLM" "Internal"
        sglangPods = softwareSystem "SGLang Pods" "LLM inference engine pods running SGLang (alternative)" "Internal"
        redisValkey = softwareSystem "Redis/Valkey" "Optional distributed KV-block index backend" "External"
        huggingFaceHub = softwareSystem "Hugging Face Hub" "Model and tokenizer file repository" "External"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection endpoint" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for pod discovery" "Platform"
        sharedStorage = softwareSystem "Shared Storage (NFS/PVC)" "Cross-node KV-cache offloading storage" "Infrastructure"

        # Relationships
        inferenceScheduler -> llmdKVCache "Imports pkg/kvcache for pod scoring" "Go library import"
        vllmPods -> llmdKVCache "Publishes KVEvents (block stored/evicted/cleared)" "ZMQ PUB/SUB, no encryption"
        sglangPods -> llmdKVCache "Publishes KVEvents (alternative engine)" "ZMQ PUB/SUB, no encryption"
        llmdKVCache -> redisValkey "Stores/queries distributed block index" "Redis protocol/6379, optional TLS"
        llmdKVCache -> huggingFaceHub "Downloads tokenizer model files" "HTTPS/443, TLS 1.2+"
        llmdKVCache -> otlpCollector "Exports distributed traces" "gRPC/4317, OTLP"
        llmdKVCache -> kubernetesAPI "Discovers pods for dynamic ZMQ subscribers" "HTTPS/443, mTLS"
        llmdKVCache -> sharedStorage "KV-cache offloading and eviction" "File I/O"
        prometheus -> llmdKVCache "Scrapes metrics" "HTTP"

        dataScientist -> inferenceScheduler "Submits inference requests"
        platformEngineer -> llmdKVCache "Configures and deploys KV-cache components"
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
            element "Internal" {
                background #85BBF0
                color #ffffff
            }
            element "Platform" {
                background #08427B
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

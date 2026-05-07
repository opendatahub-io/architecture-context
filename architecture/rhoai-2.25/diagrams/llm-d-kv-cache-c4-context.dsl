workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models and submits inference requests"
        platformEngineer = person "Platform Engineer" "Configures and monitors the llm-d inference platform"

        kvCacheSystem = softwareSystem "llm-d KV-Cache" "Pluggable KV-cache indexing and management suite for KV-cache-aware routing, storage offloading, and cache eviction" {
            kvCacheManager = container "KV-Cache Manager" "Maintains block-level KV-cache locality index, computes per-pod scores for cache-aware routing" "Go Binary (StatefulSet)" {
                indexer = component "KV-Cache Indexer" "Core indexing engine — computes request keys from tokens, matches against stored engine keys, scores pods" "Go Library"
                eventsPool = component "KV-Events Pool" "Sharded ZMQ worker pool (FNV-1a on pod ID) that ingests KV-Events and updates block index" "Go Library"
                blockIndex = component "Block Index" "Pluggable block storage — InMemory LRU, Ristretto (cost-aware), or Redis" "Go Interface"
                tokenProcessor = component "Token Processor" "Computes FNV-1a hash chains from prompt tokens for request key generation" "Go Library"
                httpApi = component "HTTP API" "Scoring endpoints: /score_completions, /score_chat_completions, /metrics" "HTTP 8080/TCP"
                grpcApi = component "gRPC IndexerService" "GetPodScores RPC for remote scoring" "gRPC 50051/TCP"
            }

            udsTokenizer = container "UDS Tokenizer" "gRPC tokenization sidecar — text tokenization, chat template rendering, prompt preparation" "Python gRPC (Sidecar)" {
                tokenizerService = component "TokenizationService" "gRPC service: Tokenize, RenderChatTemplate, RenderChatCompletion, RenderCompletion, InitializeTokenizer" "gRPC via Unix Domain Socket"
            }

            fsBackend = container "LLMD FS Backend" "vLLM KV-cache offloading connector — GPU-to-storage and storage-to-GPU block transfers" "Python/C++ vLLM Plugin"
            pvcEvictor = container "PVC Evictor" "Multi-process daemon for automatic disk space management on KV-cache PVCs" "Python Daemon"
        }

        epp = softwareSystem "llm-d Inference Scheduler (EPP)" "Envoy Processing Plugin — primary consumer that embeds the KV-Cache Indexer for cache-aware routing" "Internal llm-d"
        vllm = softwareSystem "vLLM Model Servers" "Fleet of vLLM pods serving LLM inference, emitting KV-Events via ZMQ" "Internal llm-d"
        sglang = softwareSystem "SGLang Model Servers" "Alternative model server engine, same KV-Event format as vLLM" "Internal llm-d"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform — API server for pod discovery" "Infrastructure"
        redis = softwareSystem "Redis / Valkey" "Optional distributed block index backend" "Optional Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing export" "Optional Infrastructure"
        hfHub = softwareSystem "HuggingFace Hub" "Model and tokenizer download service" "External SaaS"
        s3 = softwareSystem "S3 Object Store" "Object storage for KV-cache block offloading" "External / Cloud"

        # Relationships
        epp -> kvCacheSystem "Embeds KV-Cache Indexer library for in-process scoring; also calls HTTP/gRPC APIs"
        vllm -> kvCacheSystem "Emits KV-Events (BlockStored, BlockRemoved, AllBlocksCleared)" "ZMQ PUB/SUB 5557/TCP"
        sglang -> kvCacheSystem "Emits KV-Events (same format as vLLM)" "ZMQ PUB/SUB 5557/TCP"
        kvCacheSystem -> kubernetes "Watches pods for auto-discovery of model servers" "HTTPS/443, SA Token"
        kvCacheSystem -> redis "Optional distributed block index" "Redis/6379, Optional TLS"
        kvCacheSystem -> hfHub "Downloads tokenizer models" "HTTPS/443, HF_TOKEN"
        kvCacheSystem -> s3 "Offloads KV-cache blocks to object storage" "HTTPS/443, AWS IAM"
        kvCacheSystem -> otelCollector "Exports distributed traces" "gRPC OTLP/4317"
        prometheus -> kvCacheSystem "Scrapes /metrics endpoint" "HTTP/8080"
        platformEngineer -> kvCacheSystem "Configures and monitors KV-cache infrastructure"
        dataScientist -> epp "Submits inference requests (indirectly triggers cache-aware routing)"

        # Container-level relationships
        epp -> kvCacheManager "Calls Indexer.ScoreTokens (in-process or gRPC/HTTP)"
        vllm -> kvCacheManager "ZMQ PUB KV-Events" "5557/TCP"
        kvCacheManager -> udsTokenizer "Tokenizes prompts" "gRPC via Unix Domain Socket"
        udsTokenizer -> hfHub "Downloads tokenizer models" "HTTPS/443"
        vllm -> fsBackend "Plugin API — offloads KV-cache blocks" "In-process"
        fsBackend -> s3 "Stores/retrieves KV blocks" "HTTPS/443"
        pvcEvictor -> kubernetes "Monitors PVC usage" "HTTPS/443"
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

        component kvCacheManager "KVCacheManagerComponents" {
            include *
            autoLayout
        }

        styles {
            element "External SaaS" {
                background #999999
                color #ffffff
            }
            element "External / Cloud" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Optional Infrastructure" {
                background #cccccc
                color #333333
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
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

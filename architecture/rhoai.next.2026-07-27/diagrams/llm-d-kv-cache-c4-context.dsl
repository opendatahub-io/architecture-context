workspace {
    model {
        client = person "Inference Router / Client" "Sends scoring requests to determine optimal pod for inference"

        kvCacheSystem = softwareSystem "llm-d-kv-cache" "KV cache indexing and scoring service for LLM inference optimization" {
            kvCacheIndexer = container "KV Cache Indexer" "Prefix-aware pod scoring engine with chunked token database" "Go Service"
            indexerService = container "IndexerService" "gRPC wrapper for KV Cache Indexer with OTel instrumentation" "Go gRPC Service" {
                tags "gRPC"
            }
            httpAPI = container "HTTP Scoring API" "REST endpoints for scoring completions and chat completions" "Go HTTP Server" {
                tags "HTTP"
            }
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint" "Go HTTP Service"
            podReconciler = container "PodReconciler" "Kubernetes controller watching inference pods for ZMQ endpoint discovery" "Go Controller (controller-runtime)"
            subscriberManager = container "SubscriberManager" "Manages per-pod ZMQ subscriptions for KV cache events" "Go Service"
            llmdFsBackend = container "llmd_fs_backend" "vLLM filesystem backend connector for KV cache offloading" "Python Module"
            udsTokenizer = container "UDS Tokenizer" "Tokenization and chat template rendering service" "Python gRPC Service"
        }

        vllmEngines = softwareSystem "vLLM Engine Pods" "LLM inference engine pods publishing KV cache events" "External"
        redisValkey = softwareSystem "Redis / Valkey" "Key-value data store for KV block metadata" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Kubernetes control plane for pod discovery and resource operations" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection service" "External"
        vllmRuntime = softwareSystem "vLLM Serving Runtime" "vLLM serving runtime for model inference" "Internal RHOAI"

        # External relationships
        client -> kvCacheSystem "Requests pod scores via HTTP/gRPC"
        kvCacheSystem -> vllmEngines "Subscribes to KV cache events" "ZMQ pub/sub"
        kvCacheSystem -> redisValkey "Stores/queries KV block metadata" "TCP"
        kvCacheSystem -> k8sAPI "Watches pods, reads resources" "HTTPS/6443"
        kvCacheSystem -> otelCollector "Exports traces" "OTLP/gRPC"
        kvCacheSystem -> vllmRuntime "Integrates for KV cache offloading"

        # Container relationships
        client -> httpAPI "POST /score_completions, /score_chat_completions" "HTTP/8080"
        client -> indexerService "GetPodScores" "gRPC/50051"
        httpAPI -> kvCacheIndexer "Delegates scoring"
        indexerService -> kvCacheIndexer "Delegates scoring"
        indexerService -> otelCollector "Exports trace spans" "OTLP/gRPC"
        kvCacheIndexer -> udsTokenizer "Tokenizes prompts" "gRPC/UDS"
        kvCacheIndexer -> redisValkey "Queries KV block index" "TCP"
        podReconciler -> subscriberManager "Adds/removes ZMQ subscriptions"
        podReconciler -> k8sAPI "Watches Pod resources" "HTTPS/WSS/6443"
        subscriberManager -> vllmEngines "Subscribes to KV cache events" "ZMQ topic: kv@"
        llmdFsBackend -> vllmRuntime "KV cache offloading connector"
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
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "gRPC" {
                background #4a90e2
            }
            element "HTTP" {
                background #f5a623
            }
        }
    }
}

workspace {
    model {
        routingLayer = person "llm-d EPP (Routing Layer)" "Prefix-aware request router that selects inference pods with maximum KV cache reuse"

        kvCache = softwareSystem "llm-d-kv-cache" "KV cache indexing and scoring infrastructure for distributed vLLM inference" {
            onlineService = container "Online Service" "ZMQ event subscriber, HTTP scoring API, Prometheus metrics" "Go"
            podReconciler = container "PodReconciler" "Tracks inference pod lifecycle via Kubernetes API watches" "Go (controller-runtime)"
            udsTokenizer = container "UDS Tokenizer" "gRPC tokenization service over Unix Domain Socket" "Python"
            indexerService = container "IndexerService" "gRPC prefix scoring service (example)" "Go"
            workerPool = container "Worker Pool" "Concurrent ZMQ event processing (4 workers default)" "Go goroutines"
            pvcEvictor = container "PVC Evictor" "Evicts cached KV data from PVCs" "Python"
        }

        vllm = softwareSystem "vLLM Inference Engines" "Distributed LLM inference engines publishing KV cache events" "External"
        redisValkey = softwareSystem "Redis/Valkey" "Key-value store backing the KV block index" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for pod lifecycle watches" "Infrastructure"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend" "Infrastructure"
        hfHub = softwareSystem "HuggingFace Hub" "Model tokenizer repository" "External"

        # External relationships
        routingLayer -> kvCache "Queries per-pod KV cache scores" "HTTP/8080"
        vllm -> kvCache "Publishes KV cache events (store/delete/clear)" "ZMQ/TCP/5557"
        kvCache -> redisValkey "Reads/writes KV block index" "TCP (redis:// or rediss://)"
        kvCache -> k8sAPI "Watches Pod resources" "HTTPS/6443"
        kvCache -> otelCollector "Exports traces" "OTLP/gRPC"
        kvCache -> hfHub "Downloads model tokenizers" "HTTPS/443"

        # Internal relationships
        routingLayer -> onlineService "POST /score_completions, /score_chat_completions" "HTTP/8080"
        vllm -> workerPool "KV cache lifecycle events" "ZMQ/TCP/5557"
        workerPool -> redisValkey "Updates prefix hash → pod+block mappings" "TCP"
        onlineService -> redisValkey "Queries prefix match scores" "TCP"
        podReconciler -> k8sAPI "Watch /v1/Pod add/remove events" "HTTPS/6443 + ServiceAccount"
        podReconciler -> redisValkey "Updates pod availability" "TCP"
        onlineService -> otelCollector "Runtime trace export" "OTLP/gRPC"
        indexerService -> otelCollector "Trace context propagation" "OTLP/gRPC"
        udsTokenizer -> hfHub "Downloads tokenizer models if not cached" "HTTPS/443"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #6c8ebf
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
        }
    }
}

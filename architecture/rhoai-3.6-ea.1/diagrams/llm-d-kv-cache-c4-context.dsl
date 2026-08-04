workspace {
    model {
        router = person "llm-d Endpoint Picker" "Routes inference requests to optimal vLLM pods based on KV cache scores"

        kvCache = softwareSystem "llm-d-kv-cache" "KV cache indexing and prefix-aware scoring for LLM inference, enabling cache-aware request routing" {
            onlineServer = container "Online Scoring Server" "Processes scoring requests and KV cache events, exposes HTTP /score_* endpoints" "Go Binary, Port 8080"
            indexerService = container "IndexerService gRPC Server" "Provides GetPodScores RPC for programmatic cache scoring" "Go Binary, gRPC Port 50051"
            podReconciler = container "Pod Reconciler" "Watches Pod lifecycle events to maintain cache index consistency" "Go controller-runtime Operator"
            kvBlockLib = container "KV Block Index Library" "Abstracts Redis/Valkey as KV block index backend" "Go Library (pkg/kvcache/kvblock)"
            kvEventsLib = container "KV Events Library" "Consumes ZeroMQ KV cache lifecycle events with configurable pool concurrency" "Go Library (pkg/kvevents)"
            udsTokenizer = container "UDS Tokenizer Sidecar" "Tokenizes prompts for cache matching via Unix domain socket" "Python gRPC, UDS /tmp/tokenizer"
            pvcEvictor = container "PVC Evictor" "Evicts cached data from persistent volumes" "Python Script"
            fsBackend = container "FS Backend" "Filesystem-based KV connector for cache offload" "Python"
        }

        vllm = softwareSystem "vLLM Engines" "Large language model inference engines that generate KV cache events" "External"
        redis = softwareSystem "Redis/Valkey" "In-memory data store used as KV block index backend" "External"
        kserve = softwareSystem "KServe" "Serverless inference platform hosting vLLM pods" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster control plane for pod lifecycle management" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Receives distributed traces via OTLP/gRPC" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes /metrics endpoint for operational metrics" "External"

        # External relationships
        router -> kvCache "Requests cache scores for routing decisions" "HTTP/8080, gRPC/50051"
        vllm -> kvCache "Publishes KV cache lifecycle events" "ZMQ/5557"
        kvCache -> redis "Stores and retrieves KV block index" "TCP/6379 (TLS optional)"
        kvCache -> k8sAPI "Watches Pod resources for lifecycle events" "HTTPS/6443"
        kvCache -> otelCollector "Exports distributed traces" "OTLP/gRPC (insecure)"
        prometheus -> kvCache "Scrapes operational metrics" "HTTP/8080 /metrics"
        kvCache -> kserve "Runs tokenizer sidecar within inference pods" "UDS"

        # Internal container relationships
        onlineServer -> kvBlockLib "Queries cache scores"
        onlineServer -> kvEventsLib "Processes ZMQ events"
        indexerService -> kvBlockLib "Queries cache scores"
        podReconciler -> kvBlockLib "Removes stale index entries"
        kvBlockLib -> redis "Read/write KV block index" "Redis protocol/6379"
        kvEventsLib -> vllm "Subscribes to KV events" "ZMQ sub/5557"
        podReconciler -> k8sAPI "Watches /v1/Pod" "HTTPS/6443"
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
            element "Internal RHOAI" {
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
            element "Person" {
                background #08427b
                color #ffffff
            }
        }
    }
}

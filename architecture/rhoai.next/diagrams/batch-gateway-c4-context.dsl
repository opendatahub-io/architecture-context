workspace {
    model {
        datascientist = person "Data Scientist / API Client" "Submits batch inference jobs via OpenAI-compatible Batch API"

        batchGateway = softwareSystem "Batch Gateway" "OpenAI-compatible batch API gateway for llm-d — accepts, queues, processes, and finalizes batch inference jobs" {
            apiserver = container "batch-gateway-apiserver" "RESTful API for batch job and file management with multi-tenant isolation" "Go HTTP Service" {
                batchHandler = component "Batch Handler" "CRUD operations for batch jobs" "Go"
                fileHandler = component "File Handler" "Upload, download, delete files" "Go"
                requestMiddleware = component "Request Middleware" "Tenant extraction, security headers, recovery" "Go"
            }
            processor = container "batch-gateway-processor" "Polls priority queue, dispatches inference requests with AIMD concurrency control" "Go Worker Service" {
                poller = component "Queue Poller" "Dequeues jobs from Redis priority queue" "Go"
                workerPool = component "Worker Pool" "Manages concurrent job execution (20 workers)" "Go"
                dispatchPipeline = component "Dispatch Pipeline" "PreDispatcher → AIMDDispatcher → DirectDispatcher chain" "Go"
                recoveryEngine = component "Recovery Engine" "Phase-aware crash recovery from emptyDir artifacts" "Go"
            }
            gc = container "batch-gateway-gc" "Garbage collects expired batches/files, reconciles orphaned jobs" "Go Background Service" {
                collector = component "GC Collector" "Removes expired batches and files (interval: 30m)" "Go"
                reconciler = component "Orphan Reconciler" "Detects and re-enqueues stuck jobs (interval: 60m)" "Go"
            }
        }

        postgresql = softwareSystem "PostgreSQL" "Persistent storage for batch job and file metadata with CAS status transitions" "External"
        redis = softwareSystem "Redis / Valkey" "Priority queue (ZSET), event channels (LIST/BLMPop), status store, in-flight tracking" "External"
        s3 = softwareSystem "S3-compatible Object Store" "File content storage for input/output JSONL files" "External"
        inferenceGateway = softwareSystem "LLM Inference Gateway" "vLLM or GIE/EPP — serves inference requests for LLM models" "External"
        llmdAsync = softwareSystem "llm-d-async" "Asynchronous inference dispatch library (optional, queue-based)" "Internal Platform"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing via OTLP gRPC export" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via /metrics scrape endpoints" "External"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning (optional)" "External"
        gatewayAPI = softwareSystem "Gateway API Gateway" "Kubernetes Gateway for external ingress via HTTPRoute" "External"

        # User interactions
        datascientist -> batchGateway "Submits batch jobs and uploads files" "HTTP/HTTPS on 8000/TCP"

        # Batch Gateway → External
        batchGateway -> postgresql "Stores and queries batch/file metadata" "TCP/5432"
        batchGateway -> redis "Priority queue, events, status, in-flight tracking" "TCP/6379"
        batchGateway -> s3 "Stores and retrieves file content (JSONL)" "HTTPS/443"
        batchGateway -> inferenceGateway "Dispatches inference requests (sync mode)" "HTTP(S)/configurable"
        batchGateway -> llmdAsync "Dispatches inference requests (async mode)" "Go library"
        batchGateway -> otel "Exports distributed traces" "gRPC/4317"
        prometheus -> batchGateway "Scrapes metrics" "HTTP/8081,9090,9091"
        certManager -> batchGateway "Provisions TLS certificates" "Certificate CR"
        gatewayAPI -> batchGateway "Routes external traffic" "HTTPRoute/8000"
    }

    views {
        systemContext batchGateway "SystemContext" {
            include *
            autoLayout
        }

        container batchGateway "Containers" {
            include *
            autoLayout
        }

        component apiserver "ApiserverComponents" {
            include *
            autoLayout
        }

        component processor "ProcessorComponents" {
            include *
            autoLayout
        }

        component gc "GCComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

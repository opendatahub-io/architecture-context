workspace {
    model {
        user = person "Data Scientist / API Client" "Submits batch inference jobs via OpenAI-compatible Batch API"
        platform_admin = person "Platform Admin" "Deploys and configures batch-gateway via Helm chart"

        batchGateway = softwareSystem "Batch Gateway" "OpenAI-compatible batch API gateway for llm-d that accepts, processes, and manages batch inference jobs" {
            apiserver = container "apiserver" "REST API server implementing OpenAI Batch API for batch and file CRUD operations. Multi-tenant isolation via tenant ID header." "Go HTTP Service" {
                batchHandler = component "Batch Handler" "Handles /v1/batches/* endpoints for batch CRUD and cancellation" "Go HTTP Handler"
                fileHandler = component "File Handler" "Handles /v1/files/* endpoints for file upload, download, listing, and deletion" "Go HTTP Handler"
                requestMiddleware = component "Request Middleware" "Extracts tenant ID from X-MaaS-Username header, enforces tenant isolation" "Go Middleware"
                securityMiddleware = component "Security Headers Middleware" "Adds X-Content-Type-Options, X-Frame-Options, CSP, HSTS headers" "Go Middleware"
            }

            processor = container "batch-processor" "Dequeues batch jobs from Redis priority queue and dispatches individual inference requests with AIMD adaptive concurrency control" "Go Worker Service" {
                workerPool = component "Worker Pool" "Concurrent goroutines polling Redis queue for batch jobs" "Go Goroutines"
                aimdController = component "AIMD Controller" "Adaptive semaphore: multiplicative decrease on 429/5xx, additive increase on success" "Go Concurrency"
                inferenceDispatcher = component "Inference Dispatcher" "Sends individual inference requests via sync HTTP or async llm-d-async queue" "Go HTTP Client"
            }

            gc = container "batch-gc" "Garbage collects expired batches and files, reconciles orphaned jobs stuck in non-terminal states" "Go Background Service" {
                collector = component "Garbage Collector" "Periodically scans and deletes expired batch jobs and files" "Go Worker"
                reconciler = component "Orphan Reconciler" "Detects jobs stuck due to processor crashes, re-enqueues or fails them" "Go Worker"
            }
        }

        postgresql = softwareSystem "PostgreSQL" "Batch and file metadata persistence with ACID guarantees" "External"
        redis = softwareSystem "Redis / Valkey" "Priority queue, event channels, status cache, in-flight tracking" "External"
        s3 = softwareSystem "S3-Compatible Storage" "File content storage for input JSONL, output results, and error logs" "External"
        inferenceGateway = softwareSystem "llm-d Inference Gateway" "Model serving endpoints for dispatching individual inference requests" "Internal Platform"
        llmdAsync = softwareSystem "llm-d-async" "Optional asynchronous inference dispatch and result collection via Redis queues" "Internal Platform"
        gatewayAPI = softwareSystem "Gateway API (Kubernetes)" "External traffic routing via HTTPRoute for /v1/batches and /v1/files paths" "External"
        certManager = softwareSystem "cert-manager" "Automatic TLS certificate provisioning for apiserver HTTPS" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor and PodMonitor resources" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing via OTLP gRPC export" "External"

        # Relationships - User
        user -> batchGateway "Submits batch jobs, uploads files, checks status" "HTTPS, Tenant ID Header"
        platform_admin -> batchGateway "Deploys and configures" "Helm Chart"

        # Relationships - System Context
        batchGateway -> postgresql "Stores/queries batch and file metadata" "TCP/5432, DSN credentials"
        batchGateway -> redis "Queue operations, events, status cache" "TCP/6379, URL credentials"
        batchGateway -> s3 "Uploads/downloads file content" "HTTPS/443, AWS credentials"
        batchGateway -> inferenceGateway "Dispatches inference requests" "HTTP(S), Bearer token or mTLS"
        batchGateway -> llmdAsync "Async inference dispatch (optional)" "Redis/6379"
        batchGateway -> otelCollector "Exports distributed traces" "gRPC OTLP"
        gatewayAPI -> batchGateway "Routes external traffic" "HTTPRoute CR"
        certManager -> batchGateway "Provisions TLS certificates" "Certificate CR"
        prometheus -> batchGateway "Scrapes metrics" "HTTP/8081, 9090, 9091"

        # Relationships - Container Level
        user -> apiserver "Creates batches, uploads files" "HTTP(S), Tenant ID Header"
        apiserver -> postgresql "Batch/file metadata CRUD" "TCP/5432"
        apiserver -> redis "Enqueue jobs, send events" "TCP/6379"
        apiserver -> s3 "Upload/download files" "HTTPS/443"

        processor -> redis "Dequeue jobs, update status" "TCP/6379"
        processor -> postgresql "Read/update batch metadata" "TCP/5432"
        processor -> s3 "Download input, upload output/error" "HTTPS/443"
        processor -> inferenceGateway "Dispatch inference requests" "HTTP(S), Bearer token"

        gc -> postgresql "Query/delete expired items" "TCP/5432"
        gc -> redis "Clean expired entries, reconcile orphans" "TCP/6379"
        gc -> s3 "Delete expired file content" "HTTPS/443"
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

        component apiserver "APIServerComponents" {
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
                shape Person
                background #4a90e2
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

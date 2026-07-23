workspace {
    model {
        datascientist = person "Data Scientist / API Consumer" "Submits batch inference jobs via OpenAI-compatible API"
        platformAdmin = person "Platform Admin" "Configures batch gateway deployment and monitors operations"

        batchGateway = softwareSystem "Batch Gateway" "High-performance batch inference gateway providing OpenAI-compatible API for large-scale batch inference jobs" {
            apiserver = container "API Server" "OpenAI-compatible REST API for batch job submission, tracking, file management, and cancellation" "Go HTTP Service (8080/TCP)" {
                batchHandler = component "Batch Handler" "Handles /v1/batches endpoints with tenant-scoped CRUD" "Go HTTP Handler"
                fileHandler = component "File Handler" "Handles /v1/files endpoints with multipart upload/download" "Go HTTP Handler"
                requestMiddleware = component "Request Middleware" "Extracts tenant ID from X-MaaS-Username header" "Go Middleware"
                securityMiddleware = component "Security Middleware" "Security headers and panic recovery" "Go Middleware"
                observabilityServer = component "Observability Server" "Health, readiness, metrics on port 8081" "Go HTTP Server"
            }
            processor = container "Batch Processor" "Dequeues jobs, builds per-model execution plans, dispatches inference requests with AIMD concurrency control" "Go Worker Service (9090/TCP)" {
                workerPool = component "Worker Pool" "Configurable concurrent worker goroutines" "Go Goroutines"
                dispatcherChain = component "Dispatcher Chain" "PreDispatcher → AIMD → Direct/Async dispatch" "Go Pipeline"
                crashRecovery = component "Crash Recovery" "Scans work directory on startup for incomplete jobs" "Go Service"
            }
            gc = container "Garbage Collector" "TTL-based cleanup of expired jobs/files and orphan reconciliation for crashed processors" "Go Daemon (9091/TCP)" {
                ttlCollector = component "TTL Collector" "Periodic deletion of expired batch jobs and files" "Go Service"
                orphanReconciler = component "Orphan Reconciler" "Detects stale in-flight jobs via heartbeat monitoring" "Go Service"
            }
        }

        postgresql = softwareSystem "PostgreSQL" "Batch job and file metadata storage with tenant-scoped row filtering" "External"
        redis = softwareSystem "Redis / Valkey" "Priority queue, event channels, status store, and in-flight tracking with Lua-scripted atomic operations" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Batch input/output file storage with tenant-partitioned folders" "External"
        llmdRouter = softwareSystem "llm-d Router" "Downstream inference endpoint for model serving with per-model routing" "Internal Platform"
        llmdAsync = softwareSystem "llm-d-async" "Optional async dispatch mode via Redis queue" "Internal Platform"
        kuadrant = softwareSystem "Kuadrant / Authorino" "Authentication and authorization enforcement at gateway layer" "Internal Platform"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for ingress routing via HTTPRoute" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor and PodMonitor" "External"
        otlpCollector = softwareSystem "OTLP Collector" "Distributed tracing export via OpenTelemetry" "External"
        grafana = softwareSystem "Grafana" "Dashboards loaded via ConfigMap sidecar" "External"

        # User interactions
        datascientist -> batchGateway "Submits batch jobs, uploads files, checks status via OpenAI-compatible REST API" "HTTPS"
        platformAdmin -> grafana "Monitors batch gateway dashboards" "HTTPS"

        # Batch Gateway → External dependencies
        batchGateway -> postgresql "Stores/queries batch and file metadata" "pgx/5432 Optional TLS"
        batchGateway -> redis "Queue management, event pub/sub, status tracking, in-flight coordination" "RESP/6379 Optional TLS/mTLS"
        batchGateway -> s3 "Uploads/downloads batch input and output files" "HTTPS/443 TLS"
        batchGateway -> llmdRouter "Dispatches individual inference requests from batch jobs" "HTTP(S)/configurable API Key/mTLS"
        batchGateway -> llmdAsync "Optional: enqueues inference requests for async processing" "RESP/6379"
        batchGateway -> otlpCollector "Exports distributed traces" "gRPC Optional TLS"

        # Platform integrations
        kuadrant -> batchGateway "Enforces AuthN/AuthZ via Gateway API AuthPolicy" ""
        gatewayAPI -> batchGateway "Routes /v1/batches and /v1/files via HTTPRoute" "HTTP(S)"
        prometheus -> batchGateway "Scrapes metrics from ports 8081, 9090, 9091" "HTTP"

        # Container-level relationships
        apiserver -> postgresql "CRUD batch/file metadata" "pgx/5432"
        apiserver -> redis "Enqueue jobs, publish cancel events" "RESP/6379"
        apiserver -> s3 "Upload/download files" "HTTPS/443"
        processor -> postgresql "Read/update batch metadata" "pgx/5432"
        processor -> redis "Dequeue jobs, subscribe events, update status, heartbeat" "RESP/6379"
        processor -> s3 "Download input, upload output/error files" "HTTPS/443"
        processor -> llmdRouter "Dispatch inference requests with AIMD flow control" "HTTP(S)"
        gc -> postgresql "Query/delete expired metadata, reconcile orphans" "pgx/5432"
        gc -> redis "Check in-flight heartbeats, manage queue state" "RESP/6379"
        gc -> s3 "Delete expired files" "HTTPS/443"
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

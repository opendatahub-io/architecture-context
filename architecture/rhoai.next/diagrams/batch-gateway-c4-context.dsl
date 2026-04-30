workspace {
    model {
        user = person "Data Scientist / API Consumer" "Submits batch inference jobs and uploads input files via OpenAI-compatible API"

        batchGateway = softwareSystem "Batch Gateway" "OpenAI-compatible batch inference API gateway for llm-d that manages large-scale batch job submission, processing, and lifecycle" {
            apiserver = container "API Server" "REST API implementing OpenAI-compatible /v1/batches and /v1/files endpoints for batch job and file management" "Go HTTP Service" {
                batchHandler = component "Batch Handler" "Handles /v1/batches CRUD operations" "Go Handler"
                fileHandler = component "File Handler" "Handles /v1/files CRUD and content download" "Go Handler"
                requestMiddleware = component "Request Middleware" "Extracts tenant ID from configurable header" "Go Middleware"
                securityMiddleware = component "Security Headers" "Adds security response headers" "Go Middleware"
                healthHandler = component "Health/Ready/Metrics" "Observability endpoints on port 8081" "Go Handler"
            }
            processor = container "Batch Processor" "Polls priority queue, preprocesses input files into execution plans, dispatches inference requests with concurrency control" "Go Background Worker" {
                poller = component "Queue Poller" "BZMPop from Redis priority queue" "Go Worker"
                preprocessor = component "Preprocessor" "Builds binary plan files sorted by system prompt hash" "Go Component"
                executor = component "Executor" "Dispatches inference requests with global and per-model concurrency semaphores" "Go Worker"
                finalizer = component "Finalizer" "Uploads output/error files, updates batch status" "Go Component"
                cancelWatcher = component "Cancel Watcher" "Monitors cancel events via BLMPop" "Go Worker"
                recovery = component "Recovery" "Startup crash recovery for partial results" "Go Component"
            }
            gc = container "Garbage Collector" "Periodically scans for and removes expired batch jobs and files from database and storage" "Go Background Worker"
        }

        postgresql = softwareSystem "PostgreSQL" "Persistent metadata storage for batch job and file records" "External"
        redis = softwareSystem "Redis/Valkey" "Priority queue, event channels, and real-time status tracking" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Stores batch input, output, and error JSONL files" "External"
        inferenceGateway = softwareSystem "llm-d Inference Gateway" "Downstream LLM inference gateway for processing individual requests" "Internal Platform"
        kuadrant = softwareSystem "Kuadrant/Authorino" "External auth gateway that authenticates users and injects tenant header" "External"
        gatewayAPI = softwareSystem "llm-d Gateway (Gateway API)" "Optional Gateway API HTTPRoute for ingress routing" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend" "External"
        grafana = softwareSystem "Grafana" "Dashboard visualization with pre-built dashboards" "External"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate provisioning" "External"

        # Relationships
        user -> kuadrant "Authenticates via Bearer token" "HTTPS/443"
        kuadrant -> batchGateway "Injects tenant header, forwards request" "HTTP(S)/8000"
        gatewayAPI -> batchGateway "Routes /v1/batches, /v1/files" "HTTPRoute"
        user -> batchGateway "Creates batch jobs, uploads files" "HTTP(S)/8000"

        batchGateway -> postgresql "Reads/writes batch and file metadata" "pgx/5432"
        batchGateway -> redis "Enqueues/dequeues jobs, publishes cancel events, tracks progress" "RESP/6379"
        batchGateway -> s3 "Uploads/downloads batch input, output, error files" "HTTPS/443"
        batchGateway -> inferenceGateway "Dispatches individual inference requests" "HTTP(S)/configurable"
        batchGateway -> otelCollector "Exports distributed traces" "gRPC OTLP"

        prometheus -> batchGateway "Scrapes /metrics endpoints" "HTTP/8081,9090"
        grafana -> prometheus "Visualizes metrics" "HTTP"
        certManager -> batchGateway "Provisions TLS certificates" "K8s API"

        # Container relationships
        apiserver -> postgresql "Stores batch/file metadata" "pgx/5432"
        apiserver -> redis "Enqueues to priority queue, publishes cancel events" "RESP/6379"
        apiserver -> s3 "Stores uploaded files" "HTTPS/443"

        processor -> postgresql "Reads metadata, updates batch status" "pgx/5432"
        processor -> redis "Dequeues from priority queue, monitors cancel events" "RESP/6379"
        processor -> s3 "Downloads inputs, uploads outputs" "HTTPS/443"
        processor -> inferenceGateway "Dispatches inference requests" "HTTP(S)"

        gc -> postgresql "Queries and deletes expired records" "pgx/5432"
        gc -> redis "Queries and deletes expired entries" "RESP/6379"
        gc -> s3 "Deletes expired files" "HTTPS/443"
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

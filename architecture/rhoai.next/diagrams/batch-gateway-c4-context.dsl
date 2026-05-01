workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits batch inference jobs via OpenAI-compatible API"

        batchGateway = softwareSystem "Batch Gateway" "OpenAI-compatible batch inference API gateway for llm-d that manages large-scale batch job submission, processing, and lifecycle" {
            apiserver = container "API Server" "REST API implementing OpenAI-compatible /v1/batches and /v1/files endpoints for batch job and file management" "Go HTTP Service" {
                batchHandler = component "Batch Handler" "Handles batch job CRUD operations" "Go Handler"
                fileHandler = component "File Handler" "Handles file upload/download/delete" "Go Handler"
                tenantMiddleware = component "Tenant Middleware" "Extracts and enforces tenant ID from X-MaaS-Username header" "Go Middleware"
                securityMiddleware = component "Security Headers MW" "Adds security response headers" "Go Middleware"
            }
            processor = container "Batch Processor" "Polls priority queue, preprocesses batch input files into per-model execution plans, dispatches inference requests with concurrency control" "Go Background Worker" {
                poller = component "Queue Poller" "Blocking dequeue from Redis sorted set" "Go Goroutine"
                preprocessor = component "Preprocessor" "Builds binary plan files sorted by system prompt hash for KV cache optimization" "Go"
                executor = component "Executor" "Dispatches inference requests with global and per-model semaphores" "Go"
                finalizer = component "Finalizer" "Uploads result files and updates batch status" "Go"
                recovery = component "Startup Recovery" "Recovers partial results from previous crashes" "Go"
            }
            gc = container "Garbage Collector" "Periodically scans for and removes expired batch jobs and files from database and storage" "Go Background Worker"
        }

        postgresql = softwareSystem "PostgreSQL" "Persistent metadata storage for batch job and file records" "External Database"
        redis = softwareSystem "Redis / Valkey" "Priority queue (sorted set), event channels (list pub/sub), real-time status tracking" "External Database"
        s3 = softwareSystem "S3-Compatible Storage" "Stores batch input, output, and error JSONL files" "External Storage"
        inferenceGateway = softwareSystem "llm-d Inference Gateway" "LLM inference serving endpoint for individual request processing" "Internal Platform"
        authorino = softwareSystem "Kuadrant / Authorino" "External auth gateway that authenticates users and injects tenant header" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for API server HTTPS" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor and PodMonitor" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend for OTLP trace export" "External"
        grafana = softwareSystem "Grafana" "Dashboard visualization with pre-built dashboards" "External"
        gatewayAPI = softwareSystem "Gateway API (HTTPRoute)" "Optional ingress routing for /v1/batches and /v1/files traffic" "External"
        gie = softwareSystem "GIE InferenceObjective CRD" "Priority-band flow control for batch vs interactive workload balancing" "Internal Platform"

        # Relationships
        user -> authorino "Authenticates via API key / SA token / OpenShift token" "HTTPS/443"
        authorino -> apiserver "Forwards request with tenant header" "HTTP(S)/8000"
        gatewayAPI -> apiserver "Routes /v1/batches and /v1/files" "HTTP(S)/8000"
        user -> batchGateway "Submits batch jobs and uploads files" "HTTPS"

        apiserver -> postgresql "Stores batch and file metadata" "pgx/5432"
        apiserver -> redis "Enqueues jobs, publishes cancel events" "RESP/6379"
        apiserver -> s3 "Uploads and downloads JSONL files" "HTTPS/443"

        processor -> postgresql "Reads job metadata, updates status" "pgx/5432"
        processor -> redis "Dequeues jobs, subscribes cancel events, updates progress" "RESP/6379"
        processor -> s3 "Downloads input files, uploads output/error files" "HTTPS/443"
        processor -> inferenceGateway "Dispatches individual inference requests" "HTTP(S)"
        processor -> gie "Reads InferenceObjective for priority scheduling" "Header injection"

        gc -> postgresql "Queries and deletes expired metadata" "pgx/5432"
        gc -> redis "Queries and deletes expired data" "RESP/6379"
        gc -> s3 "Deletes expired physical files" "HTTPS/443"

        certManager -> apiserver "Provisions TLS certificates" "kubernetes.io/tls"
        prometheus -> apiserver "Scrapes metrics" "HTTP/8081"
        prometheus -> processor "Scrapes metrics" "HTTP/9090"
        apiserver -> otelCollector "Exports traces" "gRPC/OTLP"
        processor -> otelCollector "Exports traces" "gRPC/OTLP"
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
            element "External Database" {
                background #336791
                color #ffffff
                shape Cylinder
            }
            element "External Storage" {
                background #ff9900
                color #ffffff
                shape Cylinder
            }
            element "Internal Platform" {
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
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

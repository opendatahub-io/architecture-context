workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits batch inference jobs via OpenAI-compatible API"

        batchGateway = softwareSystem "llm-d Batch Gateway" "High-performance OpenAI-compatible batch inference API gateway for processing large-scale batch jobs in Kubernetes environments" {
            apiserver = container "API Server" "REST API server exposing OpenAI-compatible /v1/batches and /v1/files endpoints" "Go HTTP Service" "Deployment"
            processor = container "Batch Processor" "Pulls batch jobs from priority queue, builds per-model execution plans, dispatches inference requests with AIMD concurrency control" "Go Background Worker" "StatefulSet"
            gc = container "Garbage Collector" "Periodically removes expired batch jobs and files, reconciles orphaned jobs after processor crashes" "Go Background Worker" "Deployment"
        }

        postgresql = softwareSystem "PostgreSQL" "Job and file metadata storage" "External"
        redis = softwareSystem "Redis / Valkey" "Priority queue, event pub/sub, status updates" "External"
        s3 = softwareSystem "S3-compatible Storage" "Batch input/output file storage" "External"
        inferenceGW = softwareSystem "llm-d Inference Gateway" "Model serving endpoint for individual inference requests" "Internal Platform"
        llmdAsync = softwareSystem "llm-d-async" "Async inference dispatch via Redis queues" "Internal Platform"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for pod lifecycle watching" "Infrastructure"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics scraping and alerting" "Infrastructure"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning" "Infrastructure"

        # User interactions
        user -> batchGateway "Submits batch jobs via POST /v1/batches, uploads files via POST /v1/files" "HTTPS/8000"

        # API Server dependencies
        apiserver -> postgresql "Stores/queries job and file metadata" "TCP/pgx"
        apiserver -> redis "Enqueues batch jobs to priority queue" "TCP/go-redis"
        apiserver -> s3 "Stores/retrieves input and output files" "HTTPS/AWS SDK"

        # Processor dependencies
        processor -> redis "Polls priority queue for pending jobs" "TCP/go-redis"
        processor -> s3 "Reads input files, writes output files" "HTTPS/AWS SDK"
        processor -> inferenceGW "Dispatches individual inference requests" "HTTP(S)/resty"
        processor -> llmdAsync "Async dispatch mode: queues requests via Redis" "In-process"
        processor -> postgresql "Updates job status and metadata" "TCP/pgx"

        # GC dependencies
        gc -> postgresql "Queries and deletes expired records" "TCP/pgx"
        gc -> s3 "Deletes expired files" "HTTPS/AWS SDK"
        gc -> k8sAPI "Watches processor pods for orphan reconciliation" "HTTPS/6443"

        # Observability
        apiserver -> otelCollector "Exports distributed traces" "OTLP/gRPC"
        processor -> otelCollector "Exports distributed traces" "OTLP/gRPC"
        prometheus -> apiserver "Scrapes metrics" "HTTP/8081"
        prometheus -> processor "Scrapes metrics" "HTTP/9090"
        prometheus -> gc "Scrapes metrics" "HTTP/9091"

        # Infrastructure
        certManager -> apiserver "Provisions TLS certificates" "Kubernetes API"
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

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

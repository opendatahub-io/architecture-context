workspace {
    model {
        user = person "API Consumer" "Submits batch inference jobs and retrieves results via OpenAI-compatible API"

        batchGateway = softwareSystem "llm-d Batch Gateway" "OpenAI-compatible batch inference gateway that processes large-scale batch jobs alongside interactive workloads" {
            apiserver = container "batch-gateway-apiserver" "REST API server handling batch job submission, management, tracking, and file operations" "Go HTTP Service" "Deployment"
            processor = container "batch-gateway-processor" "Pulls batch jobs from priority queue, dispatches inference requests with AIMD adaptive concurrency control" "Go Background Worker" "StatefulSet"
            gc = container "batch-gateway-gc" "Garbage collector for expired jobs/files; orphan reconciler for crashed processor recovery" "Go Background Worker" "Deployment"
        }

        externalGateway = softwareSystem "External Gateway" "Kuadrant/Authorino — API authentication, authorization, and routing" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for batch job and file metadata storage" "External"
        redis = softwareSystem "Redis/Valkey" "Priority queue, event channels, and job status tracking" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for batch input/output JSONL files" "External"
        llmdGateway = softwareSystem "llm-d Inference Gateway" "Downstream inference endpoint for model serving" "Internal Platform"
        llmdAsync = softwareSystem "llm-d-async" "Optional async dispatch via Redis-backed inference pools" "Internal Platform"
        k8sApi = softwareSystem "Kubernetes API" "Pod watching for orphan reconciliation" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping from observability endpoints" "External"

        # External relationships
        user -> externalGateway "Submits batch jobs and files" "HTTPS/443"
        externalGateway -> batchGateway "Forwards authenticated requests with tenant header" "HTTP(S)/8000"

        # Internal container relationships
        externalGateway -> apiserver "Forwards requests with X-MaaS-Username" "HTTP(S)/8000"
        apiserver -> postgresql "Stores job and file metadata" "TCP"
        apiserver -> redis "Enqueues batch jobs" "TCP"
        apiserver -> s3 "Stores uploaded input files" "HTTP(S)"

        processor -> redis "Polls priority queue for jobs" "TCP"
        processor -> postgresql "Updates job status" "TCP"
        processor -> s3 "Downloads input, uploads output files" "HTTP(S)"
        processor -> llmdGateway "Dispatches inference requests (sync mode)" "HTTP(S)"
        processor -> llmdAsync "Dispatches inference requests (async mode)" "Go library"

        gc -> postgresql "Scans and deletes expired records" "TCP"
        gc -> s3 "Deletes expired files" "HTTP(S)"
        gc -> redis "Re-enqueues stuck jobs" "TCP"
        gc -> k8sApi "Watches processor pods for orphan detection" "HTTPS/6443"

        # Observability
        apiserver -> otelCollector "Exports traces" "OTLP/gRPC"
        processor -> otelCollector "Exports traces" "OTLP/gRPC"
        prometheus -> apiserver "Scrapes metrics" "HTTP/8081"
        prometheus -> processor "Scrapes metrics" "HTTP/9090"
        prometheus -> gc "Scrapes metrics" "HTTP/9091"
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
            element "External" {
                background #999999
                color #ffffff
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
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Deployment" {
                shape RoundedBox
            }
            element "StatefulSet" {
                shape Hexagon
            }
        }
    }
}

workspace {
    model {
        client = person "API Client" "Submits batch inference jobs via OpenAI-compatible API"
        operator = person "Platform Operator" "Deploys and monitors batch gateway"

        batchGateway = softwareSystem "Batch Gateway" "OpenAI-compatible batch inference API gateway for large-scale LLM batch processing" {
            apiserver = container "API Server" "REST API for batch job submission, tracking, and file management. OpenAI-compatible /v1/batches and /v1/files endpoints." "Go HTTP Service" "Port 8000/TCP"
            processor = container "Processor" "Pulls batch jobs from priority queue, builds per-model execution plans, dispatches inference requests with AIMD concurrency control." "Go Background Worker (StatefulSet)" "Port 9090/TCP (obs)"
            gc = container "Garbage Collector" "Periodically scans for expired items, deletes them, and reconciles orphaned jobs from crashed processors." "Go Background Worker" "Port 9091/TCP (metrics)"
        }

        kuadrant = softwareSystem "Kuadrant/Authorino" "API gateway providing authentication and authorization" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for batch job and file metadata" "External"
        redis = softwareSystem "Redis/Valkey" "In-memory data store for priority queue and event channels" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for batch input/output files" "External"
        llmdGateway = softwareSystem "llm-d Inference Gateway" "Downstream inference serving platform" "Internal Platform"
        llmdAsync = softwareSystem "llm-d-async" "Async dispatch via Redis-backed inference queues" "Internal Platform"
        k8sApi = softwareSystem "Kubernetes API" "Cluster control plane for pod lifecycle management" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning and rotation" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        grafana = softwareSystem "Grafana" "Metrics visualization dashboards" "External"

        # External relationships
        client -> kuadrant "Submits batch jobs" "HTTPS/443"
        kuadrant -> batchGateway "Forwards authenticated requests with tenant header" "HTTP(S)/8000"

        # Internal component relationships
        apiserver -> postgresql "Stores batch job and file metadata" "TCP (pgx)"
        apiserver -> redis "Enqueues batch jobs" "TCP (go-redis)"
        apiserver -> s3 "Stores input/output files" "HTTP(S) (AWS SDK)"

        processor -> redis "Polls for queued jobs" "TCP (go-redis)"
        processor -> postgresql "Reads metadata, updates status" "TCP (pgx)"
        processor -> s3 "Downloads input, uploads output" "HTTP(S) (AWS SDK)"
        processor -> llmdGateway "Dispatches inference requests (sync)" "HTTP(S) with AIMD"
        processor -> llmdAsync "Dispatches inference requests (async)" "In-process library"

        gc -> postgresql "Scans and deletes expired items" "TCP (pgx)"
        gc -> redis "Event GC and reconciliation" "TCP (go-redis)"
        gc -> s3 "Deletes expired files" "HTTP(S) (AWS SDK)"
        gc -> k8sApi "Watches processor pods for orphan detection" "HTTPS/6443"

        # Observability
        apiserver -> otelCollector "Exports traces" "OTLP/gRPC"
        processor -> otelCollector "Exports traces" "OTLP/gRPC"
        gc -> otelCollector "Exports traces" "OTLP/gRPC"

        # Optional integrations
        certManager -> batchGateway "Provisions TLS certificates"
        prometheus -> batchGateway "Scrapes metrics" "HTTP/8081,9090,9091"
        grafana -> prometheus "Queries metrics"

        operator -> grafana "Monitors batch gateway"
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
            element "Person" {
                shape person
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
        }
    }
}

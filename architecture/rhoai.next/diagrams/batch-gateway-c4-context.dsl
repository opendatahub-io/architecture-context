workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits batch inference jobs via OpenAI-compatible API"

        batchGateway = softwareSystem "Batch Gateway" "OpenAI-compatible batch inference API gateway for llm-d" {
            apiserver = container "batch-gateway-apiserver" "OpenAI-compatible REST API for batch and file CRUD operations, enqueues jobs to priority queue" "Go HTTP Service"
            processor = container "batch-gateway-processor" "Dequeues batch jobs, orchestrates multi-model concurrent inference execution, manages job lifecycle" "Go Worker Service"
            gc = container "batch-gateway-gc" "Periodically scans for and removes expired batch/file records and associated files" "Go Background Service"
        }

        postgresql = softwareSystem "PostgreSQL" "Batch and file metadata storage (primary backend)" "External"
        redis = softwareSystem "Redis / Valkey" "Priority queue, event channels, status store; optional metadata backend" "External"
        s3 = softwareSystem "S3-Compatible Storage" "File content storage for input/output/error JSONL files (MinIO or AWS S3)" "External"
        inferenceGW = softwareSystem "LLM Inference Gateway" "llm-d / vLLM inference backend for model completion requests" "Internal Platform"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning for apiserver" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection (OTLP/gRPC)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping via ServiceMonitor/PodMonitor" "External"
        grafana = softwareSystem "Grafana" "Pre-built dashboards for apiserver and processor metrics" "External"
        gatewayAPI = softwareSystem "Gateway API" "Optional external ingress routing via HTTPRoute" "External"

        # User interactions
        user -> batchGateway "Submits batch jobs, uploads files, checks status" "HTTP/HTTPS"

        # Internal container interactions
        apiserver -> redis "Enqueue jobs, publish cancel events" "TCP/6379"
        apiserver -> postgresql "Store/query batch and file metadata" "TCP/5432"
        apiserver -> s3 "Store/retrieve file content" "HTTPS/443"
        processor -> redis "Dequeue jobs, receive cancel events, update progress" "TCP/6379"
        processor -> postgresql "Update batch status, query metadata" "TCP/5432"
        processor -> s3 "Download input, upload output/error files" "HTTPS/443"
        processor -> inferenceGW "Execute inference requests" "HTTP/HTTPS, Bearer Token"
        gc -> postgresql "Query and delete expired records" "TCP/5432"
        gc -> redis "Query and delete expired records" "TCP/6379"
        gc -> s3 "Delete expired file content" "HTTPS/443"

        # External integrations
        batchGateway -> otel "Export distributed traces" "OTLP/gRPC/4317"
        prometheus -> batchGateway "Scrape metrics" "HTTP/8081"
        grafana -> prometheus "Query metrics" "HTTP"
        certManager -> batchGateway "Provision TLS certificates" "CRD"
        gatewayAPI -> batchGateway "Route external traffic to apiserver" "HTTPRoute"
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
        }
    }
}

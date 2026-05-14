workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits batch inference jobs via OpenAI-compatible API"
        platformAdmin = person "Platform Admin" "Deploys and configures batch-gateway via Helm"

        batchGateway = softwareSystem "Batch Gateway" "OpenAI-compatible batch inference API gateway for llm-d" {
            apiserver = container "batch-gateway-apiserver" "OpenAI-compatible REST API for batch and file CRUD operations. Validates input, stores metadata, enqueues jobs to priority queue." "Go HTTP Service"
            processor = container "batch-gateway-processor" "Dequeues batch jobs from priority queue, orchestrates concurrent inference execution against LLM backends, manages job lifecycle with crash recovery." "Go Worker Service"
            gc = container "batch-gateway-gc" "Periodically scans for and removes expired batch/file records and their associated file content." "Go Background Service"
        }

        postgresql = softwareSystem "PostgreSQL" "Primary metadata storage for batch and file records (batch_items, file_items tables)" "External"
        redis = softwareSystem "Redis / Valkey" "Priority queue (sorted sets), event channels (cancel via BLMPop), status store, optional metadata backend" "External"
        s3 = softwareSystem "S3-Compatible Storage" "File content storage for input/output/error JSONL files (MinIO, AWS S3)" "External"
        inferenceGateway = softwareSystem "LLM Inference Gateway" "llm-d or vLLM inference backend for model completions" "Internal Platform"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning for apiserver HTTPS" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection via OTLP/gRPC" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping via ServiceMonitor and PodMonitor" "External"
        grafana = softwareSystem "Grafana" "Pre-built dashboards for apiserver and processor metrics" "External"
        gatewayAPI = softwareSystem "Gateway API" "Optional external ingress routing via HTTPRoute" "External"

        # User interactions
        user -> batchGateway "Submits batch jobs, uploads files, checks status" "HTTP/HTTPS REST API"
        platformAdmin -> batchGateway "Deploys and configures" "Helm chart"

        # Container-level interactions
        user -> apiserver "POST /v1/files, POST /v1/batches, GET /v1/batches/{id}" "HTTP/HTTPS with Tenant Header"
        apiserver -> postgresql "CRUD batch and file metadata" "TCP/5432 TLS"
        apiserver -> redis "Enqueue jobs, publish cancel events" "TCP/6379 TLS/mTLS"
        apiserver -> s3 "Upload/download file content" "HTTPS/443"

        processor -> redis "Dequeue jobs, receive cancel events, update progress" "TCP/6379 TLS/mTLS"
        processor -> postgresql "Read metadata, update batch status" "TCP/5432 TLS"
        processor -> s3 "Download input, upload output/error files" "HTTPS/443"
        processor -> inferenceGateway "Forward inference requests with concurrency control" "HTTP/HTTPS Bearer Token"

        gc -> postgresql "Query and delete expired records" "TCP/5432 TLS"
        gc -> redis "Query and delete expired records" "TCP/6379 TLS"
        gc -> s3 "Delete expired file content" "HTTPS/443"

        # Observability
        batchGateway -> otelCollector "Export distributed traces" "OTLP/gRPC 4317"
        prometheus -> batchGateway "Scrape metrics" "HTTP/8081"
        grafana -> prometheus "Query metrics for dashboards"

        # Infrastructure
        certManager -> batchGateway "Provision TLS certificates" "Certificate CRD"
        gatewayAPI -> apiserver "Route external traffic" "HTTPRoute CRD"
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

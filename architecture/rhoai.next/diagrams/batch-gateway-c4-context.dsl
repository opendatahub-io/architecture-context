workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits batch inference jobs via OpenAI-compatible API"
        admin = person "Platform Admin" "Deploys and configures batch-gateway via Helm"

        batchGateway = softwareSystem "Batch Gateway" "OpenAI-compatible batch inference API gateway for llm-d" {
            apiserver = container "batch-gateway-apiserver" "OpenAI-compatible REST API for batch and file CRUD operations. Enqueues jobs to priority queue." "Go HTTP Service"
            processor = container "batch-gateway-processor" "Dequeues batch jobs, orchestrates multi-model concurrent inference execution, manages job lifecycle." "Go Worker Service"
            gc = container "batch-gateway-gc" "Periodically scans for and removes expired batch/file records and associated files." "Go Background Service"
        }

        postgresql = softwareSystem "PostgreSQL" "Primary metadata store for batch and file records (batch_items, file_items tables)" "External"
        redis = softwareSystem "Redis / Valkey" "Priority queue (sorted sets), event channels (BLMPop), status store, optional metadata backend" "External"
        s3 = softwareSystem "S3-Compatible Storage" "File content storage for batch input/output/error JSONL files (MinIO, AWS S3)" "External"
        inferenceGW = softwareSystem "LLM Inference Gateway" "llm-d / vLLM inference backends for model completion" "Internal Platform"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for external ingress routing via HTTPRoute" "External"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning and rotation" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection via OTLP/gRPC" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping via ServiceMonitor and PodMonitor" "External"
        grafana = softwareSystem "Grafana" "Pre-built dashboards for apiserver and processor observability" "External"

        # User interactions
        user -> batchGateway "Submits batch jobs, uploads files, queries status" "HTTP/HTTPS, Tenant Header"
        admin -> batchGateway "Deploys and configures via Helm chart" "kubectl/helm"

        # System context relationships
        batchGateway -> postgresql "Stores/queries batch and file metadata" "TCP/5432, TLS configurable"
        batchGateway -> redis "Priority queue, events, status, optional metadata" "TCP/6379, TLS/mTLS configurable"
        batchGateway -> s3 "Stores/retrieves batch input/output/error files" "HTTPS/443"
        batchGateway -> inferenceGW "Forwards inference requests for batch processing" "HTTP/HTTPS, Bearer token"
        gatewayAPI -> batchGateway "Routes external traffic to /v1/batches and /v1/files" "HTTPRoute"
        certManager -> batchGateway "Provisions TLS certificates for apiserver" "Certificate CRD"
        batchGateway -> otel "Exports distributed traces" "OTLP/gRPC 4317"
        prometheus -> batchGateway "Scrapes metrics from apiserver and processor" "HTTP/8081"
        grafana -> batchGateway "Displays pre-built dashboards" "ConfigMap"

        # Container-level relationships
        user -> apiserver "POST /v1/batches, /v1/files" "HTTP/HTTPS"
        apiserver -> postgresql "Batch/file metadata CRUD" "pgx v5, TCP/5432"
        apiserver -> redis "Enqueue jobs, publish cancel events" "go-redis v9, TCP/6379"
        apiserver -> s3 "Upload/download file content" "AWS SDK v2, HTTPS/443"

        processor -> redis "Dequeue jobs, receive cancel events, update progress" "go-redis v9, TCP/6379"
        processor -> postgresql "Update batch status" "pgx v5, TCP/5432"
        processor -> s3 "Download input, upload output/error files" "AWS SDK v2, HTTPS/443"
        processor -> inferenceGW "Execute inference requests" "HTTP/HTTPS, Bearer token"

        gc -> postgresql "Query and delete expired records" "pgx v5, TCP/5432"
        gc -> s3 "Delete expired file content" "AWS SDK v2, HTTPS/443"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

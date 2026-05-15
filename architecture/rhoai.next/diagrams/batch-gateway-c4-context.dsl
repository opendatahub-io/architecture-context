workspace {
    model {
        # Actors
        dataScientist = person "Data Scientist / ML Engineer" "Submits batch inference jobs with up to 50,000 requests per batch"
        sre = person "SRE / Platform Admin" "Monitors batch processing health and performance"

        # Primary System
        batchGateway = softwareSystem "Batch Gateway" "OpenAI-compatible batch inference gateway for processing large-scale batch jobs in Kubernetes" {
            apiserver = container "API Server" "Handles REST requests for /v1/batches and /v1/files endpoints. Enforces tenant isolation via X-MaaS-Username header. Serves health, readiness, and metrics on observability port." "Go HTTP Service" "Port 8000 (API), 8081 (obs)"
            processor = container "Batch Processor" "Queue-driven worker that dequeues batch jobs, pre-processes input files into per-model execution plans, dispatches inference requests with concurrency control, and uploads results. Supports crash recovery." "Go Worker Service" "Port 9090 (metrics)"
            gc = container "Garbage Collector" "Periodic background service that scans for expired batch jobs and files, removes them from database and file storage. Single replica to avoid delete races." "Go Background Service" "No ports"
        }

        # External Dependencies
        postgresql = softwareSystem "PostgreSQL" "Batch job and file metadata storage with tenant-scoped queries" "External"
        redis = softwareSystem "Redis / Valkey" "Priority queue (sorted set by SLO), event channels, progress status, optional metadata storage" "External"
        s3 = softwareSystem "S3-compatible Storage" "Batch input/output file content storage (JSONL files up to 200 MB)" "External"
        inferenceGW = softwareSystem "Inference Gateway (llm-d / vLLM)" "Downstream inference endpoint for individual request dispatch from batch jobs" "Internal Platform"
        kuadrant = softwareSystem "Kuadrant / Authorino" "Authentication and authorization enforcement at gateway layer via Envoy ext_authz" "Internal Platform"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for external ingress routing via HTTPRoute" "Internal Platform"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate provisioning for API server" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping via ServiceMonitor (apiserver) and PodMonitor (processor)" "Internal Platform"
        grafana = softwareSystem "Grafana" "Dashboard visualization via labeled ConfigMap sidecar loading" "Internal Platform"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry distributed tracing collection" "Internal Platform"

        # Relationships - Actors to System
        dataScientist -> batchGateway "Submits batch jobs, uploads input files, retrieves results" "HTTPS/443 via Gateway"
        sre -> prometheus "Monitors batch processing metrics and alerts" "HTTPS"
        sre -> grafana "Views batch gateway dashboards" "HTTPS"

        # Relationships - Internal containers
        apiserver -> postgresql "CRUD batch/file metadata" "TCP/5432 PostgreSQL"
        apiserver -> redis "Enqueue jobs, publish events" "TCP/6379 RESP"
        apiserver -> s3 "Store/retrieve file content" "HTTPS/443 AWS IAM"

        processor -> redis "Dequeue jobs, subscribe events, update progress" "TCP/6379 RESP"
        processor -> postgresql "Read/update batch metadata" "TCP/5432 PostgreSQL"
        processor -> s3 "Download input, upload output/error files" "HTTPS/443 AWS IAM"
        processor -> inferenceGW "Dispatch individual inference requests" "HTTP(S) Bearer/mTLS"

        gc -> postgresql "Query and delete expired records" "TCP/5432 PostgreSQL"
        gc -> redis "Query and delete expired records" "TCP/6379 RESP"
        gc -> s3 "Delete expired file content" "HTTPS/443 AWS IAM"

        # Relationships - External integrations
        kuadrant -> apiserver "Forwards authenticated requests with tenant header" "HTTP(S)/8000"
        dataScientist -> kuadrant "Authenticates via ext_authz" "HTTPS/443"
        gatewayAPI -> apiserver "Routes /v1/batches, /v1/files via HTTPRoute" "HTTP(S)/8000"
        certManager -> apiserver "Provisions TLS certificates" "Certificate CRD"
        prometheus -> apiserver "Scrapes metrics" "HTTP/8081 ServiceMonitor"
        prometheus -> processor "Scrapes metrics" "HTTP/9090 PodMonitor"
        apiserver -> otlpCollector "Exports traces" "gRPC/4317"
        processor -> otlpCollector "Exports traces" "gRPC/4317"
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
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

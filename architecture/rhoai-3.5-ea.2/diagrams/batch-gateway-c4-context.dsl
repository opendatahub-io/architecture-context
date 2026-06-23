workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Submits batch inference jobs via OpenAI-compatible API"
        sre = person "SRE / Platform Admin" "Monitors system health and manages deployment"

        batchGateway = softwareSystem "Batch Gateway" "OpenAI-compatible batch inference API gateway for llm-d, providing job submission, processing, and lifecycle management" {
            apiserver = container "API Server" "REST API server implementing OpenAI-compatible /v1/batches and /v1/files endpoints for job submission, tracking, and file management" "Go HTTP Service" "Port: 8000/TCP (API), 8081/TCP (observability)"
            processor = container "Batch Processor" "Dequeues batch jobs from priority queue, dispatches inference requests to downstream llm-d routers with AIMD adaptive concurrency control, and uploads results" "Go Worker Service" "Port: 9090/TCP (metrics)"
            gc = container "Garbage Collector" "Performs TTL-based cleanup of expired batches and files, reconciles orphaned non-terminal jobs via CAS updates" "Go Worker Service" "Port: 9091/TCP (metrics)"
        }

        kuadrant = softwareSystem "Kuadrant / Authorino" "External authentication and authorization gateway" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for ingress routing (HTTPRoute)" "External"

        postgresql = softwareSystem "PostgreSQL" "Persistent storage for batch and file metadata (batch_items, file_items)" "External"
        redis = softwareSystem "Redis / Valkey" "Priority queue, event channels, status cache, in-flight tracking" "External"
        s3 = softwareSystem "S3-Compatible Storage" "File blob storage for input and output files" "External"

        llmd = softwareSystem "llm-d Inference Endpoint" "Downstream LLM model serving for batch request dispatch" "Internal Platform"
        epp = softwareSystem "llm-d Inference Scheduler (EPP)" "Gateway API Inference Extension for request scheduling" "Internal Platform"

        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor and PodMonitor" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed trace collection (OTLP gRPC)" "External"
        grafana = softwareSystem "Grafana" "Dashboard visualization via sidecar ConfigMap" "External"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate provisioning" "External"

        # Relationships - Users
        datascientist -> kuadrant "Submits batch jobs and files" "HTTPS"
        kuadrant -> batchGateway "Forwards authenticated requests" "HTTP/8000"
        sre -> prometheus "Monitors metrics and alerts"
        sre -> grafana "Views dashboards"

        # Relationships - Internal
        apiserver -> postgresql "Stores batch and file metadata" "pgx/5432 TLS 1.2+"
        apiserver -> redis "Enqueues jobs, publishes events" "RESP/6379"
        apiserver -> s3 "Uploads/downloads files" "HTTPS/443 TLS 1.2+"

        processor -> redis "Dequeues jobs from priority queue" "RESP/6379"
        processor -> postgresql "Reads job metadata, updates status" "pgx/5432 TLS 1.2+"
        processor -> s3 "Downloads input, uploads output files" "HTTPS/443 TLS 1.2+"
        processor -> llmd "Dispatches inference requests" "HTTP(S) with AIMD concurrency"
        processor -> epp "Routes via Gateway API Inference Extension" "HTTP REST"

        gc -> postgresql "Queries and deletes expired items" "pgx/5432 TLS 1.2+"
        gc -> redis "Checks queue and in-flight for orphans" "RESP/6379"
        gc -> s3 "Deletes expired file blobs" "HTTPS/443 TLS 1.2+"

        # Relationships - Observability
        apiserver -> otel "Exports traces" "gRPC/4317 OTLP"
        batchGateway -> prometheus "Exposes metrics" "HTTP (8081, 9090, 9091)"
        batchGateway -> grafana "Provides dashboard JSON" "ConfigMap sidecar"

        # Relationships - Infrastructure
        batchGateway -> gatewayAPI "Optional ingress routing" "HTTPRoute CR"
        apiserver -> certManager "Optional TLS certificate" "Certificate CR"
    }

    views {
        systemContext batchGateway "SystemContext" {
            include *
            autoLayout
            description "System context diagram showing Batch Gateway in the RHOAI ecosystem"
        }

        container batchGateway "Containers" {
            include *
            autoLayout
            description "Container diagram showing the three Batch Gateway components and their interactions"
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
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

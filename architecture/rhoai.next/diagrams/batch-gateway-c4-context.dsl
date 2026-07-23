workspace {
    model {
        datascientist = person "Data Scientist / API Consumer" "Submits batch inference jobs via OpenAI-compatible API"
        platformadmin = person "Platform Admin" "Configures and monitors Batch Gateway deployment"

        batchGateway = softwareSystem "Batch Gateway" "High-performance batch inference job processing system with OpenAI-compatible API" {
            apiserver = container "API Server" "REST API implementing OpenAI-compatible /v1/batches and /v1/files endpoints. Multi-tenant with tenant ID from HTTP header." "Go HTTP Service" "Port: 8000/TCP"
            processor = container "Batch Processor" "Dequeues jobs from priority queue, dispatches inference requests with AIMD adaptive concurrency control, writes results." "Go Worker Service" "Port: 9090/TCP (metrics only)"
            gc = container "Garbage Collector" "Cleans up expired batches/files and recovers orphaned jobs from crashed processors via CAS-based reconciliation." "Go Background Service" "Port: 9091/TCP (metrics only)"
        }

        authGateway = softwareSystem "Kuadrant / Authorino" "External authentication gateway — API key, ServiceAccount token, or user token authentication with tenant identity injection" "External"
        llmdRouter = softwareSystem "llm-d Router" "Downstream inference gateway for batch request dispatch (per-model or global routing)" "Internal Platform"
        llmdAsync = softwareSystem "llm-d-async" "Optional async dispatch queue for metrics-driven flow control" "Internal Platform"
        gatewayAPI = softwareSystem "Gateway API" "Optional API exposure via HTTPRoute and Gateway API-compliant ingress" "External"

        postgresql = softwareSystem "PostgreSQL" "Batch and file metadata storage (pgx driver)" "External"
        redis = softwareSystem "Redis / Valkey" "Priority queue, event pub/sub, in-flight tracking, real-time status cache" "External"
        s3 = softwareSystem "S3-compatible Storage" "Input/output file storage with tenant-scoped paths" "External"

        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor and PodMonitor" "External"
        otel = softwareSystem "OpenTelemetry Collector" "OTLP gRPC trace collection" "External"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning" "External"
        grafana = softwareSystem "Grafana" "Dashboard visualization via auto-loaded ConfigMaps" "External"

        # User interactions
        datascientist -> authGateway "Submits batch jobs and uploads files" "HTTPS/443, TLS 1.2+"
        authGateway -> apiserver "Forwards requests with tenant identity" "HTTP(S)/8000"
        platformadmin -> grafana "Monitors dashboards"

        # API Server interactions
        apiserver -> postgresql "Stores/queries batch and file metadata" "pgx/5432, TLS configurable"
        apiserver -> redis "Enqueues jobs, publishes events" "go-redis/6379, TLS optional"
        apiserver -> s3 "Uploads/downloads input/output files" "HTTPS/443, AWS IAM"

        # Processor interactions
        processor -> redis "Dequeues jobs from priority queue" "go-redis/6379, TLS optional"
        processor -> postgresql "Updates batch status and metadata" "pgx/5432, TLS configurable"
        processor -> s3 "Downloads input, uploads output files" "HTTPS/443, AWS IAM"
        processor -> llmdRouter "Dispatches inference requests with AIMD concurrency" "HTTP(S), Bearer API key"
        processor -> llmdAsync "Optional async dispatch" "Queue protocol"

        # GC interactions
        gc -> postgresql "Queries and deletes expired records" "pgx/5432, TLS configurable"
        gc -> s3 "Deletes expired file content" "HTTPS/443, AWS IAM"
        gc -> redis "Cleans up stale queue/in-flight entries" "go-redis/6379, TLS optional"

        # Observability
        prometheus -> apiserver "Scrapes metrics" "HTTP/8081"
        prometheus -> processor "Scrapes metrics" "HTTP/9090"
        prometheus -> gc "Scrapes metrics" "HTTP/9091"
        apiserver -> otel "Exports traces" "gRPC/4317 OTLP"
        processor -> otel "Exports traces" "gRPC/4317 OTLP"

        # Infrastructure
        certManager -> apiserver "Provisions TLS certificates" "Certificate CRD"
        gatewayAPI -> apiserver "Routes external traffic" "HTTPRoute CRD"
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

workspace {
    model {
        user = person "API Client" "Submits batch inference jobs via OpenAI-compatible API"

        batchGateway = softwareSystem "llm-d-batch-gateway" "High-performance OpenAI-compatible batch inference gateway for processing large-scale batch jobs" {
            apiserver = container "batch-gateway-apiserver" "REST API server handling batch job submission, management, tracking, and file management" "Go HTTP Service" "Deployment"
            processor = container "batch-gateway-processor" "Pulls batch jobs from priority queue, dispatches inference requests to downstream gateways" "Go Background Worker" "StatefulSet"
            gc = container "batch-gateway-gc" "Periodically removes expired jobs and files, reconciles orphaned work from crashed processors" "Go Background Worker" "Deployment"
        }

        kuadrant = softwareSystem "Kuadrant / Authorino" "External API gateway for authentication and authorization" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for job and file metadata with row-level tenant isolation" "External"
        redis = softwareSystem "Redis / Valkey" "In-memory data store for priority queue, event channels, and status updates" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for input/output batch files" "External"
        inferenceGW = softwareSystem "llm-d Inference Gateway" "Downstream inference routing to LLM serving endpoints" "Internal Platform"
        llmdAsync = softwareSystem "llm-d-async" "Redis-backed async request/result queue protocol" "Internal Platform"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for pod lifecycle monitoring" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning" "External"

        user -> kuadrant "Submits batch jobs" "HTTPS"
        kuadrant -> apiserver "Forwards authenticated requests" "HTTP/HTTPS 8000/TCP"

        apiserver -> postgresql "Stores job and file metadata" "TCP"
        apiserver -> s3 "Stores input/output files" "HTTP/HTTPS"
        apiserver -> redis "Enqueues batch jobs" "TCP"

        processor -> redis "Dequeues batch jobs" "TCP"
        processor -> postgresql "Reads/updates job metadata" "TCP"
        processor -> s3 "Reads input, writes output files" "HTTP/HTTPS"
        processor -> inferenceGW "Dispatches inference requests" "HTTP/HTTPS"
        processor -> llmdAsync "Async dispatch mode" "Redis-backed"

        gc -> postgresql "Queries and deletes expired items" "TCP"
        gc -> s3 "Deletes expired files" "HTTP/HTTPS"
        gc -> k8sAPI "Watches processor pods for crash detection" "HTTPS 6443/TCP"
        gc -> redis "Re-enqueues orphaned jobs" "TCP"

        apiserver -> otel "Exports traces" "OTLP/gRPC"
        processor -> otel "Exports traces" "OTLP/gRPC"
        prometheus -> apiserver "Scrapes metrics" "HTTP 8081/TCP"
        prometheus -> processor "Scrapes metrics" "HTTP 9090/TCP"
        prometheus -> gc "Scrapes metrics" "HTTP 9091/TCP"
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
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

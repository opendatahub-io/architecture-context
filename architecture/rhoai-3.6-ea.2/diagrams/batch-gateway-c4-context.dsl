workspace {
    model {
        user = person "API Client" "Submits batch inference jobs via OpenAI-compatible API"

        batchGateway = softwareSystem "Batch Gateway" "OpenAI-compatible batch inference API gateway for large-scale batch job submission, processing, and lifecycle management" {
            apiserver = container "API Server" "REST API for /v1/batches and /v1/files endpoints; handles job submission, file management, tenant middleware" "Go HTTP Service" "Deployment"
            processor = container "Batch Processor" "Pulls jobs from priority queue, builds per-model execution plans, dispatches inference requests with AIMD adaptive concurrency" "Go Background Worker" "StatefulSet"
            gc = container "Garbage Collector" "Periodically removes expired jobs/files; orphan reconciler recovers stuck jobs after processor crashes" "Go Background Worker" "Deployment (single replica)"
        }

        kuadrant = softwareSystem "Kuadrant/Authorino" "Authentication and authorization gateway" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for batch and file metadata storage" "External"
        redis = softwareSystem "Redis/Valkey" "In-memory data store for priority queue, event channels, and status tracking" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for batch input/output files" "External"
        llmdRouter = softwareSystem "llm-d Inference Gateway" "Model serving endpoint for individual inference requests" "Internal Platform"
        llmdAsync = softwareSystem "llm-d-async" "Async inference request queuing via Redis" "Internal Platform"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for pod/statefulset lifecycle monitoring" "External"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor/PodMonitor" "External"

        # External relationships
        user -> kuadrant "Submits batch jobs" "HTTPS/443, API Key/Token"
        kuadrant -> batchGateway "Forwards authenticated requests" "HTTP(S)/8000, X-MaaS-Username header"

        # Internal container relationships
        apiserver -> postgresql "Stores batch/file metadata" "TCP"
        apiserver -> redis "Enqueues jobs, publishes events" "TCP, Optional TLS"
        apiserver -> s3 "Uploads/downloads files" "HTTP(S)"
        apiserver -> otel "Exports traces" "OTLP/gRPC"

        processor -> redis "Pulls jobs from priority queue" "TCP, Optional TLS"
        processor -> postgresql "Reads/updates job status" "TCP"
        processor -> s3 "Downloads input, uploads output" "HTTP(S)"
        processor -> llmdRouter "Dispatches inference requests (sync mode)" "HTTP(S), Optional mTLS"
        processor -> llmdAsync "Enqueues inference requests (async mode)" "Go library"
        processor -> otel "Exports traces" "OTLP/gRPC"

        gc -> postgresql "Queries/deletes expired records" "TCP"
        gc -> redis "Cleans up expired entries" "TCP, Optional TLS"
        gc -> k8sAPI "Watches pods/statefulsets for orphan reconciliation" "HTTPS/6443, SA Token"

        # Optional integrations
        certManager -> batchGateway "Provisions TLS certificates" "Kubernetes CRD"
        prometheus -> batchGateway "Scrapes metrics" "HTTP /metrics"
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
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

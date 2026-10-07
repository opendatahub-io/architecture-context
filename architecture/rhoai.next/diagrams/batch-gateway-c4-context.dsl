workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits batch inference jobs and retrieves results via OpenAI-compatible API"

        batchGateway = softwareSystem "Batch Gateway" "High-performance batch inference gateway providing OpenAI-compatible /v1/batches and /v1/files API for large-scale batch inference jobs" {
            apiserver = container "API Server" "REST API handling batch job submission, management, tracking, and file management. Deployed as Kubernetes Deployment with horizontal scaling" "Go HTTP Service" "Component"
            processor = container "Processor" "Pulls batch jobs from priority queue, dispatches inference requests to downstream gateways with AIMD adaptive concurrency control. Deployed as StatefulSet" "Go Background Worker" "Component"
            gc = container "Garbage Collector" "Periodically garbage-collects expired jobs and files, reconciles orphaned in-flight jobs from crashed processors. Single-replica Deployment" "Go Background Worker" "Component"
        }

        upstreamGateway = softwareSystem "Upstream Gateway" "Authentication and authorization enforcement (Kuadrant/Authorino). Injects tenant identity via X-MaaS-Username header" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for batch job and file metadata storage with tenant-scoped queries" "External"
        redis = softwareSystem "Redis/Valkey" "In-memory data store for priority queuing, event channels, and status updates" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for batch input/output files (JSONL)" "External"
        llmd = softwareSystem "llm-d Inference Gateway" "Downstream model serving gateway for inference request dispatch" "Internal Platform"
        llmdAsync = softwareSystem "llm-d-async" "Asynchronous inference dispatch via Redis queues" "Internal Platform"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for pod watching and orphan reconciliation" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend for observability" "External"

        user -> upstreamGateway "Submits batch jobs and retrieves results" "HTTPS"
        upstreamGateway -> batchGateway "Forwards authenticated requests with tenant identity" "HTTP/HTTPS + X-MaaS-Username"
        batchGateway -> postgresql "Stores and queries job/file metadata" "TCP"
        batchGateway -> redis "Manages priority queue and events" "TCP"
        batchGateway -> s3 "Stores and retrieves batch files" "HTTP/HTTPS"
        batchGateway -> llmd "Dispatches inference requests (sync mode)" "HTTP/HTTPS, Optional TLS/mTLS"
        batchGateway -> llmdAsync "Dispatches inference requests (async mode)" "Redis queues"
        batchGateway -> k8sAPI "Watches processor pods for crash recovery" "HTTPS/6443"
        batchGateway -> otel "Exports distributed traces" "OTLP/gRPC"

        apiserver -> postgresql "Create/query jobs and files" "TCP"
        apiserver -> redis "Enqueue jobs" "TCP"
        apiserver -> s3 "Upload/download files" "HTTP/HTTPS"
        processor -> redis "Dequeue jobs, publish events" "TCP"
        processor -> postgresql "Load job details, update status" "TCP"
        processor -> s3 "Read input, write output" "HTTP/HTTPS"
        processor -> llmd "Forward inference requests" "HTTP/HTTPS"
        gc -> postgresql "Scan expired records" "TCP"
        gc -> s3 "Delete expired files" "HTTP/HTTPS"
        gc -> redis "Clean expired events" "TCP"
        gc -> k8sAPI "Watch processor pods" "HTTPS/6443"
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
            element "Component" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

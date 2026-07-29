workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits large-scale batch inference jobs via OpenAI-compatible API"

        batchGateway = softwareSystem "llm-d Batch Gateway" "Multi-component batch inference processing system with OpenAI-compatible API" {
            apiserver = container "API Server" "REST API exposing /v1/batches and /v1/files endpoints for batch job submission, management, and file operations" "Go HTTP Service, Port 8000"
            processor = container "Batch Processor" "Dequeues jobs from priority queue, builds per-model execution plans, dispatches inference requests with AIMD concurrency control" "Go Background Worker"
            gc = container "Garbage Collector" "Periodically removes expired jobs/files and reconciles orphaned jobs after processor crashes" "Go Background Worker"
        }

        postgresql = softwareSystem "PostgreSQL" "Job and file metadata persistence with CAS-based status updates" "External"
        redis = softwareSystem "Redis / Valkey" "Priority queue, event channels, in-flight tracking, ephemeral status" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Batch input/output file storage" "External"
        inferenceGateway = softwareSystem "llm-d Inference Gateway" "Downstream LLM inference endpoint (Router/EPP)" "Internal Platform"
        llmdAsync = softwareSystem "llm-d-async" "Optional async dispatch backend via Redis sorted sets" "Internal Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via scrape" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning" "External"
        gatewayAPI = softwareSystem "Gateway API" "Optional ingress routing via HTTPRoute" "External"

        # User interactions
        user -> batchGateway "Submits batch jobs and uploads files" "HTTP/8000, Tenant Header"

        # API Server connections
        apiserver -> postgresql "Persists job/file metadata" "TCP"
        apiserver -> redis "Enqueues jobs, publishes events" "TCP, Optional TLS"
        apiserver -> s3 "Stores/retrieves files" "HTTP/HTTPS"

        # Processor connections
        processor -> redis "Dequeues jobs, tracks in-flight" "TCP, Optional TLS"
        processor -> postgresql "Reads/updates job state (CAS)" "TCP"
        processor -> s3 "Downloads input, uploads output" "HTTP/HTTPS"
        processor -> inferenceGateway "Dispatches inference requests" "HTTP/HTTPS, Optional mTLS"
        processor -> llmdAsync "Async dispatch (optional)" "TCP via Redis"
        processor -> otelCollector "Exports traces" "OTLP/gRPC"

        # GC connections
        gc -> postgresql "Queries/deletes expired resources" "TCP"
        gc -> redis "Checks in-flight, reconciles orphans" "TCP, Optional TLS"
        gc -> s3 "Deletes physical files" "HTTP/HTTPS"

        # External integrations
        prometheus -> batchGateway "Scrapes /metrics endpoints" "HTTP"
        certManager -> batchGateway "Provisions TLS certificates" "Kubernetes API"
        gatewayAPI -> batchGateway "Routes external traffic" "HTTPRoute"
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

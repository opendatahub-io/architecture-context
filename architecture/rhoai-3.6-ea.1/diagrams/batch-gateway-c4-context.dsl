workspace {
    model {
        client = person "API Client" "Submits batch inference requests and retrieves results"

        batchGateway = softwareSystem "batch-gateway" "Asynchronous batch inference gateway for llm-d, providing OpenAI-compatible Batch API" {
            apiserver = container "API Server" "REST API for batch submission, file upload/download, status queries. Dual-mux design with TLS opt-in (min TLS 1.2, FIPS-compliant)." "Go HTTP Service" "Port 8000"
            processor = container "Processor" "Polls Redis for pending batches, fans out inference requests to llm-d gateway, aggregates results." "Go Background Worker"
            gc = container "Garbage Collector" "Periodically scans for expired batch jobs and files, removes metadata and file content." "Go Background Worker"
        }

        postgresql = softwareSystem "PostgreSQL" "Relational database for batch and file metadata" "External"
        redis = softwareSystem "Redis/Valkey" "Work exchange queue between API server and processor" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for input/output files" "External"
        llmd = softwareSystem "llm-d Inference Gateway" "Downstream inference service for model predictions" "Internal Platform"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        platformGW = softwareSystem "Platform Gateway" "Gateway API ingress with AuthN/AuthZ" "Internal Platform"

        # External relationships
        client -> platformGW "Submits batch requests" "HTTPS/443"
        platformGW -> batchGateway "Routes requests with auth passthrough" "HTTP(S)/8000"

        # Container relationships
        client -> apiserver "Creates batches, uploads/downloads files" "REST API via Platform Gateway"
        apiserver -> postgresql "Stores batch/file metadata" "TCP"
        apiserver -> redis "Enqueues pending batches" "TCP"
        apiserver -> s3 "Stores input/output files" "HTTP/HTTPS"

        redis -> processor "Delivers pending batch work" "TCP"
        processor -> postgresql "Reads batch details, updates status" "TCP"
        processor -> s3 "Downloads input, uploads output files" "HTTP/HTTPS"
        processor -> llmd "Fans out inference requests" "HTTP/HTTPS"

        gc -> postgresql "Queries expired records, deletes metadata" "TCP"
        gc -> s3 "Removes expired file content" "HTTP/HTTPS"

        apiserver -> otel "Exports traces" "OTLP/gRPC"
        processor -> otel "Exports traces" "OTLP/gRPC"
        gc -> otel "Exports traces" "OTLP/gRPC"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
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

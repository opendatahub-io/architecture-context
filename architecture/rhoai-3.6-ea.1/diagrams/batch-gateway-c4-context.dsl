workspace {
    model {
        client = person "API Client" "Submits batch inference jobs and retrieves results"

        batchGateway = softwareSystem "batch-gateway" "Asynchronous batch inference gateway for LLM workloads" {
            apiserver = container "batch-gateway-apiserver" "REST API server for batch job CRUD operations (create, list, get, delete). Optional TLS 1.2+ with FIPS cipher suites. No app-level auth." "Go HTTP Service"
            processor = container "batch-gateway-processor" "Polls for pending tasks, dispatches inference requests to llm-d gateways, writes results" "Go Background Worker"
            gc = container "batch-gateway-gc" "Periodically scans for expired batch jobs and removes them from database and storage" "Go Background Worker"
        }

        postgresql = softwareSystem "PostgreSQL" "Relational database for job state persistence" "Infrastructure"
        redis = softwareSystem "Redis/Valkey" "Async task queue via llm-d-async library" "Infrastructure"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for batch input/output files" "Infrastructure"
        llmd = softwareSystem "llm-d Inference Gateway" "LLM inference serving endpoint" "Internal RHOAI"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "Infrastructure"
        platform = softwareSystem "Platform Gateway/Service Mesh" "Provides authentication and authorization" "Infrastructure"

        client -> platform "Submits requests via" "HTTPS"
        platform -> batchGateway "Forwards authenticated requests" "HTTP/HTTPS"

        client -> apiserver "Creates/queries/deletes batch jobs" "REST API (HTTP/HTTPS)"
        apiserver -> postgresql "Stores/queries job metadata" "TCP (pgx)"
        apiserver -> s3 "Uploads input files" "HTTP/HTTPS (AWS SDK v2)"
        apiserver -> redis "Publishes async tasks" "TCP (go-redis)"
        apiserver -> otel "Exports trace spans" "OTLP/gRPC"

        processor -> redis "Consumes pending tasks" "TCP (go-redis)"
        processor -> llmd "Dispatches inference requests" "HTTP/HTTPS"
        processor -> s3 "Reads inputs, writes results" "HTTP/HTTPS (AWS SDK v2)"
        processor -> postgresql "Updates job state" "TCP (pgx)"
        processor -> otel "Exports trace spans" "OTLP/gRPC"

        gc -> postgresql "Scans for expired jobs" "TCP (pgx)"
        gc -> s3 "Removes expired files" "HTTP/HTTPS (AWS SDK v2)"
        gc -> otel "Exports trace spans" "OTLP/gRPC"
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
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
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

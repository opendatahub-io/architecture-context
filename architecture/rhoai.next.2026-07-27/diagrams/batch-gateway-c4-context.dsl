workspace {
    model {
        client = person "API Client" "Submits batch inference requests via OpenAI-compatible API"

        batchGateway = softwareSystem "Batch Gateway" "Batch inference gateway providing asynchronous batch job submission, processing, and lifecycle management" {
            apiserver = container "batch-gateway-apiserver" "Accepts batch inference requests, manages job lifecycle via REST API" "Go HTTP Service"
            processor = container "batch-gateway-processor" "Dequeues jobs from Redis, dispatches inference requests to model gateways" "Go Background Worker"
            gc = container "batch-gateway-gc" "Periodically removes expired batch jobs and files, optional orphan reconciliation" "Go Background Worker"
            metricsServer = container "Metrics Server" "Prometheus metrics, health, and readiness endpoints" "Go HTTP Service"
        }

        envoy = softwareSystem "Envoy ext_authz Sidecar" "External authentication proxy that validates requests and injects identity headers" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for persistent batch job state" "External"
        redis = softwareSystem "Redis/Valkey" "Message queue and key-value store for job coordination" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for batch input/output files" "External"
        llmd = softwareSystem "llm-d Inference Gateway" "Model serving gateway for inference request dispatch" "Internal Platform"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing and observability pipeline" "External"

        # External relationships
        client -> envoy "Submits batch requests" "HTTP/HTTPS"
        envoy -> apiserver "Forwards with identity headers" "HTTP"

        # API Server relationships
        apiserver -> postgresql "Stores job state" "TCP/pgx"
        apiserver -> redis "Enqueues batch jobs" "TCP/go-redis"
        apiserver -> s3 "Uploads input files" "HTTP/HTTPS/AWS SDK v2"

        # Processor relationships
        processor -> redis "Dequeues batch jobs" "TCP/go-redis"
        processor -> postgresql "Updates job state" "TCP/pgx"
        processor -> llmd "Dispatches inference requests" "HTTP/HTTPS"
        processor -> s3 "Stores output files" "HTTP/HTTPS/AWS SDK v2"

        # GC relationships
        gc -> postgresql "Scans and removes expired jobs" "TCP/pgx"
        gc -> s3 "Removes expired files" "HTTP/HTTPS/AWS SDK v2"
        gc -> redis "Orphan reconciliation (optional)" "TCP/go-redis"

        # Observability
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

workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Submits batch inference jobs via OpenAI-compatible API"
        platformAdmin = person "Platform Admin" "Deploys and configures Batch Gateway via Helm chart"

        batchGateway = softwareSystem "Batch Gateway" "High-performance batch inference job processing with OpenAI-compatible API (/v1/batches, /v1/files)" {
            apiserver = container "Apiserver" "REST API server for batch job submission, management, tracking, and file operations" "Go HTTP Service" "Port: 8000/TCP"
            processor = container "Processor" "Background worker: dequeues jobs, builds per-model execution plans, dispatches inference with AIMD concurrency" "Go Background Worker" "Port: 9090/TCP (metrics)"
            gc = container "Garbage Collector" "Singleton: garbage-collects expired jobs/files, reconciles orphaned jobs" "Go Background Worker" "Port: 9091/TCP (metrics)"
        }

        postgresql = softwareSystem "PostgreSQL" "Batch job and file metadata persistence (JSONB, CAS updates)" "External"
        redis = softwareSystem "Redis / Valkey" "Priority queue (ZSET), event channels (List), status store (String), in-flight tracking (Hash)" "External"
        s3 = softwareSystem "S3-compatible Storage" "Batch input/output/error file storage" "External"
        inferenceGateway = softwareSystem "llm-d Router / Inference Gateway" "Serves individual inference requests (chat/completions, embeddings)" "Internal Platform"
        kuadrant = softwareSystem "Kuadrant / Authorino" "Gateway-level authentication and authorization enforcement" "Internal Platform"
        gatewayAPI = softwareSystem "Gateway API (Kubernetes)" "Ingress routing via HTTPRoute for /v1/batches and /v1/files" "Internal Platform"
        gieObjective = softwareSystem "GIE InferenceObjective" "Per-model InferencePool routing in multi-pool deployments" "Internal Platform"
        llmdAsync = softwareSystem "llm-d-async" "Optional async dispatch mode for inference requests via Redis queue" "Internal Platform"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace export (Jaeger, Tempo, OTEL Collector)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping via ServiceMonitor/PodMonitor" "Internal Platform"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate provisioning for apiserver" "Internal Platform"

        # User interactions
        dataScientist -> batchGateway "Submits batch jobs, uploads files, checks status" "HTTPS/8000 via Gateway"
        platformAdmin -> batchGateway "Deploys and configures" "Helm chart"

        # System context relationships
        batchGateway -> postgresql "Stores/retrieves batch and file metadata" "pgx/5432"
        batchGateway -> redis "Priority queue, events, status tracking, in-flight monitoring" "RESP/6379"
        batchGateway -> s3 "Stores/retrieves batch input/output/error files" "HTTPS/443"
        batchGateway -> inferenceGateway "Sends individual inference requests for batch processing" "HTTP(S)/configurable"
        kuadrant -> batchGateway "Enforces AuthN/AuthZ before requests reach apiserver" "Gateway policy"
        gatewayAPI -> batchGateway "Routes external traffic to apiserver" "HTTPRoute"
        batchGateway -> otlpCollector "Exports OpenTelemetry traces" "gRPC/4317"
        prometheus -> batchGateway "Scrapes metrics from all three components" "HTTP/8081,9090,9091"
        certManager -> batchGateway "Provisions TLS certificates" "Certificate CR"

        # Container-level relationships
        dataScientist -> apiserver "POST /v1/batches, /v1/files" "HTTPS/8000"
        apiserver -> postgresql "INSERT/SELECT/UPDATE batch and file records" "pgx/5432"
        apiserver -> redis "ZADD priority queue, RPUSH cancel events" "RESP/6379"
        apiserver -> s3 "PutObject (upload), GetObject (download)" "HTTPS/443"

        processor -> redis "BZMPOP (dequeue jobs), BLMPOP (cancel events)" "RESP/6379"
        processor -> postgresql "SELECT job details, UPDATE status" "pgx/5432"
        processor -> s3 "GetObject (input), PutObject (output/error)" "HTTPS/443"
        processor -> inferenceGateway "POST /v1/chat/completions, /v1/embeddings" "HTTP(S)"

        gc -> postgresql "SELECT expired, DELETE records" "pgx/5432"
        gc -> redis "HGETALL inflight hash for orphan detection" "RESP/6379"
        gc -> s3 "DeleteObject (expired files)" "HTTPS/443"
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

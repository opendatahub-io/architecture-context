workspace {
    model {
        user = person "API Client / Data Scientist" "Submits OpenAI-compatible batch inference jobs"

        batchGateway = softwareSystem "batch-gateway" "OpenAI-compatible batch inference gateway for llm-d (/v1/files, /v1/batches)" {
            apiserver = container "batch-gateway-apiserver" "OpenAI Files and Batches REST API; tenant extraction from X-MaaS-Username; 8000/TCP API, 8081/TCP observability" "Go HTTP Service (Deployment)"
            processor = container "batch-gateway-processor" "Pulls jobs from PostgreSQL queue, builds per-model plans, dispatches inference (sync HTTP or async llm-d-async) with AIMD concurrency control" "Go Worker (StatefulSet)"
            gc = container "batch-gateway-gc" "Expires jobs/files; orphan reconciler recovers jobs from crashed processor replicas" "Go Worker (Deployment, 1 replica)"
        }

        platformGateway = softwareSystem "Platform Gateway" "Gateway API ingress (batch-route) with Kuadrant AuthPolicy / RateLimitPolicy (MaaS)" "Internal RHOAI"
        inferenceGateway = softwareSystem "llm-d inference gateway / EPP" "Internal batch-llm-route; SubjectAccessReview on inferencepools" "Internal RHOAI"
        llmdAsync = softwareSystem "llm-d-async" "Metrics-driven async batch dispatcher" "Internal RHOAI"
        postgres = softwareSystem "PostgreSQL" "Metadata, priority queue, events, checkpoints, leases" "External"
        objectStore = softwareSystem "S3-compatible storage" "Input/output file content (alt: filesystem/PVC)" "External"
        redis = softwareSystem "Redis / Valkey" "llm-d-async request/result queues" "External"
        k8sApi = softwareSystem "Kubernetes API" "StatefulSet / pod watch for orphan recovery" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Trace collection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping via ServiceMonitor / PodMonitor" "External"

        user -> platformGateway "Uploads files, creates batches" "HTTPS/443, Bearer token"
        platformGateway -> apiserver "Forwards with X-MaaS-Username tenant header" "HTTP or HTTPS/8000"
        apiserver -> postgres "Stores metadata, queue entries, pass-through headers" "TCP/5432"
        apiserver -> objectStore "Stores file content under t-sha256(tenant)" "HTTPS/443, SigV4"
        processor -> postgres "Dequeues jobs, leases, status, checkpoints" "TCP/5432"
        processor -> objectStore "Downloads input, uploads output/error files" "HTTPS/443, SigV4"
        processor -> inferenceGateway "Sends inference requests with forwarded user bearer (sync)" "HTTP/HTTPS, optional mTLS"
        processor -> redis "Pushes requests, reads per-replica results (async)" "TCP/6379"
        llmdAsync -> redis "Consumes request queues, writes results"
        llmdAsync -> inferenceGateway "Dispatches inference" "HTTP"
        gc -> postgres "Expires items, re-queues orphaned jobs" "TCP/5432"
        gc -> objectStore "Deletes expired files" "HTTPS/443"
        gc -> k8sApi "Watches processor StatefulSet, lists pods" "HTTPS/6443, SA token"
        apiserver -> otel "Exports traces" "OTLP/gRPC 4317 (insecure default)"
        processor -> otel "Exports traces" "OTLP/gRPC 4317"
        gc -> otel "Exports traces" "OTLP/gRPC 4317"
        prometheus -> apiserver "Scrapes /metrics" "HTTP/8081"
        prometheus -> processor "Scrapes /metrics" "HTTP/9090"
        prometheus -> gc "Scrapes /metrics" "HTTP/9091"
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
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
            }
        }
    }
}

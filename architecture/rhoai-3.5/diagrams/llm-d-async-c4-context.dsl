workspace {
    model {
        producer = person "Producer Client" "Submits batch inference requests (bulk summarization, classification, sentiment analysis)"
        consumer = person "Consumer Client" "Retrieves inference results from message queues"

        asyncProcessor = softwareSystem "llm-d-async" "Asynchronous dispatch processor that pulls batch inference requests from message queues and forwards them to the inference gateway with capacity-aware flow control" {
            server = container "Server (Runner)" "Main server process: health probes, metrics, worker pool lifecycle, signal handling" "Go Service"
            workerPool = container "Worker Pool" "Concurrent workers that dispatch requests through gates to the inference gateway" "Go Goroutines"
            gateFactory = container "Gate Factory" "Flow control system: composes Prometheus, Redis, local, and endpoint-scrape gates per queue" "Go Library (601 LOC)"
            mergePolicy = container "Merge Policy" "Multi-queue request selection: random-robin or tier-priority (6-level scheduler)" "Go Library"
            retryWorker = container "Retry Worker" "Exponential backoff retry via Redis sorted sets with cancellation tokens" "Go Worker"
            transformChain = container "Transform Chain" "Request/response transformation pipeline (GCS multipart, custom plugins)" "Go Library"
        }

        pipelineModule = softwareSystem "pipeline Module" "Flow interface, gate abstraction, worker pool configuration (importable Go module)" "Go Module"
        apiModule = softwareSystem "api Module" "Request/result message types, inference client interface, error categorization (importable Go module)" "Go Module"
        producerModule = softwareSystem "producer Module" "Client-side SDK for submitting/retrieving requests (importable Go module)" "Go Module"

        redis = softwareSystem "Redis / Valkey" "Message queue backend: Pub/Sub channels, sorted sets, result lists, gate budget, quota tracking, retry sets" "External"
        gcpPubSub = softwareSystem "GCP Pub/Sub" "Alternative message queue backend with subscription-based pull delivery" "External"
        gcpMonitoring = softwareSystem "GCP Cloud Monitoring" "Backlog metrics for Pub/Sub subscriptions (num_undelivered_messages)" "External"
        inferenceGateway = softwareSystem "llm-d-router" "Inference gateway that routes requests to model servers" "Internal llm-d"
        prometheus = softwareSystem "Prometheus" "Metrics server for dispatch gate PromQL queries (saturation, budget, custom)" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing export via OTLP gRPC" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Signal handling, optional metrics RBAC (SubjectAccessReview)" "External"
        epp = softwareSystem "llm-d-inference-scheduler (EPP)" "Provides flow control metrics (pool_saturation, queue_size) consumed via Prometheus" "Internal llm-d"
        vllm = softwareSystem "vLLM Model Servers" "Provides fallback metrics (num_requests_running, ready_pods) via Prometheus relabeling" "Internal"
        gmp = softwareSystem "Google Managed Prometheus" "GCP-hosted Prometheus with OAuth2 authentication" "External"

        # Relationships
        producer -> asyncProcessor "Submits batch inference requests" "Redis RESP / GCP gRPC"
        consumer -> asyncProcessor "Retrieves inference results" "Redis RESP"
        producer -> producerModule "Uses SDK to submit requests"

        asyncProcessor -> redis "Queue subscribe/publish, sorted set ops, gate budget, quota, retry" "RESP 6379/TCP, Optional TLS"
        asyncProcessor -> gcpPubSub "Subscribe requests, publish results" "gRPC 443/TCP, TLS, GCP workload identity"
        asyncProcessor -> gcpMonitoring "Query subscription backlog metrics" "gRPC 443/TCP, TLS"
        asyncProcessor -> inferenceGateway "Forward inference requests" "HTTP/1.1, Optional TLS 1.2+"
        asyncProcessor -> prometheus "PromQL queries for dispatch gates" "HTTP, configurable port"
        asyncProcessor -> otelCollector "Export distributed traces" "gRPC OTLP, Optional TLS"
        asyncProcessor -> k8sAPI "Signal handling, optional SubjectAccessReview" "HTTPS 443/TCP, mTLS"
        asyncProcessor -> gmp "PromQL queries with OAuth2" "HTTPS 443/TCP"

        epp -> prometheus "Publishes flow control metrics" "Prometheus scrape"
        vllm -> prometheus "Publishes model server metrics" "Prometheus scrape + relabeling"

        # Internal container relationships
        server -> workerPool "Manages lifecycle"
        workerPool -> gateFactory "Creates gates per queue config"
        workerPool -> mergePolicy "Selects requests from multiple queues"
        workerPool -> retryWorker "Sends failed requests for retry"
        workerPool -> transformChain "Transforms requests before dispatch"
    }

    views {
        systemContext asyncProcessor "SystemContext" {
            include *
            autoLayout
        }

        container asyncProcessor "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal llm-d" {
                background #4a90e2
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Go Module" {
                background #e1d5e7
                color #333333
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

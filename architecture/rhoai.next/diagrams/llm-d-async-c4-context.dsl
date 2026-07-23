workspace {
    model {
        user = person "ML Engineer / Data Scientist" "Submits batch inference requests for latency-insensitive workloads (bulk summarization, classification, sentiment analysis)"

        asyncProcessor = softwareSystem "llm-d-async (Async Processor)" "Asynchronous dispatch processor that pulls batch inference requests from a message queue, gates dispatch based on system capacity, and forwards them to an inference gateway" {
            runner = container "Runner" "Initializes queue backends, worker pools, gates, and health endpoints" "Go Service (pkg/server)"
            pipeline = container "Pipeline" "Orchestrates message consumption, merge policy, gating, and worker dispatch" "Go Module (pipeline/)"
            asyncWorker = container "Async Worker" "HTTP inference client with retry logic, request transforms, and cancellation" "Go Package (pkg/asyncworker)"
            flowControl = container "Flow Control" "Dispatch gating — Prometheus, Redis, local concurrency, tier-priority, composite gates" "Go Package (flowcontrol/)"
            apiModule = container "API Module" "Shared message types, error categories, cancellation interface (zero dependencies)" "Go Module (api/)"
            producerModule = container "Producer Module" "Client library for submitting requests and retrieving results via Redis sorted set" "Go Module (producer/)"
            healthServer = container "Health Server" "Liveness (/healthz) and readiness (/readyz) HTTP endpoints on port 8081" "Go Package (internal/health)"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint on port 9090" "Go Package (pkg/metrics)"
        }

        redis = softwareSystem "Redis/Valkey" "Message queue backend — sorted sets for priority queues, lists for results, keys for budgets and quotas" "External"
        gcpPubSub = softwareSystem "GCP Pub/Sub" "Alternative message queue backend for GCP environments" "External"
        gcpMonitoring = softwareSystem "GCP Cloud Monitoring" "Queue backlog metrics for GCP Pub/Sub mode" "External"
        inferenceGateway = softwareSystem "llm-d-router (Inference Gateway)" "Upstream inference backend — receives dispatched requests via HTTP POST" "Internal Platform"
        prometheus = softwareSystem "Prometheus / Thanos" "Metric source for capacity-based dispatch gating (saturation, budget, custom PromQL)" "Internal Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection via OTLP gRPC" "External"
        vllm = softwareSystem "vLLM Model Servers" "LLM model serving backends (metrics scraped indirectly via PodMonitor)" "Internal Platform"

        # Relationships
        user -> asyncProcessor "Submits batch inference requests via message queue"
        user -> producerModule "Uses producer client library to submit and retrieve results"

        asyncProcessor -> redis "Consumes/produces messages, manages budgets and quotas" "RESP 6379/TCP, Optional TLS"
        asyncProcessor -> gcpPubSub "Consumes/produces messages" "gRPC 443/TCP, TLS 1.2+, GCP IAM"
        asyncProcessor -> gcpMonitoring "Queries queue backlog metrics" "gRPC 443/TCP, TLS 1.2+, GCP IAM"
        asyncProcessor -> inferenceGateway "Dispatches inference requests" "HTTP/HTTPS POST, Optional mTLS"
        asyncProcessor -> prometheus "Queries dispatch gating metrics (PromQL)" "HTTP, Configurable"
        asyncProcessor -> otelCollector "Exports distributed traces" "OTLP gRPC 4317/TCP"

        inferenceGateway -> vllm "Routes requests to model servers"
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
            element "Software System" {
                background #438DD5
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
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

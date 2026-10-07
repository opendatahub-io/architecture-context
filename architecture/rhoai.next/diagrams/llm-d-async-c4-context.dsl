workspace {
    model {
        producer = person "Producer Client" "Submits async inference requests to the message queue"
        consumer = person "Consumer Client" "Retrieves inference results from the result queue"

        llmDAsync = softwareSystem "llm-d-async" "Asynchronous queue-based dispatch processor for batch inference workloads" {
            asyncProcessor = container "Async Processor" "Pulls requests from message queues, applies dispatch gates, forwards to inference gateway" "Go Service"
            apiModule = container "api" "Message wire formats (RedisRequest, PubSubRequest), inference client interfaces" "Go Library"
            pipelineModule = container "pipeline" "Flow abstractions, gate interfaces, merge policies" "Go Library"
            producerModule = container "producer" "Redis-based message producer library" "Go Library"
        }

        redis = softwareSystem "Redis / Valkey" "Message broker — sorted-set queues, pub/sub channels, retry scheduling, result publishing, quota state" "External"
        gcpPubSub = softwareSystem "GCP Pub/Sub" "Alternative message queue transport" "External"
        gcpMonitoring = softwareSystem "GCP Cloud Monitoring" "Queue backlog metric queries for Pub/Sub mode" "External"
        router = softwareSystem "llm-d-router" "Inference gateway — routes requests to model servers with flow control" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics server — capacity metric queries for dispatch-gate decisions" "Internal Platform"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server — metrics endpoint authentication via SubjectAccessReview" "Internal Platform"
        otlpCollector = softwareSystem "OTLP Collector" "Distributed trace collection — receives spans via gRPC" "Internal Platform"
        gaie = softwareSystem "Gateway API Inference Extension" "Flow control metric definitions shared with EPP for coordinated capacity gating" "Internal Platform"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages PodMonitor for metrics scraping and PrometheusRule for alerting" "Internal Platform"

        # External relationships
        producer -> llmDAsync "Enqueues async inference requests via message broker"
        consumer -> redis "Retrieves inference results from result queue"

        # Internal relationships
        asyncProcessor -> apiModule "Uses wire format types and client interfaces"
        asyncProcessor -> pipelineModule "Uses flow and gate abstractions"
        producer -> producerModule "Uses to enqueue messages"

        # System relationships
        llmDAsync -> redis "Poll requests, publish results, retry scheduling, quota state" "Redis/6379 Optional TLS"
        llmDAsync -> gcpPubSub "Subscribe to request topics" "gRPC/443 TLS 1.2+"
        llmDAsync -> gcpMonitoring "Query queue backlog metrics" "gRPC/443 TLS 1.2+"
        llmDAsync -> router "Dispatch inference requests" "HTTP(S) Optional mTLS"
        llmDAsync -> prometheus "Query capacity metrics for dispatch gates" "HTTP/9090"
        llmDAsync -> k8sAPI "Metrics endpoint authentication" "HTTPS/6443 TLS 1.2+"
        llmDAsync -> otlpCollector "Export distributed traces" "gRPC/4317 Optional TLS"
        llmDAsync -> gaie "Import flow control metric definitions" "Go library"
        prometheusOperator -> llmDAsync "Scrape metrics via PodMonitor" "HTTP/9090"
    }

    views {
        systemContext llmDAsync "SystemContext" {
            include *
            autoLayout
        }

        container llmDAsync "Containers" {
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
        }
    }
}

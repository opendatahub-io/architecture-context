workspace {
    model {
        producer = person "External Producer" "Submits async inference requests to message queues"
        consumer = person "External Consumer" "Reads inference results from message queues"

        llmDAsync = softwareSystem "llm-d-async" "Asynchronous queue-based processor that pulls latency-insensitive inference requests from message brokers and dispatches them to inference gateways using capacity-aware gating" {
            asyncProcessor = container "Async Processor" "Pulls requests from queues, evaluates dispatch gates, forwards to inference gateway" "Go Service"
            healthServer = container "Health Server" "Kubernetes liveness and readiness probe endpoints" "Go HTTP Server" {
                tags "Health"
            }
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint with optional kube-rbac-proxy authentication" "Go HTTP Server" {
                tags "Metrics"
            }
            apiModule = container "api module" "Public request/result message types and Producer interface contracts" "Go Library"
            pipelineModule = container "pipeline module" "Flow, gate, merge policy, and worker pool abstractions" "Go Library"
            producerModule = container "producer module" "Producer-side SDK for submitting requests with durable delivery" "Go Library"
        }

        redis = softwareSystem "Redis / Valkey" "Message queue backend for request, retry, and result queues" "External" {
            tags "External"
        }
        gcpPubSub = softwareSystem "GCP Pub/Sub" "Alternative message queue backend" "External" {
            tags "External"
        }
        llmDRouter = softwareSystem "llm-d-router" "Inference gateway for dispatching inference requests to model servers" "Internal Platform" {
            tags "Internal"
        }
        prometheus = softwareSystem "Prometheus" "Monitoring system for capacity metric queries used by dispatch gates" "Internal Platform" {
            tags "Internal"
        }
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for metrics endpoint authentication" "Infrastructure" {
            tags "Infrastructure"
        }
        otlpCollector = softwareSystem "OTLP Collector" "Distributed tracing collection endpoint" "Infrastructure" {
            tags "Infrastructure"
        }
        epp = softwareSystem "gateway-api-inference-extension" "Flow control metric types for dispatch budget gates" "Internal Platform" {
            tags "Internal"
        }

        # External relationships
        producer -> redis "Submit requests" "Redis/6379 Optional TLS"
        producer -> gcpPubSub "Submit requests" "gRPC/443 TLS"
        consumer -> redis "Read results" "Redis/6379 Optional TLS"

        # Async processor relationships
        asyncProcessor -> redis "Pull requests, write results, retry enqueue" "Redis/6379 Optional TLS"
        asyncProcessor -> gcpPubSub "Pull requests" "gRPC/443 TLS"
        asyncProcessor -> llmDRouter "Dispatch inference requests" "HTTP/HTTPS Optional TLS 1.2+ / mTLS"
        asyncProcessor -> prometheus "Query capacity metrics for dispatch gates" "HTTP"
        asyncProcessor -> k8sAPI "Metrics endpoint authentication" "HTTPS/6443 TLS 1.2+"
        asyncProcessor -> otlpCollector "Export traces" "gRPC Optional TLS"

        # Compile-time dependency
        asyncProcessor -> epp "Flow control metric types" "Go library (compile-time)"

        # Internal container relationships
        asyncProcessor -> healthServer "Exposes" ""
        asyncProcessor -> metricsServer "Exposes" ""
        producerModule -> apiModule "Uses types from" ""
        asyncProcessor -> pipelineModule "Implements interfaces from" ""
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
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Health" {
                background #82b366
            }
            element "Metrics" {
                background #82b366
            }
        }
    }
}

workspace {
    model {
        producer = person "Request Producer" "Publishes async inference requests to message broker"
        sre = person "SRE / Platform Engineer" "Monitors health and metrics"

        llmDAsync = softwareSystem "llm-d-async" "Asynchronous inference processor that dequeues LLM requests from a message broker, dispatches them to model-serving backends, and returns results" {
            processor = container "async-processor" "Long-lived Go process with configurable worker pools and pluggable transport backends" "Go (FIPS-enabled)"
            healthServer = container "Health Server" "Liveness (/healthz) and readiness (/readyz) probes on port 8081" "Go HTTP Server"
            metricsServer = container "Metrics Server" "Prometheus metrics with K8s-delegated auth on port 9090" "controller-runtime"
        }

        redis = softwareSystem "Redis" "Message broker for async request/result transport (Pub/Sub or Sorted Set modes)" "External"
        gcpPubSub = softwareSystem "GCP Pub/Sub" "Alternative cloud message broker for async inference transport" "External"
        inferenceGateway = softwareSystem "Inference Gateway (vLLM)" "Downstream model-serving endpoint for LLM inference" "Internal llm-d"
        prometheus = softwareSystem "Prometheus" "Metrics store queried for flow-control gate admission decisions" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Receives distributed traces via OTLP/gRPC" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster control plane for resource operations" "External"
        gatewayAPIExt = softwareSystem "Gateway API Inference Extension" "Runtime library for inference gateway integration" "Internal ODH"

        # Relationships
        producer -> llmDAsync "Publishes inference requests via" "Redis/GCP Pub/Sub"
        llmDAsync -> redis "Consumes requests, publishes results" "RESP/TCP:6379, Configurable TLS"
        llmDAsync -> gcpPubSub "Consumes requests, publishes results" "HTTPS/443, TLS 1.2+"
        llmDAsync -> inferenceGateway "Dispatches inference requests" "HTTP(S)/8000, TLS 1.2+ optional mTLS"
        llmDAsync -> prometheus "Queries metrics for flow-control gates" "HTTP/9090"
        llmDAsync -> otelCollector "Exports distributed traces" "OTLP/gRPC"
        llmDAsync -> kubernetesAPI "Resource operations" "HTTPS/6443, ServiceAccount"
        llmDAsync -> gatewayAPIExt "Uses runtime packages" "Go library"
        sre -> llmDAsync "Monitors health and metrics" "HTTP/8081, HTTP/9090"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Internal llm-d" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
        }
    }
}

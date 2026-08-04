workspace {
    model {
        requestProducer = person "Request Producer" "System or user submitting async inference requests via message queue"

        llmDAsync = softwareSystem "llm-d-async" "Asynchronous inference request processor that bridges message queues with model serving backends" {
            runner = container "Runner" "Manages worker pools, transport selection, flow control" "Go (controller-runtime)"
            asyncWorker = container "Async Worker" "Processes inference requests with configurable transforms" "Go HTTP Client"
            healthServer = container "Health Server" "Serves /healthz and /readyz probes" "Go HTTP Server" "Port 8081"
            metricsServer = container "Metrics Server" "Serves /metrics with K8s auth" "controller-runtime" "Port 9090"
            transportLayer = container "Transport Layer" "Pluggable message queue abstraction (pipeline.Flow)" "Go Interface"
        }

        redis = softwareSystem "Redis" "Message queue transport (Pub/Sub or Sorted Set mode)" "External Infrastructure"
        gcpPubSub = softwareSystem "GCP Pub/Sub" "Alternative cloud message queue transport" "External Infrastructure"
        modelServer = softwareSystem "Model Server" "ML inference serving backend (vLLM, etc.)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics server for flow control gate queries" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for auth and resource operations" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace collection endpoint" "External"
        gatewayAPIExt = softwareSystem "gateway-api-inference-extension" "Shared logging and inference extension utilities" "Internal Platform"

        requestProducer -> redis "Publishes inference requests" "TCP"
        requestProducer -> gcpPubSub "Publishes inference requests" "gRPC/TLS"

        llmDAsync -> redis "Consumes requests, writes results" "TCP"
        llmDAsync -> gcpPubSub "Consumes requests, writes results" "gRPC/TLS"
        llmDAsync -> modelServer "Forwards inference requests" "HTTP/HTTPS (TLS 1.2+, optional mTLS)"
        llmDAsync -> prometheus "Queries metrics for flow control" "HTTP/HTTPS"
        llmDAsync -> kubernetesAPI "Auth validation, resource operations" "HTTPS/6443"
        llmDAsync -> otlpCollector "Exports traces" "gRPC (otlptracegrpc)"
        llmDAsync -> gatewayAPIExt "Uses logging utilities" "Go library"
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
            element "External Infrastructure" {
                background #6c8ebf
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

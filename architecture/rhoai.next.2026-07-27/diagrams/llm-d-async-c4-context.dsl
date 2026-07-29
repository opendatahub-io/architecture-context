workspace {
    model {
        user = person "ML Engineer" "Submits async inference requests to LLM serving infrastructure"

        llmdAsync = softwareSystem "llm-d-async" "Async inference request processing framework with flow-control gating, multi-backend message queuing, and Prometheus-driven dispatch decisions" {
            mainProcess = container "Main Process" "Entry point, orchestrates pipeline and health server" "Go Binary"
            healthServer = container "Health Server" "Exposes /healthz and /readyz for Kubernetes probes" "Go HTTP Server"
            pipelineModule = container "Pipeline Module" "Gate-based flow control framework with Apply() → Continue/Refuse" "Go Sub-Module"
            dispatchGate = container "BinaryMetricDispatchGate" "Queries Prometheus for inference_pool_average_queue_size, binary capacity decisions" "Go Component"
            apiModule = container "API Module" "Core API types for async inference" "Go Sub-Module"
            producerModule = container "Producer Module" "Message producer implementations for Redis/Valkey and Pub/Sub" "Go Sub-Module"
        }

        vllmServer = softwareSystem "vLLM Model Server" "GPU-accelerated LLM inference serving, companion deployment" "External"

        prometheus = softwareSystem "Prometheus" "Metrics collection and query for inference pool queue depth" "External"
        gmp = softwareSystem "Google Managed Prometheus" "Alternative metrics source for GCP deployments" "External"
        redis = softwareSystem "Redis / Valkey" "Message queue backend using sorted sets" "External"
        pubsub = softwareSystem "Google Cloud Pub/Sub" "Alternative message queue backend" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        k8sApi = softwareSystem "Kubernetes API" "Cluster resource management" "External"
        gatewayExt = softwareSystem "Gateway API Inference Extension" "Inference pool metrics and runtime packages" "Internal Platform"

        # Relationships
        user -> llmdAsync "Submits async inference requests"
        llmdAsync -> prometheus "Queries inference_pool_average_queue_size" "HTTP(S)"
        llmdAsync -> gmp "Queries metrics (GCP alternative)" "HTTPS/OAuth2"
        llmdAsync -> redis "Enqueues inference requests" "RESP Protocol"
        llmdAsync -> pubsub "Publishes inference requests (alternative)" "gRPC/TLS"
        llmdAsync -> otel "Exports traces" "OTLP/gRPC"
        llmdAsync -> k8sApi "Watches resources" "HTTPS/6443"
        llmdAsync -> gatewayExt "Uses runtime packages" "Go Library"
        llmdAsync -> vllmServer "Companion deployment pattern"

        # Container relationships
        mainProcess -> pipelineModule "Uses for request processing"
        mainProcess -> healthServer "Starts health endpoints"
        pipelineModule -> dispatchGate "Applies gate decisions"
        dispatchGate -> prometheus "Queries queue depth metrics"
        dispatchGate -> gmp "Queries metrics (GCP)"
        producerModule -> redis "Writes to sorted sets"
        producerModule -> pubsub "Publishes messages"
        apiModule -> pipelineModule "Provides API types"
        apiModule -> producerModule "Provides API types"
    }

    views {
        systemContext llmdAsync "SystemContext" {
            include *
            autoLayout
        }

        container llmdAsync "Containers" {
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
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

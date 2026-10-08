workspace {
    model {
        dataEngineer = person "Data Engineer / ML Engineer" "Submits batch inference requests via producer SDK"

        asyncProcessor = softwareSystem "llm-d Async Processor" "Asynchronous queue-based dispatch processor for batch LLM inference" {
            processorBinary = container "async-processor" "Pulls requests from message queues, evaluates dispatch gates, forwards to inference gateway" "Go Binary"
            apiModule = container "api module" "Public request/result wire format types and interfaces" "Go Library"
            pipelineModule = container "pipeline module" "Flow, gate, merge policy, and worker pool abstractions" "Go Library"
            producerModule = container "producer module" "Client-side SDK for enqueueing requests and consuming results" "Go Library"
        }

        redis = softwareSystem "Redis / Valkey" "Message queue backend for request/result sorted sets and budget/quota storage" "External"
        gcpPubSub = softwareSystem "GCP Pub/Sub" "Alternative message queue backend" "External"
        llmdRouter = softwareSystem "llm-d-router" "Inference gateway that routes to model servers" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics server for saturation/budget dispatch gate queries" "External"
        otlpCollector = softwareSystem "OTLP Collector" "Receives distributed traces via OpenTelemetry" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for RBAC authentication" "External"
        gatewayAPIExt = softwareSystem "gateway-api-inference-extension" "Flow control types for dispatch gate implementations" "Internal Platform"

        dataEngineer -> asyncProcessor "Submits batch inference requests" "Producer SDK / Redis"
        asyncProcessor -> redis "Pulls/publishes messages, stores quotas" "Redis Protocol / 6379"
        asyncProcessor -> gcpPubSub "Pulls/publishes messages" "gRPC / 443"
        asyncProcessor -> llmdRouter "Dispatches inference requests" "HTTP/HTTPS / configurable"
        asyncProcessor -> prometheus "Queries saturation/budget metrics" "HTTP / 9090"
        asyncProcessor -> otlpCollector "Exports distributed traces" "gRPC / configurable"
        asyncProcessor -> k8sAPI "Metrics endpoint RBAC auth" "HTTPS / 6443"

        processorBinary -> apiModule "Uses wire format types"
        processorBinary -> pipelineModule "Uses flow/gate/merge abstractions"
        pipelineModule -> gatewayAPIExt "Uses flow control types" "Go import"
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

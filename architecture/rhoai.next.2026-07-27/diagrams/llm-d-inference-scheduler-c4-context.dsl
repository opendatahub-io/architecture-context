workspace {
    model {
        user = person "ML Platform User" "Sends inference requests to LLM models through Envoy gateway"

        llmDScheduler = softwareSystem "llm-d-inference-scheduler" "Pluggable Envoy ExtProc gRPC service and Kubernetes controller for intelligent LLM inference request routing, scheduling, and flow control" {
            epp = container "Endpoint Picker (EPP)" "Envoy external processing service with multi-stage request pipeline: parsing, request control, scheduling, and flow control" "Go gRPC Service"
            imrController = container "InferenceModelRewrite Controller" "Reconciles InferenceModelRewrite resources to maintain model rewrite rules in datastore" "Go Controller"
            ioController = container "InferenceObjective Controller" "Reconciles InferenceObjective resources to configure priority bands and flow control" "Go Controller"
            ipController = container "InferencePool Controller" "Reconciles InferencePool resources for pool-based autoscaling configuration" "Go Controller"
            podController = container "Pod Controller" "Reconciles Pod resources to track available model-serving endpoints" "Go Controller"
            datastore = container "Routing Datastore" "In-memory state of endpoints, models, objectives, and metrics for scheduling decisions" "Go In-Memory"
        }

        envoyProxy = softwareSystem "Envoy Proxy" "L7 proxy that intercepts inference requests and delegates routing to EPP via ExtProc" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Kubernetes control plane for resource management and controller watches" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Collects and exports distributed traces" "External"
        modelEndpoints = softwareSystem "Model-Serving Endpoints" "vLLM or other model servers hosting LLM inference workloads" "Internal RHOAI"
        gatewayAPIExt = softwareSystem "Gateway API Inference Extension" "Kubernetes Gateway API extension for inference workload routing" "Internal RHOAI"
        llmDKVCache = softwareSystem "llm-d-kv-cache" "KV cache management library for cache-aware scheduling" "Internal RHOAI"

        user -> envoyProxy "Sends inference requests" "HTTPS"
        envoyProxy -> epp "gRPC ExtProc callouts per request" "gRPC/Optional TLS"
        epp -> datastore "Queries endpoint state for scheduling"
        epp -> envoyProxy "Returns routing decision (target endpoint)" "gRPC"

        imrController -> k8sAPI "Watches InferenceModelRewrite CRs" "HTTPS/6443"
        ioController -> k8sAPI "Watches InferenceObjective CRs" "HTTPS/6443"
        ipController -> k8sAPI "Watches InferencePool CRs" "HTTPS/6443"
        podController -> k8sAPI "Watches Pod resources" "HTTPS/6443"

        imrController -> datastore "Updates model rewrite rules"
        ioController -> datastore "Updates priority band configuration"
        ipController -> datastore "Updates pool configuration"
        podController -> datastore "Updates endpoint inventory"

        epp -> otelCollector "Exports trace spans" "OTLP/gRPC"
        epp -> modelEndpoints "Scrapes endpoint metrics" "HTTP"
        epp -> gatewayAPIExt "Uses runtime packages" "Go library"
        epp -> llmDKVCache "Uses KV cache scoring" "Go library"

        envoyProxy -> modelEndpoints "Forwards inference requests to selected endpoint" "HTTP/gRPC"
    }

    views {
        systemContext llmDScheduler "SystemContext" {
            include *
            autoLayout
        }

        container llmDScheduler "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
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

workspace {
    model {
        user = person "ML Engineer / Platform Admin" "Deploys inference models and configures routing policies via CRDs"
        client = person "Inference Client" "Sends inference requests to LLM endpoints"

        llmDRouter = softwareSystem "llm-d-router" "LLM inference request router implementing Envoy ExtProc with plugin-driven scheduling, flow control, and OpenAI-compatible HTTP gateway" {
            epp = container "Endpoint Picker (EPP)" "gRPC ExtProc service with plugin framework for request parsing, flow control, scheduling, and data layer" "Go gRPC Service"
            coordinator = container "Coordinator Server" "HTTP gateway exposing OpenAI-compatible /v1/chat/completions and /v1/completions endpoints" "Go HTTP Service"
            imrController = container "InferenceModelRewrite Controller" "Reconciles InferenceModelRewrite CRDs for model name rewriting with weighted traffic distribution" "controller-runtime"
            ioController = container "InferenceObjective Controller" "Reconciles InferenceObjective CRDs for priority-based flow control" "controller-runtime"
            ipController = container "InferencePool Controller" "Reconciles InferencePool resources for pool-based configuration" "controller-runtime"
            podController = container "Pod Controller" "Reconciles Pod resources to populate endpoint datastore" "controller-runtime"
        }

        envoy = softwareSystem "Envoy Proxy" "L7 proxy with External Processing filter for per-request routing callouts" "External"
        kubernetes = softwareSystem "Kubernetes API Server" "Cluster control plane for CRD storage, watch, and RBAC" "External"
        gatewayAPIInfExt = softwareSystem "Gateway API Inference Extension" "Provides InferencePool CRD and runtime packages" "Internal RHOAI"
        llmDKVCache = softwareSystem "llm-d-kv-cache" "KV cache library for prefix cache state management" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection endpoint" "External"
        redis = softwareSystem "Redis" "In-memory data store for cache and state" "External"
        inferenceBackend = softwareSystem "Inference Backend" "Model server pods running LLM inference (e.g., vLLM)" "Internal RHOAI"

        // User interactions
        user -> llmDRouter "Configures routing via EndpointPickerConfig, InferenceModelRewrite, InferenceObjective CRDs"
        client -> envoy "Sends inference requests"
        client -> coordinator "Sends inference requests (direct HTTP)"

        // Envoy to EPP
        envoy -> epp "gRPC ExtProc callout per request" "gRPC / Optional TLS"
        epp -> envoy "Returns selected endpoint routing decision"

        // Coordinator
        coordinator -> inferenceBackend "Routes inference requests" "HTTP"

        // Controller interactions
        imrController -> kubernetes "Watch/reconcile InferenceModelRewrite" "HTTPS/6443"
        ioController -> kubernetes "Watch/reconcile InferenceObjective" "HTTPS/6443"
        ipController -> kubernetes "Watch/reconcile InferencePool" "HTTPS/6443"
        podController -> kubernetes "Watch/reconcile Pods" "HTTPS/6443"

        // External integrations
        epp -> otelCollector "Export traces" "OTLP/gRPC"
        epp -> redis "Cache and state" "Redis protocol"
        envoy -> inferenceBackend "Forward to selected inference endpoint" "HTTP/gRPC"

        // Library dependencies
        epp -> llmDKVCache "KV cache state for prefix cache scheduling" "Go library"
        ipController -> gatewayAPIInfExt "InferencePool CRD types and runtime packages" "Go library"
    }

    views {
        systemContext llmDRouter "SystemContext" {
            include *
            autoLayout
        }

        container llmDRouter "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}

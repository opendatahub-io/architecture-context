workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys models and sends inference requests"
        platformEngineer = person "Platform Engineer" "Configures InferencePools, objectives, and routing policies"

        llmdRouter = softwareSystem "llm-d Router" "Intelligent LLM inference routing engine with KV-cache-aware endpoint selection, disaggregated inference coordination, and flow control" {
            epp = container "Endpoint Picker (EPP)" "Evaluates requests against real-time signals (KV-cache, queue depth, priority) to select optimal model-serving endpoints" "Go Service (gRPC ext-proc)" {
                extProcServer = component "gRPC ext-proc Server" "Bidirectional stream with Envoy for request/response interception" "gRPC 9002/TCP TLS"
                pluginEngine = component "Plugin Engine" "Orchestrates filters, scorers, pickers, and profile handlers" "Go"
                dataLayer = component "Data Layer" "Scrapes Prometheus metrics, DCGM GPU metrics, ZMQ events" "Go"
                endpointDatastore = component "Endpoint Datastore" "In-memory store of endpoint states, metrics, and KV-cache info" "Go"
                crdReconciler = component "CRD Reconciler" "Watches InferencePool, Pod, InferenceObjective, InferenceModelRewrite" "controller-runtime"
                flowControl = component "Flow Control" "Priority-based queuing with fairness and ordering policies" "Go (feature-gated)"
                healthServer = component "Health Server" "gRPC health checks for K8s probes" "gRPC 9003/TCP"
                metricsServer = component "Metrics Server" "Prometheus metrics endpoint" "HTTP 9090/TCP"
            }

            sidecar = container "Disaggregation Sidecar (pd-sidecar)" "Per-pod HTTP proxy coordinating disaggregated P/D and E/P/D inference between prefill, decode, and encode workers" "Go Service (HTTP proxy 8000/TCP)"

            coordinator = container "Coordinator" "Central orchestrator for distributed E/P/D inference pipelines (upstream-only, not in RHOAI Konflux builds)" "Go Service (HTTP 8080/TCP)"
        }

        envoyProxy = softwareSystem "Envoy Proxy" "L7 proxy delegating routing decisions to EPP via ext-proc filter" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing API server, CRDs, RBAC" "External"
        gatewayAPI = softwareSystem "Gateway API / GIE" "Kubernetes Gateway API with Inference Extension providing InferencePool CRD and HTTPRoute" "External"
        istio = softwareSystem "Istio / kGateway" "Gateway controller providing Envoy data plane for Gateway API mode" "External"

        vllm = softwareSystem "vLLM Model Server" "High-performance LLM inference engine exposing Prometheus metrics and serving predictions" "Internal Platform"
        sglang = softwareSystem "SGLang Model Server" "Alternative LLM inference backend" "Internal Platform"
        dcgmExporter = softwareSystem "DCGM Exporter" "NVIDIA GPU utilization metrics exporter" "External"

        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing export" "External"
        redis = softwareSystem "Redis" "Optional external cache for KV-cache metadata" "External"

        inferenceGateway = softwareSystem "Inference Gateway" "Routes pipeline stages to appropriate InferencePools" "Internal Platform"
        renderingService = softwareSystem "Rendering Service" "Tokenizes prompts and extracts multimodal features" "Internal Platform"

        # Relationships - EPP
        dataScientist -> envoyProxy "Sends inference requests (HTTP)" "" ""
        platformEngineer -> kubernetes "Creates InferencePool, InferenceObjective, InferenceModelRewrite CRs" "" ""
        envoyProxy -> epp "gRPC ext-proc bidirectional stream" "gRPC/9002 TLS"
        epp -> envoyProxy "Returns routing decision (target pod header)" "gRPC/9002 TLS"
        envoyProxy -> vllm "Forwards routed inference request" "HTTP/8000"
        envoyProxy -> sglang "Forwards routed inference request" "HTTP/8000"

        epp -> kubernetes "Watches CRDs (InferencePool, Pod, InferenceObjective, InferenceModelRewrite)" "HTTPS/443 SA token"
        epp -> vllm "Scrapes Prometheus metrics (queue depth, KV-cache, running requests)" "HTTP configurable"
        epp -> sglang "Scrapes Prometheus metrics" "HTTP configurable"
        epp -> dcgmExporter "Scrapes GPU utilization metrics" "HTTP configurable"
        epp -> otelCollector "Exports distributed traces" "gRPC/4317"
        epp -> redis "Optional KV-cache metadata cache" "Redis/6379"
        prometheus -> epp "Scrapes EPP metrics" "HTTP/9090"

        # Relationships - Sidecar
        epp -> sidecar "Routes requests to decode pods (via Envoy)" "HTTP/8000"
        sidecar -> vllm "Forwards decode requests to local vLLM" "HTTP/8200"
        sidecar -> vllm "Routes prefill requests to remote prefill pods" "HTTP configurable"
        sidecar -> otelCollector "Exports distributed traces" "gRPC/4317"

        # Relationships - Coordinator
        dataScientist -> coordinator "Sends multimodal inference requests" "HTTP/8080"
        coordinator -> inferenceGateway "Dispatches encode/prefill/decode pipeline stages" "HTTP/80"
        coordinator -> renderingService "Tokenizes prompts and extracts features" "HTTP/8080"
    }

    views {
        systemContext llmdRouter "SystemContext" {
            include *
            autoLayout
        }

        container llmdRouter "Containers" {
            include *
            autoLayout
        }

        component epp "EPPComponents" {
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
            element "Internal Platform" {
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

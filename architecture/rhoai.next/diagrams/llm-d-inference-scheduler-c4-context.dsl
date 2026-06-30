workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys models and sends inference requests"
        platformAdmin = person "Platform Admin" "Configures InferencePool, objectives, and model rewrites"

        llmdRouter = softwareSystem "llm-d Router (Inference Scheduler)" "Intelligent LLM-aware request routing engine with prefill/decode disaggregation support" {
            epp = container "Endpoint Picker (EPP)" "Core routing engine implementing Envoy ext_proc protocol for intelligent request placement" "Go gRPC Service" {
                extProcServer = component "ext_proc Server" "Handles bidirectional gRPC streaming with Envoy" "gRPC/9002"
                pluginFramework = component "Plugin Framework" "Extensible scheduling with filters, scorers, pickers, profile handlers" "Go"
                dataLayer = component "Data Layer" "Manages endpoint metrics collection via polling, K8s notifications, ZMQ" "Go"
                poolController = component "InferencePool Controller" "Watches InferencePool CRDs" "controller-runtime"
                objectiveController = component "InferenceObjective Controller" "Watches InferenceObjective CRDs for priority config" "controller-runtime"
                rewriteController = component "InferenceModelRewrite Controller" "Watches model rewrite rules" "controller-runtime"
                podController = component "Pod Controller" "Tracks pod readiness and endpoint state" "controller-runtime"
                healthServer = component "Health Server" "gRPC health checks for liveness/readiness" "gRPC/9003"
                metricsEndpoint = component "Metrics Endpoint" "Prometheus metrics (40+ metrics)" "HTTP/9090"
            }

            pdSidecar = container "PD-Sidecar (Disaggregation Sidecar)" "Coordinates prefill/decode and E/P/D disaggregation alongside decode workers" "Go HTTP Reverse Proxy" {
                proxyServer = component "Reverse Proxy Server" "HTTP/HTTPS proxy on port 8000" "HTTP/8000"
                nixlConnector = component "NIXL v2 Connector" "KV transfer via NIXL (RDMA-capable)" "Go"
                sharedStorageConnector = component "Shared Storage Connector" "KV transfer via shared filesystem" "Go"
                sglangConnector = component "SGLang Connector" "KV transfer via SGLang protocol" "Go"
                mooncakeConnector = component "Mooncake Connector" "KV transfer via Mooncake protocol" "Go"
                ssrfValidator = component "SSRF Allowlist Validator" "Validates routing targets against InferencePool membership" "Go"
            }
        }

        envoyProxy = softwareSystem "Envoy Proxy" "L7 proxy that delegates routing decisions to EPP via ext_proc" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing API server, CRDs, RBAC" "External"
        vllm = softwareSystem "vLLM Model Servers" "LLM inference engine providing model serving, metrics, and KV-cache management" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for ingress (HTTPRoute, Gateway)" "External"
        gie = softwareSystem "Gateway API Inference Extension (GIE)" "Defines InferencePool CRD and Endpoint Picker Protocol" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing via OTLP" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management and mTLS" "External"

        # Relationships
        dataScientist -> llmdRouter "Sends inference requests via Gateway" "HTTPS/443"
        platformAdmin -> llmdRouter "Configures scheduling via CRDs" "kubectl"

        llmdRouter -> envoyProxy "Receives requests via ext_proc, returns routing decisions" "gRPC/9002 TLS"
        envoyProxy -> llmdRouter "Forwards requests via ext_proc filter" "gRPC/9002 TLS"
        envoyProxy -> vllm "Routes requests to selected model server" "HTTP/HTTPS"

        llmdRouter -> kubernetes "Watches CRDs, Pods; leader election" "HTTPS/443"
        llmdRouter -> vllm "Polls metrics, routes P/D requests" "HTTP/HTTPS"
        llmdRouter -> otelCollector "Exports distributed traces" "gRPC/4317"
        prometheus -> llmdRouter "Scrapes metrics" "HTTP/9090"

        llmdRouter -> gie "Uses InferencePool CRD definition" "CRD API"
        llmdRouter -> gatewayAPI "Referenced by HTTPRoute for ingress" "CRD API"
        llmdRouter -> istio "Optionally deployed with Istio gateway" "Service Mesh"
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

        component epp "EPP-Components" {
            include *
            autoLayout
        }

        component pdSidecar "Sidecar-Components" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Software System" {
                background #1168bd
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

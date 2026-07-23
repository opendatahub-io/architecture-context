workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and deploys LLM inference workloads"
        platform_admin = person "Platform Admin" "Configures InferencePools and routing policies"

        llmdRouter = softwareSystem "llm-d Router" "Intelligent routing engine for LLM inference traffic with load-aware, prefix-cache-aware endpoint selection and disaggregated serving" {
            epp = container "Endpoint Picker (EPP)" "Core routing intelligence; evaluates requests against model server state via plugin framework (filters, scorers, flow control)" "Go Service (controller-runtime + gRPC ext-proc)" {
                extProcServer = component "ext-proc Server" "Bidirectional gRPC stream for Envoy request/response interception" "gRPC/HTTP2 9002/TCP TLS"
                pluginFramework = component "Plugin Framework" "Scheduling plugins (filter, score, pick), flow control, data layer" "Go Plugin DAG"
                kvIndex = component "KV-Cache Block Index" "Prefix cache affinity scoring using block hashes" "In-memory (optional Redis)"
                metricsServer = component "Metrics Server" "Prometheus metrics endpoint" "HTTP 9090/TCP"
                healthServer = component "Health Server" "gRPC health checks" "gRPC 9003/TCP"
            }

            sidecar = container "PD-Sidecar" "Disaggregation sidecar for prefill/decode orchestration with KV-cache transfer coordination" "Go Service (HTTP reverse proxy)" {
                httpProxy = component "HTTP Reverse Proxy" "Intercepts inference requests, coordinates multi-stage E/P/D lifecycle" "HTTPS 8000/TCP TLS 1.2+"
                kvConnectors = component "KV Connectors" "NIXLv2, Shared Storage, SGLang, Mooncake, P2P Offloading" "Go interfaces"
                ssrfGuard = component "SSRF Protection" "InferencePool-based pod IP allowlist" "Go middleware"
            }

            coordinator = container "Coordinator" "Multimodal request orchestration with configurable pipeline (replace media, render, encode, prefill, decode)" "Go Service (HTTP pipeline)" {
                pipelineEngine = component "Pipeline Engine" "Sequential step execution with factory pattern and early exit" "Go pipeline"
                mediaReplacer = component "Media URL Replacer" "Downloads images with SSRF protection (dial-time IP checks)" "Go step"
            }
        }

        envoyProxy = softwareSystem "Envoy Proxy" "L7 data plane proxy that routes inference traffic; EPP provides routing decisions via ext-proc" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for L7 routing (Gateway, HTTPRoute, InferencePool backendRef)" "External"
        vllmServers = softwareSystem "vLLM Model Servers" "LLM model serving pods (prefill workers, decode workers, encoder workers)" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD watches, pod discovery, leader election" "External"
        dcgmExporter = softwareSystem "DCGM Exporter" "NVIDIA GPU metrics exporter for utilization-aware scheduling" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing aggregation" "External"

        inferencePoolCRD = softwareSystem "InferencePool CRD (GIE)" "Defines model server pool membership and label selectors" "Internal Platform"
        inferenceObjectiveCRD = softwareSystem "InferenceObjective CRD" "Request priority levels and scheduling goals per model use case" "Internal Platform"
        inferenceModelRewriteCRD = softwareSystem "InferenceModelRewrite CRD" "Model name rewriting rules for A/B testing and canary rollouts" "Internal Platform"

        // Relationships
        user -> envoyProxy "Sends inference requests via" "HTTPS/443"
        platform_admin -> inferencePoolCRD "Creates/configures" "kubectl"
        platform_admin -> inferenceObjectiveCRD "Defines priority policies" "kubectl"
        platform_admin -> inferenceModelRewriteCRD "Configures traffic splitting" "kubectl"

        envoyProxy -> epp "Sends ext-proc stream" "gRPC/9002 TLS"
        epp -> envoyProxy "Returns routing decisions" "gRPC/9002 TLS"
        envoyProxy -> vllmServers "Routes to selected endpoint" "HTTP/HTTPS"
        envoyProxy -> sidecar "Forwards disaggregated requests" "HTTPS/8000"

        epp -> k8sAPI "Watches CRDs and pods" "HTTPS/6443 SA token"
        epp -> vllmServers "Scrapes Prometheus metrics" "HTTP/HTTPS"
        epp -> dcgmExporter "Collects GPU utilization" "HTTP/HTTPS"

        sidecar -> vllmServers "Forwards prefill/decode/encode" "HTTP/HTTPS"

        user -> coordinator "Sends multimodal requests" "HTTP/8080"
        coordinator -> gatewayAPI "Routes E/P/D stages" "HTTP"

        llmdRouter -> otelCollector "Exports traces" "gRPC"
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

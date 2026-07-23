workspace {
    model {
        user = person "ML Engineer / Platform Admin" "Deploys inference services and configures routing policies"
        client = person "Inference Client" "Sends inference requests to deployed models"

        llmdRouter = softwareSystem "llm-d Router" "Intelligent LLM inference request router with KV-cache-aware scheduling, request prioritization, and disaggregated prefill/decode orchestration" {
            epp = container "Endpoint Picker (EPP)" "Intelligent routing engine implementing Envoy ext-proc protocol with pluggable Filter→Score→Pick scheduling pipeline" "Go Service (controller-runtime)" {
                extProcServer = component "ext-proc gRPC Server" "Bidirectional gRPC stream processing for Envoy request/response interception" "gRPC 9002/TCP TLS"
                schedulingEngine = component "Scheduling Engine" "Pluggable Filter→Score→Pick pipeline with named profiles" "Go"
                flowController = component "Flow Controller" "Priority-based queuing with actor model processor and eviction" "Go"
                dataLayer = component "Data Layer" "Topological sort-based data producer graph (Kahn's algorithm)" "Go"
                metricsCollector = component "Metrics Collector" "Scrapes vLLM/SGLang Prometheus metrics (KV cache, queue depth)" "HTTP"
                crdWatcher = component "CRD Watchers" "Watches InferencePool, InferenceObjective, InferenceModelRewrite" "controller-runtime"
            }
            pdSidecar = container "Disaggregation Sidecar (pd-sidecar)" "Orchestrates P/D and E/P/D disaggregated inference with pluggable KV connectors (NIXLv2, SGLang, Mooncake, shared-storage)" "Go HTTP Proxy (sidecar)"
        }

        envoy = softwareSystem "Envoy Proxy" "L7 proxy data plane with ext-proc filter for routing decision injection" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform hosting CRDs, Pods, and API server" "External"
        vllm = softwareSystem "vLLM / SGLang Model Servers" "LLM inference engines serving model predictions with KV cache metrics" "Internal Platform"
        istio = softwareSystem "Istio" "Service mesh providing mTLS and connection pooling (optional, Gateway mode)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing infrastructure" "External"
        gatewayAPI = softwareSystem "Gateway API Inference Extension" "InferencePool CRD and Endpoint Picker protocol definition" "External"

        # User interactions
        user -> llmdRouter "Configures InferencePool, InferenceObjective, InferenceModelRewrite CRDs" "kubectl / YAML"
        client -> envoy "Sends inference requests" "HTTP 8081/TCP"

        # System interactions
        envoy -> epp "ext-proc bidirectional stream for routing decisions" "gRPC 9002/TCP TLS 1.2+"
        envoy -> vllm "Forwards routed inference requests" "HTTP/gRPC 8000/TCP"
        envoy -> pdSidecar "Forwards P/D requests to sidecar" "HTTP/HTTPS 8000/TCP TLS"
        epp -> vllm "Scrapes Prometheus metrics (KV cache, queue depth)" "HTTP 8000/TCP"
        epp -> kubernetes "Watches CRDs, discovers Pods, leader election" "HTTPS 443/TCP"
        epp -> prometheus "Exposes EPP metrics" "HTTP 9090/TCP"
        epp -> otel "Exports distributed traces" "gRPC 4317/TCP TLS"
        epp -> gatewayAPI "Consumes InferencePool protocol" "Kubernetes API"
        pdSidecar -> vllm "Proxies decode, prefill, and encoder requests" "HTTP/HTTPS 8000-8001/TCP"
        llmdRouter -> istio "Uses for mTLS and connection pooling in Gateway mode" "DestinationRule"
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

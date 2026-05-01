workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and manages LLM inference workloads"
        application = person "Application / Client" "Sends inference requests to LLM models"

        llmdScheduler = softwareSystem "llm-d Inference Scheduler" "Intelligent inference request scheduler for LLM workloads via Envoy ext-proc" {
            epp = container "EPP (Endpoint Picker)" "Envoy ext-proc server — runs configurable filter/scorer/picker scheduling pipeline to select optimal model-serving pod" "Go gRPC Service" {
                extProcServer = component "gRPC ext-proc Server" "Receives ProcessingRequest from Envoy, returns routing decision" "gRPC H2, 9002/TCP"
                schedulingPipeline = component "Scheduling Pipeline" "Filters → Scorers → Pickers with plugin architecture" "Go"
                dataLayer = component "Data Layer" "Collects metrics, KV cache events, CRD state for scheduling decisions" "Go"
                metricsServer = component "Metrics Server" "Exposes Prometheus metrics (TTFT, TPOT, SLO violations)" "HTTP, 9090/TCP"
                healthServer = component "Health Server" "gRPC liveness and readiness checks" "gRPC, 9003/TCP"
            }
            pdSidecar = container "PD Sidecar Proxy" "Orchestrates disaggregated Prefill/Decode execution with pluggable KV transfer protocols (NIXL v2, shared storage, SGLang)" "Go HTTP Reverse Proxy"
            udsTokenizer = container "UDS Tokenizer" "Tokenizes prompts for prefix-cache-aware scoring" "Sidecar Container"
        }

        envoyGateway = softwareSystem "Envoy Gateway" "Data plane gateway with ext-proc filter for routing inference requests" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway and HTTPRoute CRDs for ingress" "External"
        gie = softwareSystem "Gateway API Inference Extension (GIE)" "Framework providing InferencePool, InferenceModel CRDs and ext-proc interfaces" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform — API server, RBAC, CRD watches" "External"
        vllm = softwareSystem "vLLM Model Servers" "LLM model serving engine exposing inference API and Prometheus metrics" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring via ServiceMonitor" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing export target (OTLP)" "External"
        llmdKVCache = softwareSystem "llm-d-kv-cache" "KV cache block indexer library for precise prefix cache scoring" "Internal Platform"

        # User interactions
        datascientist -> llmdScheduler "Configures InferencePool, InferenceObjective, EndpointPickerConfig"
        application -> envoyGateway "Sends inference requests (HTTP POST /v1/chat/completions)"

        # Core scheduling flow
        envoyGateway -> llmdScheduler "Calls EPP via gRPC ext-proc for routing decisions" "gRPC/9002 TLS"
        llmdScheduler -> envoyGateway "Returns target endpoint header"
        envoyGateway -> vllm "Forwards routed inference requests" "HTTP/8000"

        # EPP dependencies
        llmdScheduler -> kubernetes "Watches InferencePool, Pod, InferenceObjective, InferenceModelRewrite CRDs" "HTTPS/443"
        llmdScheduler -> vllm "Scrapes Prometheus metrics (queue depth, KV cache, running requests)" "HTTP/3000"
        llmdScheduler -> llmdKVCache "KV cache block index for prefix cache scoring" "Go library"

        # PD Sidecar flow
        pdSidecar -> vllm "Sends prefill/encode/decode requests" "HTTP(S)/Dynamic"

        # Observability
        prometheus -> llmdScheduler "Scrapes metrics" "HTTP/9090"
        llmdScheduler -> otel "Exports distributed traces" "gRPC/4317 OTLP"

        # Framework dependency
        llmdScheduler -> gie "Extends ext-proc framework with LLM-specific scheduling plugins" "Go library"
        llmdScheduler -> gatewayAPI "Uses Gateway and HTTPRoute CRDs" "Kubernetes API"
    }

    views {
        systemContext llmdScheduler "SystemContext" {
            include *
            autoLayout
        }

        container llmdScheduler "Containers" {
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
                background #08427b
                color #ffffff
                shape person
            }
            element "Software System" {
                background #4a90e2
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

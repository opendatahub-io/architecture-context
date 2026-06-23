workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys models and sends inference requests"
        sre = person "SRE / Platform Admin" "Monitors metrics, configures routing policies"

        llmdRouter = softwareSystem "llm-d Router" "Intelligent LLM-aware inference request router with ext-proc integration and disaggregation sidecar" {
            epp = container "Endpoint Picker (EPP)" "gRPC ext-proc server that evaluates request placement using pluggable scheduling framework with filters, scorers, and pickers" "Go gRPC Service"
            sidecar = container "Disaggregation Sidecar (pd-sidecar)" "HTTP reverse proxy that coordinates multi-stage inference (P/D, E/P/D) by routing between prefill, encode, and decode workers" "Go HTTP Reverse Proxy"
            schedulingEngine = container "Scheduling Engine" "Pluggable pipeline of filters (ByLabel, PrefixCacheAffinity, SessionAffinity), scorers (LoadAware, KVCacheUtil, LoRAffinity), and pickers (MaxScore, WeightedRandom)" "Go Library"
            flowControl = container "Flow Control" "Priority-based queuing with fairness policies (global strict, program-aware, round-robin) and SLO-based admission" "Go Library"
            reconcilers = container "K8s Reconcilers" "controller-runtime reconcilers watching InferencePool, Pod, InferenceObjective, InferenceModelRewrite resources" "Go controller-runtime"
        }

        envoyProxy = softwareSystem "Envoy Proxy" "L7 proxy that routes traffic based on EPP decisions via ext-proc protocol" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "API server for watching CRDs and pod resources" "External"
        modelServers = softwareSystem "Model Servers (vLLM/SGLang)" "LLM inference servers providing predictions, metrics, and model info" "Internal Platform"
        tokenizer = softwareSystem "Tokenizer Service" "Tokenizes request prompts for prefix cache and load scoring" "Internal Platform"
        latencyPredictor = softwareSystem "Latency Predictor" "Predicts per-request latency for SLO-based admission control" "Internal Platform"
        otlpCollector = softwareSystem "OTLP Collector" "Collects and exports distributed traces" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes metrics from EPP for monitoring" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API providing InferencePool CRD definitions" "External"

        # Relationships - System Context
        datascientist -> llmdRouter "Sends inference requests via" "HTTPS/443"
        datascientist -> llmdRouter "Creates InferenceObjective, InferenceModelRewrite CRs via" "kubectl"
        sre -> prometheus "Monitors EPP metrics via" "HTTP"

        llmdRouter -> envoyProxy "Receives requests from and returns routing decisions to" "gRPC ext-proc/9002 TLS"
        llmdRouter -> k8sAPI "Watches InferencePool, Pod, CRD resources" "HTTPS/443"
        llmdRouter -> modelServers "Polls metrics, models; routes inference requests" "HTTP/8000"
        llmdRouter -> tokenizer "Tokenizes prompts" "HTTP or UDS"
        llmdRouter -> latencyPredictor "Predicts request latency" "HTTP"
        llmdRouter -> otlpCollector "Exports traces" "gRPC/4317"

        envoyProxy -> llmdRouter "Consults for routing decisions" "gRPC ext-proc/9002"
        envoyProxy -> modelServers "Routes inference requests" "HTTP/8000"
        prometheus -> llmdRouter "Scrapes metrics" "HTTP/9090"

        # Relationships - Container
        epp -> schedulingEngine "Uses for endpoint selection"
        epp -> flowControl "Uses for priority queuing and admission"
        epp -> reconcilers "Uses for K8s resource state"
        reconcilers -> k8sAPI "Watches resources" "HTTPS/443"
        epp -> envoyProxy "Returns routing decisions" "gRPC ext-proc/9002 TLS"
        epp -> modelServers "Polls metrics and model info" "HTTP/8000"
        epp -> tokenizer "Tokenizes prompts" "HTTP/UDS"
        epp -> latencyPredictor "Predicts latency" "HTTP"
        epp -> otlpCollector "Exports traces" "gRPC/4317"

        sidecar -> modelServers "Routes to prefill, decode, encode workers" "HTTP(S)/dynamic"
        sidecar -> k8sAPI "Watches pods for SSRF allowlist" "HTTPS/443"
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

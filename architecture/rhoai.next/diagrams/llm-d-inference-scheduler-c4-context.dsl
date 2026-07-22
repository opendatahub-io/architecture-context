workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys models and sends inference requests"
        sre = person "SRE / Platform Admin" "Configures InferencePools, monitors metrics"

        llmdRouter = softwareSystem "llm-d Router (Inference Scheduler)" "Intelligent LLM inference request router with KV-cache-aware scheduling and disaggregated inference orchestration" {
            epp = container "Endpoint Picker (EPP)" "Intelligent routing engine using ext-proc gRPC protocol for real-time scheduling decisions" "Go Service" {
                extProcServer = component "ext-proc gRPC Server" "Receives request metadata from Envoy and returns routing decisions" "gRPC 9002/TCP"
                pluginFramework = component "Plugin Framework" "Pluggable filters, scorers, and pickers for endpoint selection" "Go Interfaces"
                flowController = component "Flow Controller" "Per-priority-band queuing, eviction, and fairness" "Go"
                dataLayer = component "Data Layer" "Scrapes model server metrics and KV-cache events" "HTTP + ZMQ"
                crdWatcher = component "CRD Reconcilers" "Watches InferencePool, InferenceObjective, InferenceModelRewrite" "controller-runtime"
                metricsServer = component "Metrics Server" "Exposes Prometheus metrics" "HTTP 9090/TCP"
            }
            sidecar = container "Disaggregation Sidecar (pd-sidecar)" "Coordinates P/D and E/P/D disaggregated inference with pluggable KV transfer connectors" "Go Sidecar" {
                httpProxy = component "HTTP Proxy" "Intercepts inference API requests and orchestrates multi-stage inference" "HTTP/HTTPS 8000/TCP"
                kvConnectors = component "KV Transfer Connectors" "Pluggable connectors: NIXL V2, Mooncake, SGLang, Shared Storage" "Go Plugins"
                ssrfProtection = component "SSRF Protection" "Optional allowlist validation against InferencePool pods" "Go"
            }
        }

        envoyProxy = softwareSystem "Envoy Proxy" "L7 proxy that routes traffic based on EPP ext-proc decisions" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing API, CRDs, and pod scheduling" "External"
        gatewayAPI = softwareSystem "Gateway API + Inference Extension" "HTTPRoute, Gateway, and InferencePool CRDs for traffic management" "External"
        istio = softwareSystem "Istio" "Optional service mesh for Gateway Mode with Istio provider" "External"
        modelServers = softwareSystem "Model Servers (vLLM/SGLang/Triton)" "GPU-accelerated LLM inference engines serving predictions" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        latencyPredictor = softwareSystem "Latency Predictor" "XGBoost-based TTFT/TPOT prediction for SLO-aware scheduling" "Internal Platform"
        kvCache = softwareSystem "llm-d-kv-cache" "KV-cache event library for prefix cache awareness" "Internal Platform"

        # User interactions
        datascientist -> envoyProxy "Sends inference requests via HTTPRoute" "HTTP/80"
        sre -> kubernetes "Configures InferencePool, InferenceObjective, InferenceModelRewrite CRs" "kubectl/HTTPS"

        # Envoy ↔ EPP
        envoyProxy -> epp "Sends request headers/body for routing decision" "gRPC ext-proc/9002 TLS"
        epp -> envoyProxy "Returns selected endpoint and header mutations" "gRPC ext-proc response"

        # Envoy → Model Servers (after routing)
        envoyProxy -> modelServers "Forwards inference request to selected endpoint" "HTTP/8000"

        # Envoy → Sidecar (P/D mode)
        envoyProxy -> sidecar "Forwards P/D inference requests to decode pod sidecar" "HTTP(S)/8000"

        # EPP dependencies
        epp -> kubernetes "Watches CRDs and Pods" "HTTPS/443 SA token"
        epp -> modelServers "Scrapes Prometheus metrics for scheduling signals" "HTTP/configurable"
        epp -> kvCache "Subscribes to KV-cache block events" "ZMQ SUB/5557"
        epp -> otlpCollector "Exports distributed traces" "gRPC/4317"
        epp -> latencyPredictor "Requests latency predictions for SLO scheduling" "HTTP/8000-8001+"
        prometheus -> epp "Scrapes operational metrics" "HTTP/9090"

        # Sidecar dependencies
        sidecar -> modelServers "Forwards to prefill, encode, and decode workers" "HTTP(S)/configurable"
        sidecar -> kubernetes "Watches pods for SSRF allowlist (optional)" "HTTPS/443"
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

        component sidecar "Sidecar-Components" {
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

workspace {
    model {
        user = person "ML Engineer / Client" "Sends inference requests to deployed models"

        llmdRouter = softwareSystem "llm-d Router" "Intelligent inference request router with LLM-aware load balancing, prefix-cache-aware routing, and disaggregated P/D coordination" {
            epp = container "Endpoint Picker (EPP)" "Envoy ext-proc gRPC service implementing pluggable scheduling with filters, scorers, data-layer, and flow-control plugins" "Go gRPC Service" {
                extProcServer = component "ExternalProcessor Server" "Receives per-request gRPC callouts from Envoy" "gRPC 9002/TCP"
                pluginFramework = component "Plugin Framework" "Configurable pipeline: filters, scorers, data-layer, flow-control, parsers" "Go"
                poolController = component "InferencePool Controller" "Watches InferencePool CRs for pool-based endpoint discovery" "controller-runtime"
                objectiveController = component "InferenceObjective Controller" "Watches InferenceObjective CRs for scheduling priorities" "controller-runtime"
                rewriteController = component "InferenceModelRewrite Controller" "Watches InferenceModelRewrite CRs for model name rewriting" "controller-runtime"
                podController = component "Pod Controller" "Watches model-serving Pods for endpoint discovery and health" "controller-runtime"
                metricsScraper = component "Metrics Scraper" "Scrapes KV-cache, queue depth, LoRA metrics from model servers" "HTTP"
            }
            sidecar = container "Disaggregation Sidecar (pd-sidecar)" "HTTP reverse proxy for disaggregated P/D and E/P/D inference coordination with KV-cache transfer" "Go HTTP Proxy"
        }

        envoyGateway = softwareSystem "Envoy Gateway" "L7 proxy that routes inference traffic via ext-proc callouts" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster control plane for resource watches and RBAC" "External"
        modelServers = softwareSystem "Model-Serving Pods" "vLLM instances serving inference workloads" "Internal"
        prefillWorkers = softwareSystem "Remote Prefill Workers" "vLLM prefill-phase workers in disaggregated topology" "Internal"
        encodeWorkers = softwareSystem "Remote Encode Workers" "Encoding workers for multimodal E/P/D inference" "Internal"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection and export" "External"
        gieExtension = softwareSystem "Gateway API Inference Extension (GIE)" "InferencePool API types and EPP protocol definitions" "Internal"
        kvCacheLib = softwareSystem "llm-d-kv-cache" "KV-cache metadata types for disaggregated inference" "Internal"

        user -> envoyGateway "Sends inference requests" "HTTPS/443"
        envoyGateway -> epp "gRPC ext-proc callout per request" "gRPC/9002"
        envoyGateway -> sidecar "Routes to decode pod (P/D mode)" "HTTP/8000"
        envoyGateway -> modelServers "Forwards routed request (gateway mode)" "HTTP"
        epp -> modelServers "Scrapes runtime metrics" "HTTP"
        epp -> k8sAPI "Watches InferencePool, Pods, InferenceObjective, InferenceModelRewrite" "HTTPS/6443"
        epp -> otelCollector "Exports distributed traces" "OTLP/gRPC"
        sidecar -> prefillWorkers "Orchestrates remote prefill" "HTTP/HTTPS"
        sidecar -> encodeWorkers "Orchestrates remote encoding (E/P/D mode)" "HTTP/HTTPS"
        sidecar -> modelServers "Forwards decode to local vLLM" "HTTP/8001"
        sidecar -> k8sAPI "InferencePool allowlist for SSRF protection" "HTTPS/6443"
        epp -> gieExtension "Uses InferencePool types and EPP protocol" "Go library"
        epp -> kvCacheLib "Uses KV-cache metadata types" "Go library"
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
            element "Internal" {
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

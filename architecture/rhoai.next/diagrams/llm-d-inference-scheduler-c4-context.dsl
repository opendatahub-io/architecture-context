workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys models and sends inference requests"

        llmdScheduler = softwareSystem "llm-d Inference Scheduler" "Optimized routing for LLM inference workloads via Gateway API Inference Extension (GIE)" {
            epp = container "EPP (Endpoint Picker)" "Main scheduling service: ext_proc gRPC server with pluggable filter/scorer/picker pipeline, controller-runtime reconcilers, flow control" "Go Service (controller-runtime)" {
                extProcServer = component "ext_proc gRPC Server" "Receives routing callbacks from Envoy, returns endpoint selection" "gRPC Service"
                schedulingPipeline = component "Scheduling Pipeline" "Filter → Score → Pick pipeline with configurable profiles" "Go Framework"
                controllers = component "CRD Reconcilers" "Watch InferencePool, Pod, InferenceObjective, InferenceModelRewrite" "controller-runtime"
                dataLayer = component "Data Layer" "DAG-based data collection from metrics, K8s, ZMQ sources" "Go Framework"
                kvCacheIndex = component "KV Cache Index" "In-process prefix cache index from ZMQ events" "llm-d-kv-cache library"
                flowControl = component "Flow Control" "Priority-based admission, fairness, saturation detection" "Go (Experimental)"
                metricsEndpoint = component "Metrics Endpoint" "Prometheus metrics on /metrics" "HTTP Server"
            }
            sidecar = container "P/D Routing Sidecar" "Orchestrates disaggregated Prefill/Decode and E/P/D inference stages with KV cache transfer" "Go HTTP Proxy" {
                sidecarProxy = component "HTTP/HTTPS Proxy" "Intercepts inference API calls, coordinates P/D stages" "Go HTTP Proxy"
                nixlConnector = component "NIXL V2 Connector" "Direct memory KV cache transfer" "Go Plugin"
                sharedStorageConnector = component "Shared Storage Connector" "KV transfer via intermediate storage" "Go Plugin"
                sglangConnector = component "SGLang Connector" "Concurrent P/D via room-based coordination" "Go Plugin"
                ssrfAllowlist = component "SSRF Allowlist" "Validates targets against InferencePool pod list" "Go Security"
            }
            udsTokenizer = container "UDS Tokenizer" "Tokenization sidecar for prompt tokenization via Unix Domain Socket" "External Image"
        }

        envoyGateway = softwareSystem "Envoy Gateway" "Gateway API implementation with ext_proc filter for request routing" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane for CRD management and pod discovery" "External"
        vllmServers = softwareSystem "vLLM Model Servers" "LLM inference engine pods serving predictions with KV cache" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        gatewayAPI = softwareSystem "Gateway API CRDs" "HTTPRoute and Gateway resources for traffic routing" "External"

        # User interactions
        user -> envoyGateway "Sends inference requests (HTTP)" "HTTP/80"
        user -> k8sAPI "Creates InferenceService, InferencePool CRs" "kubectl"

        # Envoy → EPP
        envoyGateway -> epp "Sends ext_proc routing callbacks" "gRPC/9002"
        epp -> envoyGateway "Returns endpoint selection (target-pod header)" "gRPC/9002"

        # Envoy → Model Servers
        envoyGateway -> vllmServers "Routes inference requests to selected pod" "HTTP/8000"
        envoyGateway -> sidecar "Routes P/D requests to sidecar" "HTTP/8000"

        # EPP dependencies
        epp -> k8sAPI "Watches CRDs: InferencePool, Pod, InferenceObjective, InferenceModelRewrite" "HTTPS/443"
        epp -> vllmServers "Scrapes Prometheus metrics (queue, KV cache, LoRA)" "HTTP(S)"
        epp -> vllmServers "Subscribes to KV cache events" "ZMQ PUB/SUB/5556"
        udsTokenizer -> epp "Provides prompt tokenization" "gRPC over UDS"

        # Sidecar dependencies
        sidecar -> vllmServers "Forwards prefill/decode/encode requests" "HTTP(S)/8001"
        sidecar -> k8sAPI "Watches InferencePool for SSRF allowlist" "HTTPS/443"

        # Observability
        prometheus -> epp "Scrapes /metrics endpoint" "HTTP/9090"
        epp -> otelCollector "Exports distributed traces" "gRPC OTLP/4317"

        # Gateway API integration
        gatewayAPI -> envoyGateway "HTTPRoute references InferencePool as backendRef" "CRD"
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

        component epp "EPP-Components" {
            include *
            autoLayout
        }

        component sidecar "Sidecar-Components" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
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
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Component" {
                background #85BBF0
                color #000000
            }
        }
    }
}

workspace {
    model {
        user = person "ML Engineer / Application" "Sends inference requests to LLM models"

        llmdRouter = softwareSystem "llm-d Router" "Intelligent inference traffic router with LLM load-aware and prefix-cache-aware routing" {
            epp = container "Endpoint Picker (EPP)" "Envoy ext-proc routing engine with plugin-driven scheduling, flow control, and data-layer integration" "Go gRPC Service + Controller" "core"
            coordinator = container "Coordinator" "Orchestrates disaggregated inference pipelines (E/P/D and P/D) through configurable steps" "Go HTTP Service" "core"
            pdSidecar = container "PD-Sidecar" "Routes inference requests through prefill/encode workers alongside decode model servers" "Go Reverse Proxy" "core"
            infObjController = container "InferenceObjective Controller" "Reconciles InferenceObjective resources for priority-based scheduling" "Go Controller"
            infRewriteController = container "InferenceModelRewrite Controller" "Reconciles InferenceModelRewrite resources for model-name rewriting" "Go Controller"
            poolController = container "InferencePool Controller" "Reconciles InferencePool resources from Gateway API Inference Extension" "Go Controller"
            podController = container "Pod Controller" "Watches Pods in InferencePool selector for datastore population" "Go Controller"
        }

        envoy = softwareSystem "Envoy Proxy" "Service proxy that routes traffic using ext-proc" "External"
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for CRD and Pod management" "External"
        modelServers = softwareSystem "Model Server Pods" "vLLM inference workers (decode, prefill, encode)" "External"
        inferenceGateway = softwareSystem "Inference Gateway" "Gateway for routing inference requests to model pools" "Internal Platform"
        renderingService = softwareSystem "Rendering Service" "Tokenization and multimodal preprocessing" "Internal Platform"
        redis = softwareSystem "Redis" "Queue storage for async inference broker" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection and export" "External"
        gatewayApiInfExt = softwareSystem "gateway-api-inference-extension" "InferencePool types and EPP protocol definitions" "External"
        llmdAsync = softwareSystem "llm-d-async" "Async inference broker API and producer" "External"

        # Relationships
        user -> envoy "Sends inference requests" "HTTPS/443"
        envoy -> epp "ext-proc callout for routing decisions" "gRPC/9002"
        epp -> envoy "Returns routing headers" "gRPC/9002"
        envoy -> modelServers "Forwards routed request" "HTTP(S)"

        user -> coordinator "Sends inference requests (disaggregated)" "HTTPS/8080"
        coordinator -> inferenceGateway "Forwards encode/prefill/decode steps" "HTTP/80"
        coordinator -> renderingService "Tokenization and preprocessing" "HTTP/8080"
        coordinator -> redis "Async queue operations" "TCP/6379"

        pdSidecar -> modelServers "Routes through prefill/encode/decode workers" "HTTP(S)"

        epp -> k8sApi "Watches CRDs and Pods" "HTTPS/6443"
        epp -> modelServers "Scrapes metrics, DCGM, model metadata" "HTTP(S)"
        epp -> otelCollector "Exports traces" "OTLP/gRPC"
        coordinator -> otelCollector "Exports traces" "OTLP/gRPC"

        poolController -> k8sApi "Watches InferencePool resources" "HTTPS/6443"
        infObjController -> k8sApi "Watches InferenceObjective resources" "HTTPS/6443"
        infRewriteController -> k8sApi "Watches InferenceModelRewrite resources" "HTTPS/6443"
        podController -> k8sApi "Watches Pod resources" "HTTPS/6443"
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
            element "core" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Submits inference requests and deploys models"
        platformadmin = person "Platform Admin" "Configures routing policies and InferencePool resources"

        llmdRouter = softwareSystem "llm-d Router" "Intelligent LLM inference router with KV-cache-aware request placement, priority scheduling, and disaggregated inference coordination" {
            epp = container "Endpoint Picker (EPP)" "Integrates with Envoy via ext-proc to make KV-cache-aware, priority-driven endpoint placement decisions" "Go gRPC Service"
            coordinator = container "Coordinator" "Orchestrates disaggregated inference pipelines (encode/prefill/decode) with TLS serving and OpenTelemetry tracing" "Go HTTP Service"
            sidecar = container "Disaggregation Sidecar" "Per-pod reverse proxy alongside model servers to coordinate prefill/decode KV-cache transfers" "Go HTTP Proxy"
            ioController = container "InferenceObjective Controller" "Reconciles InferenceObjective resources for priority scheduling" "Go Controller"
            imrController = container "InferenceModelRewrite Controller" "Reconciles InferenceModelRewrite resources for model name rewriting" "Go Controller"
            ipController = container "InferencePool Controller" "Reconciles InferencePool resources for pool-based routing" "Go Controller"
            podController = container "Pod Controller" "Watches Pod resources to maintain the endpoint datastore" "Go Controller"
        }

        envoyProxy = softwareSystem "Envoy Proxy" "Production-grade proxy providing ext-proc callouts for per-request routing" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource watches and RBAC" "External"
        redis = softwareSystem "Redis" "Queue backend for async inference broker" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection and export" "External"
        renderingService = softwareSystem "Rendering Service" "Tokenizes requests before disaggregated processing" "Internal"
        inferenceGateway = softwareSystem "Inference Gateway" "Routes encode/prefill/decode requests to EPP-selected endpoints" "Internal"
        modelServers = softwareSystem "Model Server Pods" "vLLM/SGLang instances serving inference workloads" "Internal"
        gatewayAPIExt = softwareSystem "Gateway API Inference Extension" "InferencePool API types and endpoint picker protocol" "Internal"
        llmdAsync = softwareSystem "llm-d-async" "Async request submission and result retrieval library" "Internal"

        datascientist -> llmdRouter "Submits inference requests via Gateway" "HTTPS/443"
        platformadmin -> llmdRouter "Configures InferencePool, InferenceObjective, EndpointPickerConfig" "kubectl"

        envoyProxy -> epp "Per-request ext-proc callouts" "gRPC/9002"
        epp -> envoyProxy "Returns routing decisions (selected endpoint)" "gRPC response"
        epp -> kubernetesAPI "Watches InferencePool, InferenceObjective, InferenceModelRewrite, Pod" "HTTPS/6443"
        epp -> modelServers "Scrapes Prometheus metrics (queue depth, KV-cache, LoRA)" "HTTP"
        epp -> otelCollector "Exports distributed traces" "OTLP/gRPC"

        coordinator -> renderingService "Tokenizes requests" "HTTP/8080"
        coordinator -> inferenceGateway "Forwards encode/prefill/decode requests" "HTTP/80"
        coordinator -> redis "Async broker queue operations" "TCP/6379"
        coordinator -> otelCollector "Exports distributed traces" "OTLP/gRPC"

        sidecar -> modelServers "Proxies decode requests to local model server" "HTTP/8200"
        sidecar -> modelServers "Proxies prefill requests to prefill workers" "HTTP/HTTPS"
        sidecar -> otelCollector "Exports distributed traces" "OTLP/gRPC"

        ioController -> kubernetesAPI "Reconciles InferenceObjective resources" "HTTPS/6443"
        imrController -> kubernetesAPI "Reconciles InferenceModelRewrite resources" "HTTPS/6443"
        ipController -> kubernetesAPI "Reconciles InferencePool resources" "HTTPS/6443"
        podController -> kubernetesAPI "Watches Pod resources" "HTTPS/6443"
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
            element "Internal" {
                background #7ed321
                color #000000
            }
            element "Person" {
                shape person
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

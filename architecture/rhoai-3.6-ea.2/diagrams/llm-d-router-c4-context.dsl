workspace {
    model {
        client = person "Client Application" "Sends inference requests to LLM models"
        mlEngineer = person "ML Engineer" "Configures scheduling objectives, model rewrites, and deployment modes"

        llmdRouter = softwareSystem "llm-d Router" "Intelligent inference traffic router with LLM load-aware and prefix-cache-aware routing, request prioritization, and disaggregated inference coordination" {
            epp = container "Endpoint Picker (EPP)" "Envoy ext-proc server that scores and selects model-serving endpoints based on KV-cache locality, load, and priority via a plugin-based scheduling framework" "Go gRPC Service"
            coordinator = container "Coordinator" "Orchestrates multi-stage disaggregated inference (Encode/Prefill/Decode) through a configurable pipeline of steps" "Go HTTP Service"
            sidecar = container "Disaggregation Sidecar" "Runs alongside decode workers to coordinate prefill/decode handoff and KV-cache transfers" "Go HTTP Proxy"
            ioController = container "InferenceObjective Controller" "Reconciles scheduling goals, priority levels, and performance targets" "controller-runtime"
            imrController = container "InferenceModelRewrite Controller" "Reconciles model name rewriting for A/B testing and canary rollouts" "controller-runtime"
            ipController = container "InferencePool Controller" "Reconciles InferencePool resources for pool-based routing" "controller-runtime"
            podController = container "Pod Controller" "Maintains in-memory datastore of model-serving pod states" "controller-runtime"
            dataStore = container "In-Memory DataStore" "Stores pod states, model objectives, and scheduling profiles" "Go in-memory"
        }

        envoy = softwareSystem "Envoy Proxy" "L7 proxy providing ext-proc callouts for routing decisions" "External"
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for CRD and Pod watches" "External"
        inferenceGateway = softwareSystem "Inference Gateway" "Routes encode/prefill/decode requests to specialized worker pods" "Internal llm-d"
        redis = softwareSystem "Redis" "Async broker queue and result storage for deferred request processing" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        renderingSvc = softwareSystem "Rendering Service" "Tokenizes requests for the coordinator render pipeline step" "Internal llm-d"
        modelServer = softwareSystem "Model Server" "Runs ML model inference (decode workers)" "Internal llm-d"
        prefillWorkers = softwareSystem "Prefill Workers" "Specialized pods for prefill computation" "Internal llm-d"
        encoderWorkers = softwareSystem "Encoder Workers" "Specialized pods for multimodal encoding" "Internal llm-d"
        gatewayApi = softwareSystem "Gateway API Inference Extension" "Kubernetes Gateway API with inference extension CRDs" "External"

        # Relationships
        client -> envoy "Sends inference requests" "HTTPS/443"
        mlEngineer -> k8sApi "Configures InferenceObjective, InferenceModelRewrite CRDs" "kubectl"

        envoy -> epp "ext-proc callout for routing decisions" "gRPC/9002"
        epp -> envoy "Returns selected endpoint" "gRPC/9002"
        envoy -> modelServer "Forwards routed request" "HTTP(S)"

        client -> coordinator "Sends disaggregated inference requests" "HTTP/8080"
        coordinator -> renderingSvc "Tokenizes requests" "HTTP/8080"
        coordinator -> inferenceGateway "Routes E/P/D requests" "HTTP/80"
        coordinator -> redis "Enqueues/dequeues async requests" "TCP/6379"

        inferenceGateway -> sidecar "Forwards to decode worker pod" "HTTP/8000"
        sidecar -> modelServer "Forwards decode requests" "HTTP/8200"
        sidecar -> prefillWorkers "Coordinates prefill stage" "HTTP(S)"
        sidecar -> encoderWorkers "Coordinates encode stage" "HTTP(S)"

        ioController -> k8sApi "Watches InferenceObjective CRDs" "HTTPS/6443"
        imrController -> k8sApi "Watches InferenceModelRewrite CRDs" "HTTPS/6443"
        ipController -> k8sApi "Watches InferencePool CRDs" "HTTPS/6443"
        podController -> k8sApi "Watches Pod resources" "HTTPS/6443"

        ioController -> dataStore "Updates scheduling profiles"
        imrController -> dataStore "Updates model rewrite rules"
        ipController -> dataStore "Updates pool configuration"
        podController -> dataStore "Updates pod states"
        epp -> dataStore "Queries for endpoint scoring"

        epp -> otel "Exports traces" "OTLP/gRPC"
        coordinator -> otel "Exports traces" "OTLP/gRPC"
        sidecar -> otel "Exports traces" "OTLP/gRPC"
        prometheus -> epp "Scrapes metrics" "HTTP/9090"
        prometheus -> coordinator "Scrapes metrics" "HTTP/9090"

        gatewayApi -> ipController "Provides InferencePool CRD" "Kubernetes API"
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
            element "Internal llm-d" {
                background #7ed321
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
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

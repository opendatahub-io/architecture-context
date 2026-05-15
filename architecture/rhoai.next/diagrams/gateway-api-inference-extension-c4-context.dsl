workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys and manages ML inference workloads on Kubernetes"
        platformAdmin = person "Platform Admin" "Configures gateway routing and InferencePool resources"

        igw = softwareSystem "Gateway API Inference Extension" "Envoy ext-proc extension for intelligent LLM inference request scheduling and routing" {
            epp = container "Endpoint Picker (EPP)" "Primary ext-proc server: schedules inference requests to optimal model server endpoints using pluggable filters, scorers, and pickers" "Go gRPC Service"
            bbr = container "Body Based Router (BBR)" "Optional ext-proc server: parses request bodies to extract model names and LoRA adapter info into headers" "Go gRPC Service"
            crdControllers = container "CRD Controllers" "Reconcile InferencePool, InferenceObjective, InferenceModelRewrite, and Pod resources" "Go controller-runtime"
            latencyTraining = container "Latency Training Server" "Collects inference latency observations and trains XGBoost/LightGBM/BayesianRidge prediction models" "Python HTTP Service"
            latencyPrediction = container "Latency Prediction Server" "Serves trained latency prediction models for real-time TTFT/TPOT estimation" "Python HTTP Service"
            latencyAsyncClient = container "Latency Predictor Async Client" "Async Go client with request coalescing for non-blocking latency prediction queries" "Go Sidecar Library"
        }

        envoyGateway = softwareSystem "Envoy-based Gateway" "Any ext-proc capable proxy: Envoy Gateway, Istio, GKE Gateway, kgateway, nginx Gateway Fabric" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API CRDs (HTTPRoute, Gateway) for routing inference traffic" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API for CRD and Pod management" "External"
        modelServers = softwareSystem "Model Servers" "vLLM, sglang, triton-tensorrt-llm, trtllm-serve - serve ML inference and expose Prometheus metrics" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate management" "External"

        # Relationships - System Context
        dataScientist -> igw "Creates InferencePool, InferenceObjective, InferenceModelRewrite CRs via kubectl"
        platformAdmin -> envoyGateway "Configures Gateway and HTTPRoute resources"
        envoyGateway -> igw "Sends ext-proc requests for inference scheduling" "gRPC/9002,9004 TLS"
        igw -> k8sAPI "Watches CRDs, Pods, ConfigMaps" "HTTPS/443"
        igw -> modelServers "Scrapes Prometheus metrics for scheduling decisions" "HTTP(S)/configurable"
        igw -> otlpCollector "Exports distributed traces" "gRPC/4317"
        prometheus -> igw "Scrapes EPP/BBR metrics" "HTTP/9090"
        envoyGateway -> modelServers "Routes inference requests to selected endpoints" "HTTP or gRPC"
        igw -> certManager "Loads TLS certificates (optional)" "Filesystem"

        # Relationships - Container
        envoyGateway -> bbr "ext-proc: extract model name from request body" "gRPC/9004 TLS"
        envoyGateway -> epp "ext-proc: select optimal model server endpoint" "gRPC/9002 TLS"
        bbr -> k8sAPI "Watch ConfigMaps (adapter-to-base-model mappings)" "HTTPS/443"
        crdControllers -> k8sAPI "Watch InferencePool, InferenceObjective, InferenceModelRewrite, Pods" "HTTPS/443"
        crdControllers -> epp "Provides CRD state to scheduling framework" "In-process"
        epp -> modelServers "Scrape Prometheus metrics (KV cache, queue depth, running reqs)" "HTTP(S)"
        epp -> latencyAsyncClient "Query latency predictions" "In-process"
        latencyAsyncClient -> latencyTraining "Submit training data observations" "HTTP/8000"
        latencyAsyncClient -> latencyPrediction "Request TTFT/TPOT predictions (coalesced)" "HTTP/8001"
        latencyTraining -> latencyPrediction "Trained model files via shared PVC" "Filesystem"
        epp -> otlpCollector "Export traces" "gRPC/4317"
    }

    views {
        systemContext igw "SystemContext" {
            include *
            autoLayout
        }

        container igw "Containers" {
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
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

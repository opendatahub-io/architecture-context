workspace {
    model {
        platformEngineer = person "Platform Engineer" "Configures InferencePool, InferenceObjective, and InferenceModelRewrite CRDs"
        dataScientist = person "Data Scientist" "Sends inference requests to deployed models"

        igw = softwareSystem "Gateway API Inference Extension" "Extends Gateway API-compatible proxies into inference gateways with KV-cache-aware endpoint selection and body-based routing" {
            epp = container "Endpoint Picker (EPP)" "Intelligent endpoint selection via pluggable scheduling framework (Filter → Score → Pick)" "Go ext-proc Service"
            bbr = container "Body Based Router (BBR)" "Parses HTTP request bodies to extract model names into headers for routing" "Go ext-proc Service"
            trainingServer = container "Latency Training Server" "Trains XGBoost models for TTFT/TPOT prediction from model server metrics" "Python Sidecar"
            predictionServer = container "Latency Prediction Server" "Serves latency predictions for EPP predicted-latency scoring" "Python Sidecar"
        }

        envoyGateway = softwareSystem "Gateway / Envoy Proxy" "Gateway API-compatible proxy with ext-proc filter support (Envoy Gateway, kGateway, GKE Gateway, Istio)" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform with CRD support (v1.31+)" "External"
        modelServers = softwareSystem "Model Servers" "Generative AI model server backends (vLLM, SGLang, Triton TensorRT-LLM, trtllm-serve)" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection (optional)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping and monitoring" "External"

        # Person relationships
        platformEngineer -> igw "Configures InferencePool, InferenceObjective, InferenceModelRewrite CRDs via kubectl"
        dataScientist -> envoyGateway "Sends inference requests" "HTTPS/443"

        # System-level relationships
        envoyGateway -> igw "Forwards requests via ext-proc for endpoint selection and body parsing" "gRPC/9002, 9004 TLS"
        igw -> modelServers "Scrapes Prometheus metrics for scheduling decisions" "HTTP/configurable"
        igw -> kubernetes "Watches CRDs (InferencePool, InferenceObjective, InferenceModelRewrite) and Pods" "HTTPS/443"
        igw -> otelCollector "Exports distributed traces (optional)" "gRPC/4317"
        prometheus -> igw "Scrapes metrics" "HTTP/9090"
        envoyGateway -> modelServers "Forwards inference requests to EPP-selected endpoint" "HTTP/8000"

        # Container-level relationships
        envoyGateway -> bbr "Sends request body for model name extraction" "gRPC ext-proc/9004 TLS"
        envoyGateway -> epp "Sends request for endpoint selection" "gRPC ext-proc/9002 TLS"
        epp -> modelServers "Scrapes /metrics for KV cache, queue depth, running requests" "HTTP/configurable"
        epp -> kubernetes "Watches InferencePool, InferenceObjective, InferenceModelRewrite, Pods, Leases" "HTTPS/443"
        epp -> predictionServer "Queries latency predictions" "HTTP/8001+"
        bbr -> kubernetes "Watches ConfigMaps (bbr-managed)" "HTTPS/443"
        trainingServer -> predictionServer "Syncs trained models" "HTTP (internal)"
        epp -> otelCollector "Exports traces" "gRPC/4317"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
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
        }
    }
}

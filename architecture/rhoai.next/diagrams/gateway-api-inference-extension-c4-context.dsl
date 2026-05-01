workspace {
    model {
        user = person "ML Engineer / Data Scientist" "Sends inference requests to hosted ML models"
        platformAdmin = person "Platform Admin" "Configures InferencePool, routing rules, and model deployments"

        igw = softwareSystem "Gateway API Inference Extension" "Extends Gateway API-compatible proxies into inference gateways with KV-cache-aware endpoint selection and body-based routing" {
            epp = container "Endpoint Picker (EPP)" "Intelligent endpoint selection for inference requests via pluggable scheduling framework (Filter → Score → Pick)" "Go ext-proc Service"
            bbr = container "Body Based Router (BBR)" "Parses HTTP request bodies to extract model names into headers for gateway routing" "Go ext-proc Service"
            latencyTraining = container "Latency Training Server" "Trains XGBoost models for predicting TTFT and TPOT latency" "Python Sidecar (optional)"
            latencyPrediction = container "Latency Prediction Server" "Serves latency predictions via HTTP for scheduling decisions" "Python Sidecar (optional)"
            clientGo = container "client-go Library" "Generated Kubernetes client library (clientset, informers, listers) for IGW CRDs" "Go Library"
        }

        envoyGateway = softwareSystem "Gateway / Envoy Proxy" "Gateway API-compatible proxy with ext-proc filter support (Envoy Gateway, kGateway, GKE Gateway, Istio)" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform hosting CRDs and model server pods" "External"
        modelServers = softwareSystem "Model Servers" "vLLM, SGLang, Triton TensorRT-LLM, trtllm-serve — backends hosting inference models" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend" "External"
        gatewayAPI = softwareSystem "Gateway API CRDs" "HTTPRoute and related CRDs for traffic routing" "External"

        # User interactions
        user -> envoyGateway "Sends inference requests" "HTTPS/443"
        platformAdmin -> kubernetes "Creates InferencePool, InferenceObjective, InferenceModelRewrite CRDs" "kubectl/HTTPS"

        # Gateway ↔ IGW interactions
        envoyGateway -> bbr "Sends request for body parsing" "gRPC/9004 TLS"
        envoyGateway -> epp "Sends request for endpoint selection" "gRPC/9002 TLS"
        envoyGateway -> modelServers "Forwards inference request to selected endpoint" "HTTP/8000"

        # EPP interactions
        epp -> kubernetes "Watches InferencePool, InferenceObjective, InferenceModelRewrite, Pods" "HTTPS/443"
        epp -> modelServers "Scrapes Prometheus metrics (KV cache, queue depth, LoRA)" "HTTP/configurable"
        epp -> latencyPrediction "Queries latency predictions for scoring" "HTTP/8001"
        epp -> otel "Exports distributed traces" "gRPC/4317"

        # BBR interactions
        bbr -> kubernetes "Watches ConfigMaps (adapter-to-base-model mappings)" "HTTPS/443"

        # Latency Predictor interactions
        latencyTraining -> latencyPrediction "Syncs trained XGBoost models" "HTTP/internal"

        # Monitoring
        prometheus -> epp "Scrapes EPP metrics" "HTTP/9090"
        prometheus -> bbr "Scrapes BBR metrics" "HTTP/9090"

        # client-go used by EPP
        epp -> clientGo "Uses generated clientset and informers" "In-process"
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

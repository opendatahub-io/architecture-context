workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys and queries ML models via inference APIs"
        platformAdmin = person "Platform Administrator" "Configures InferencePool, routing rules, and gateway policies"

        igw = softwareSystem "Gateway API Inference Extension" "Extends Gateway API proxies into inference gateways with KV-cache-aware endpoint selection and request routing" {
            epp = container "Endpoint Picker (EPP)" "Envoy ext-proc server performing intelligent endpoint selection using scheduling plugins, flow control, and model server metrics" "Go gRPC Service"
            bbr = container "Body-Based Router (BBR)" "Envoy ext-proc server parsing request bodies to extract model names and map LoRA adapters to base models" "Go gRPC Service"
            latencyTraining = container "Latency Training Server" "Trains latency prediction models (XGBoost/LightGBM) from inference telemetry" "Python Service"
            latencyPrediction = container "Latency Prediction Server" "Serves TTFT/TPOT latency predictions via HTTP API" "Python Service"
        }

        envoyGateway = softwareSystem "Envoy-Compatible Gateway" "Gateway API proxy (Envoy Gateway / kgateway / Istio / GKE Gateway) with ext-proc filter chain" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing CRD hosting, Pod discovery, RBAC, leader election" "External"
        modelServers = softwareSystem "Model Servers" "vLLM / SGLang / Triton TensorRT-LLM serving inference requests" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"
        gatewayAPICRDs = softwareSystem "Gateway API CRDs" "HTTPRoute references InferencePool as backend" "External"

        # User interactions
        dataScientist -> envoyGateway "Sends inference requests via HTTPS/443"
        platformAdmin -> kubernetes "Creates InferencePool, InferenceObjective, InferenceModelRewrite CRDs"

        # Gateway → IGW ext-proc chain
        envoyGateway -> bbr "Sends request body for model name extraction" "gRPC/9004 TLS"
        envoyGateway -> epp "Sends request for endpoint selection" "gRPC/9002 TLS"

        # EPP internal
        epp -> latencyTraining "Submits training data" "HTTP/8000"
        epp -> latencyPrediction "Requests latency predictions" "HTTP/8001+"

        # IGW → External systems
        epp -> kubernetes "Watches InferencePool, InferenceObjective, InferenceModelRewrite CRDs, Pods, Leases" "HTTPS/443"
        bbr -> kubernetes "Watches ConfigMaps with bbr-managed label" "HTTPS/443"
        epp -> modelServers "Scrapes Prometheus metrics (KV cache, queue depth, LoRA status)" "HTTP/varies"
        envoyGateway -> modelServers "Forwards inference requests to selected endpoint" "HTTP/varies"

        # Observability
        prometheus -> igw "Scrapes metrics from EPP/BBR" "HTTP/9090"
        epp -> otlpCollector "Exports distributed traces" "gRPC/4317"

        # Gateway API integration
        gatewayAPICRDs -> envoyGateway "HTTPRoute references InferencePool as backendRef"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

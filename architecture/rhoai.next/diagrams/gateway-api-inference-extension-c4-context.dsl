workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and queries ML models via inference endpoints"
        platformadmin = person "Platform Admin" "Configures InferencePool, routing, and scheduling policies"

        igw = softwareSystem "Gateway API Inference Extension" "Extends Gateway API-compatible proxies with intelligent, KV-cache-aware endpoint selection for self-hosted generative AI models" {
            epp = container "Endpoint Picker (EPP)" "Envoy ext-proc server performing intelligent endpoint selection via scheduling plugins, flow control, and model server metrics scraping" "Go gRPC Service"
            bbr = container "Body-Based Router (BBR)" "Envoy ext-proc server parsing request bodies to extract model names and map LoRA adapters to base models via header injection" "Go gRPC Service"
            latencyPredictor = container "Latency Predictor Sidecar" "Async client library for latency prediction using XGBoost/LightGBM models" "Go Library (EPP sidecar)"
            latencyTraining = container "Latency Training Server" "Trains latency prediction models from inference request telemetry data" "Python Service"
            latencyPrediction = container "Latency Prediction Server" "Serves latency predictions via HTTP API using trained models" "Python Service"

            epp -> latencyPredictor "Uses for latency estimates" "In-process"
            latencyPredictor -> latencyTraining "Submits training data" "HTTP/8000"
            latencyPredictor -> latencyPrediction "Requests predictions" "HTTP/8001+"
        }

        gateway = softwareSystem "Envoy-compatible Gateway" "Gateway API proxy that delegates request processing to ext-proc filters (Envoy Gateway, kgateway, Istio, GKE Gateway)" "External"
        kubernetes = softwareSystem "Kubernetes API" "Hosts CRDs (InferencePool, InferenceObjective, InferenceModelRewrite), Pods, ConfigMaps, Leases" "External"
        modelServers = softwareSystem "Model Servers" "vLLM, SGLang, or Triton TensorRT-LLM pods serving inference requests and exposing Prometheus metrics" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes EPP/BBR metrics for monitoring and alerting" "External"
        otlp = softwareSystem "OpenTelemetry Collector" "Receives distributed traces from EPP/BBR" "External"

        datascientist -> gateway "Sends inference requests" "HTTPS/443"
        platformadmin -> kubernetes "Creates InferencePool, InferenceObjective, InferenceModelRewrite CRDs" "kubectl/HTTPS"

        gateway -> igw "Sends ext-proc requests for routing decisions" "gRPC/9002, 9004 TLS"
        igw -> gateway "Returns endpoint selection headers" "gRPC ext-proc response"
        gateway -> modelServers "Forwards inference requests to EPP-selected endpoint" "HTTP/gRPC"

        igw -> kubernetes "Watches CRDs, Pods, ConfigMaps; leader election Leases" "HTTPS/443 SA Token"
        igw -> modelServers "Scrapes Prometheus metrics (KV cache, queue depth, LoRA info)" "HTTP/varies InsecureSkipVerify"
        igw -> otlp "Exports distributed traces" "gRPC/4317"

        prometheus -> igw "Scrapes metrics" "HTTP/9090 Bearer Token"
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

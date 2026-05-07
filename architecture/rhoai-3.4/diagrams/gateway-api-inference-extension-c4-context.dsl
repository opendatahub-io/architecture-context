workspace {
    model {
        user = person "ML Engineer / Data Scientist" "Deploys and manages inference workloads on Kubernetes"
        platformAdmin = person "Platform Admin" "Configures gateway infrastructure and InferencePools"

        igw = softwareSystem "Gateway API Inference Extension" "Extends Gateway API proxies into inference-aware load balancers with intelligent scheduling" {
            epp = container "Endpoint Picker Proxy (EPP)" "Core inference scheduling engine — intercepts Envoy ext-proc streams, applies scheduling pipeline (filters, scorers, pickers), selects optimal model-serving endpoint" "Go gRPC Service"
            bbr = container "Body-Based Router (BBR)" "Parses HTTP request bodies to extract model names and sets routing headers for gateway-level routing decisions" "Go gRPC Service"
            trainingServer = container "Latency Training Server" "Trains XGBoost models on observed latency data (TTFT, TPOT) for SLO-aware scheduling" "Python FastAPI"
            predictionServer = container "Latency Prediction Server" "Serves real-time latency predictions from trained models for endpoint scoring" "Python FastAPI"
            asyncClient = container "Latency Predictor Async Client" "Coalesces and dispatches latency samples from EPP to training server" "Go Sidecar"
            loraSidecar = container "Dynamic LoRA Sidecar" "Manages dynamic LoRA adapter loading on model servers" "Python Sidecar"
        }

        envoyGateway = softwareSystem "Envoy Gateway / Gateway API Proxy" "Gateway API-compatible proxy providing ext-proc filter for request interception" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform hosting CRDs, Pods, and Services" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API providing Gateway and HTTPRoute CRDs" "External"
        modelServers = softwareSystem "Model Servers (vLLM / SGLang / Triton)" "GPU-accelerated model serving backends for inference workloads" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend" "External"
        istio = softwareSystem "Istio" "Service mesh and gateway provider with EnvoyFilter and DestinationRule support" "External"

        # User interactions
        user -> igw "Creates InferencePool, InferenceObjective, InferenceModelRewrite CRDs via kubectl"
        platformAdmin -> envoyGateway "Configures Gateway and HTTPRoute resources"

        # IGW internal relationships
        epp -> bbr "BBR sets routing headers before EPP selects endpoint" "gRPC ext-proc chain"
        asyncClient -> trainingServer "Sends coalesced latency samples" "HTTP/8000"
        epp -> predictionServer "Requests latency predictions for scoring" "HTTP/8001"
        trainingServer -> predictionServer "Shares trained models via PVC" "Filesystem"
        loraSidecar -> modelServers "Manages dynamic LoRA adapter loading" "Sidecar"

        # External interactions
        envoyGateway -> epp "Sends ext-proc streams for endpoint selection" "gRPC/9002 TLS"
        envoyGateway -> bbr "Sends ext-proc streams for body parsing" "gRPC/9004 TLS"
        epp -> envoyGateway "Returns routing decisions (selected endpoint)" "gRPC ext-proc response"
        envoyGateway -> modelServers "Routes inference requests to selected pod" "HTTP"

        epp -> kubernetes "Watches InferencePool, Pod, InferenceObjective, InferenceModelRewrite CRDs; leader election leases" "HTTPS/443"
        bbr -> kubernetes "Watches ConfigMaps labeled bbr-managed=true" "HTTPS/443"
        epp -> modelServers "Scrapes Prometheus metrics (KV cache, queue depth, LoRA info)" "HTTP/HTTPS"

        igw -> gatewayAPI "Uses Gateway and HTTPRoute CRDs for traffic routing" "CRD reference"
        igw -> istio "Integrates via EnvoyFilter and DestinationRule CRDs" "CRD reference"

        prometheus -> epp "Scrapes metrics endpoint" "HTTP/9090"
        prometheus -> bbr "Scrapes metrics endpoint" "HTTP/9090"
        epp -> otel "Exports distributed traces" "gRPC"
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
            element "Internal Platform" {
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
                background #5ba3f5
                color #ffffff
            }
        }
    }
}

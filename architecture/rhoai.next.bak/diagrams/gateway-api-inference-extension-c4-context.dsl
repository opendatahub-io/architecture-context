workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys models and creates InferencePool, InferenceObjective, InferenceModelRewrite resources"
        platformadmin = person "Platform Administrator" "Configures gateway, deploys IGW components via Helm, manages scheduling profiles"
        apiclient = person "API Client" "Sends inference requests (OpenAI-compatible) to the gateway endpoint"

        igw = softwareSystem "Gateway API Inference Extension" "Extends Envoy-based gateways with intelligent inference-aware routing, load balancing, and flow control for LLM serving workloads" {
            epp = container "Endpoint Picker (EPP)" "Core inference scheduling engine — intercepts Envoy requests via ext-proc, selects optimal model server endpoints using pluggable scheduling profiles, manages flow control with priority-based queuing" "Go gRPC Service" "ext-proc"
            bbr = container "Body Based Router (BBR)" "Parses HTTP request bodies to extract model names and LoRA adapter info, sets routing headers for gateway-level routing before EPP" "Go gRPC Service" "ext-proc"
            controllers = container "Controller Reconcilers" "Four reconcilers (InferencePool, InferenceObjective, InferenceModelRewrite, Pod) watch Kubernetes resources and maintain in-memory datastore" "Go (controller-runtime)"
            trainingServer = container "Latency Training Server" "Continuously trains XGBoost latency prediction models from live request telemetry" "Python FastAPI"
            predictionServer = container "Latency Prediction Server" "Serves XGBoost-based latency predictions for SLO-aware endpoint selection" "Python FastAPI"
        }

        envoyGateway = softwareSystem "Envoy-based Gateway" "Gateway API-compatible proxy supporting ext-proc (Istio, Envoy Gateway, kgateway, GKE Gateway)" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing API server, CRDs, RBAC, and pod scheduling" "External"
        modelServers = softwareSystem "Model Servers" "LLM inference servers (vLLM, SGLang, Triton TensorRT-LLM) exposing /metrics and serving predictions" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        gatewayAPICRDs = softwareSystem "Gateway API CRDs" "Gateway, HTTPRoute, and related CRDs for routing configuration" "External"

        # Relationships - External
        apiclient -> envoyGateway "Sends inference requests" "HTTP/80"
        envoyGateway -> bbr "Sends ext-proc stream (body parsing)" "gRPC/9004"
        envoyGateway -> epp "Sends ext-proc stream (endpoint selection)" "gRPC/9002"
        envoyGateway -> modelServers "Forwards requests to selected endpoint" "HTTP/8000"

        datascientist -> kubernetes "Creates InferencePool, InferenceObjective, InferenceModelRewrite CRs" "kubectl"
        platformadmin -> igw "Deploys and configures via Helm charts" "Helm"

        # Relationships - Internal
        epp -> modelServers "Scrapes /metrics for KV-cache, queue depth, running requests, LoRA adapters" "HTTP/8000"
        epp -> trainingServer "Submits observed latency training samples" "HTTP/8000"
        epp -> predictionServer "Fetches per-request TTFT/TPOT predictions" "HTTP/8001"
        controllers -> kubernetes "Watches InferencePool, InferenceObjective, InferenceModelRewrite CRDs and Pods" "HTTPS/443"
        bbr -> kubernetes "Watches ConfigMaps with bbr-managed label" "HTTPS/443"

        # Relationships - Optional
        prometheus -> epp "Scrapes metrics" "HTTP/9090"
        prometheus -> bbr "Scrapes metrics" "HTTP/9090"
        epp -> otelCollector "Exports distributed traces" "gRPC"
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
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "ext-proc" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

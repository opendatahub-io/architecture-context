workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries ML models via inference APIs"
        platformadmin = person "Platform Admin" "Configures InferencePool, routing rules, and SLO objectives"

        igw = softwareSystem "Gateway API Inference Extension" "KV-cache-aware intelligent routing and load balancing for generative AI model servers on Kubernetes" {
            epp = container "Endpoint Picker Provider (EPP)" "Core ext-proc server: watches CRDs, scrapes model server metrics, executes Filter/Score/Pick scheduling pipeline for endpoint selection" "Go gRPC Service" {
                tags "Primary"
            }
            bbr = container "Body Based Router (BBR)" "Optional ext-proc server: parses HTTP request bodies to extract model names into routing headers" "Go gRPC Service" {
                tags "Optional"
            }
            lpTraining = container "Latency Predictor Training" "Trains Bayesian Ridge/XGBoost/LightGBM models on observed TTFT/TPOT latency data" "Python ML Service" {
                tags "Optional"
            }
            lpPrediction = container "Latency Predictor Prediction" "Serves trained models for real-time TTFT/TPOT latency forecasting with uncertainty bounds" "Python ML Service" {
                tags "Optional"
            }
            asyncClient = container "Latency Predictor Async Client" "Sidecar that batches and coalesces latency prediction requests from EPP" "Go Sidecar" {
                tags "Optional"
            }
            loraSidecar = container "Dynamic LoRA Sidecar" "Watches ConfigMaps and reconciles vLLM LoRA adapter loading/unloading" "Python Sidecar" {
                tags "Optional"
            }
        }

        envoyGateway = softwareSystem "Envoy Gateway" "Gateway API-compatible proxy that routes inference traffic; calls ext-proc filters for routing decisions" "External"
        k8s = softwareSystem "Kubernetes" "Platform runtime providing API server, CRD storage, pod discovery, and RBAC" "External"
        modelServers = softwareSystem "Model Servers (vLLM / SGLang)" "Backend generative AI model servers exposing Prometheus metrics and serving inference" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otlp = softwareSystem "OpenTelemetry Collector" "Distributed tracing infrastructure" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API resources (Gateway, HTTPRoute) defining ingress topology" "Internal RHOAI"

        # Person interactions
        datascientist -> envoyGateway "Sends inference requests" "HTTPS/443"
        platformadmin -> k8s "Creates InferencePool, InferenceObjective, InferenceModelRewrite CRDs" "kubectl"

        # Gateway to ext-proc chain
        envoyGateway -> bbr "Sends ext-proc requests for body parsing" "gRPC/9004 TLS"
        envoyGateway -> epp "Sends ext-proc requests for endpoint selection" "gRPC/9002 TLS"
        envoyGateway -> modelServers "Forwards inference requests to selected endpoint" "HTTP/8000"

        # EPP interactions
        epp -> k8s "Watches CRDs (InferencePool, Pod, InferenceObjective, InferenceModelRewrite), updates status, manages leases" "HTTPS/443"
        epp -> modelServers "Scrapes Prometheus metrics (KV cache, queue depth, LoRA info)" "HTTP/configurable"
        epp -> prometheus "Exposes scheduling and pool metrics" "HTTP/9090"
        epp -> otlp "Exports distributed traces" "gRPC/4317"

        # BBR interactions
        bbr -> k8s "Watches labeled ConfigMaps for LoRA adapter mappings" "HTTPS/443"

        # Latency prediction
        asyncClient -> lpTraining "Sends training data" "HTTP/8000"
        asyncClient -> lpPrediction "Requests bulk TTFT/TPOT predictions" "HTTP/8000"

        # LoRA sidecar
        loraSidecar -> modelServers "Loads/unloads LoRA adapters via REST API" "HTTP/8000"

        # Gateway API reference
        gatewayAPI -> envoyGateway "Configures gateway routing via HTTPRoute/Gateway resources" ""
        gatewayAPI -> igw "InferencePool referenced as HTTPRoute backend" ""
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
            element "Internal RHOAI" {
                background #7ed321
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
            element "Primary" {
                background #1168bd
                color #ffffff
            }
            element "Optional" {
                background #6b9dc4
                color #ffffff
            }
        }
    }
}

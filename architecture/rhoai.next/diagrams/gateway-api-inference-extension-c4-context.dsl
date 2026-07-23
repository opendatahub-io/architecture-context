workspace {
    model {
        datascientist = person "Data Scientist" "Deploys ML models and creates InferencePool resources"
        mlEngineer = person "ML Engineer" "Configures inference routing, model rewrites, and priority objectives"
        client = person "API Client" "Sends inference requests to deployed models via gateway"

        inferenceExtension = softwareSystem "Gateway API Inference Extension" "Extends Envoy-based gateways with intelligent, KV-cache-aware load balancing for LLM inference" {
            epp = container "Endpoint Picker (EPP)" "Core scheduling engine; intercepts Envoy traffic via ext-proc, selects optimal model server endpoints using pluggable Filter/Scorer/Picker pipeline" "Go gRPC Service" {
                tags "Core"
            }
            bbr = container "Body Based Router (BBR)" "Optional body parser; extracts model name from JSON request body into routing headers for gateway-level routing" "Go gRPC Service" {
                tags "Optional"
            }
            trainingServer = container "Latency Predictor Training Server" "Collects latency observations and trains Bayesian Ridge / XGBoost / LightGBM models for TTFT/TPOT prediction" "Python FastAPI" {
                tags "Optional"
            }
            predictionServer = container "Latency Predictor Prediction Server" "Serves trained models for real-time latency predictions; supports bulk and strict-bulk endpoints" "Python FastAPI" {
                tags "Optional"
            }
            asyncClient = container "Latency Predictor Async Client" "Async Go client for latency prediction servers; runs as EPP sidecar with request coalescing" "Go Sidecar" {
                tags "Optional"
            }
            clientGo = container "client-go" "Generated Kubernetes client, informers, and listers for InferencePool, InferenceObjective, InferenceModelRewrite CRDs" "Go Library" {
                tags "Library"
            }
        }

        envoyGateway = softwareSystem "Envoy-based Gateway" "Gateway API-compatible proxy (Envoy Gateway, Istio, GKE Gateway, kgateway) that routes inference traffic" "External" {
            tags "External"
        }
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for CRD management, Pod discovery, and leader election" "External" {
            tags "External"
        }
        modelServers = softwareSystem "Model Servers" "LLM model serving backends (vLLM, SGLang, Triton TensorRT-LLM, trtllm-serve) exposing Prometheus metrics" "External" {
            tags "External"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring system" "External" {
            tags "External"
        }
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend for OTLP trace export" "External" {
            tags "External"
        }
        llmd = softwareSystem "llm-d Inference Scheduler" "External scheduler plugin for disaggregated vLLM serving" "Internal RHOAI" {
            tags "Internal"
        }

        # Person interactions
        datascientist -> inferenceExtension "Creates InferencePool CRDs via kubectl"
        mlEngineer -> inferenceExtension "Configures InferenceObjective, InferenceModelRewrite, EndpointPickerConfig"
        client -> envoyGateway "Sends inference requests" "HTTPS/443"

        # System context
        envoyGateway -> inferenceExtension "Sends traffic through ext-proc filter chain" "gRPC/9002, 9004"
        inferenceExtension -> envoyGateway "Returns endpoint selection and header mutations" "gRPC response"
        envoyGateway -> modelServers "Forwards requests to selected model server pods" "HTTP/8000"
        inferenceExtension -> modelServers "Scrapes Prometheus /metrics for scheduling decisions" "HTTP/8000"
        inferenceExtension -> k8sAPI "Watches Pods, InferencePool, InferenceObjective, InferenceModelRewrite CRDs, Leases" "HTTPS/443"
        inferenceExtension -> otelCollector "Exports distributed traces" "gRPC OTLP/4317"
        prometheus -> inferenceExtension "Scrapes /metrics endpoint" "HTTP/9090"
        llmd -> inferenceExtension "Integrates via pluggable EPP scheduling framework" "Plugin API"

        # Container interactions
        epp -> clientGo "Uses for CRD watches and informers"
        epp -> asyncClient "Delegates latency prediction requests"
        asyncClient -> trainingServer "Submits training data" "HTTP/8000"
        asyncClient -> predictionServer "Requests TTFT/TPOT predictions" "HTTP/8001"
        predictionServer -> trainingServer "Fetches trained model coefficients" "HTTP/8000"
    }

    views {
        systemContext inferenceExtension "SystemContext" {
            include *
            autoLayout
        }

        container inferenceExtension "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Core" {
                background #4a90e2
                color #ffffff
            }
            element "Optional" {
                background #9b59b6
                color #ffffff
            }
            element "Library" {
                background #95a5a6
                color #ffffff
            }
            relationship "Relationship" {
                thickness 2
            }
        }
    }
}

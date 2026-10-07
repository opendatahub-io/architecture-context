workspace {
    model {
        user = person "ML Engineer / Application Developer" "Sends inference requests to LLM models hosted on Kubernetes"

        igw = softwareSystem "Gateway API Inference Extension" "Extends Gateway API-compatible proxies with KV-cache-aware, LoRA-adapter-aware request scheduling for Kubernetes-hosted LLM serving" {
            epp = container "Endpoint Picker (EPP)" "Core ext-proc gRPC server: pluggable scheduling pipeline with filter/score/pick, flow control, and real-time metrics-driven endpoint selection" "Go gRPC Service" {
                tags "Primary"
            }
            bbr = container "Body Based Router (BBR)" "Optional ext-proc gRPC server: parses HTTP request bodies to extract model names into headers for gateway routing" "Go gRPC Service"
            poolController = container "InferencePool Controller" "Reconciles InferencePool CRDs to configure endpoint discovery and pool membership" "Go Controller"
            objectiveController = container "InferenceObjective Controller" "Reconciles InferenceObjective CRDs for SLO-driven priority-based scheduling" "Go Controller"
            rewriteController = container "InferenceModelRewrite Controller" "Reconciles InferenceModelRewrite CRDs for model name aliasing" "Go Controller"
            podController = container "Pod Controller" "Watches Pods matching InferencePool selectors to maintain endpoint datastore" "Go Controller"
            dataLayer = container "Data Layer" "Scrapes Prometheus metrics from model server pods at configurable intervals (default 50ms)" "Go Component"
            latencyPredictor = container "Latency Predictor" "Optional ML sidecar providing XGBoost-based latency estimation for scheduling" "Python Service" {
                tags "Optional"
            }
        }

        envoyGateway = softwareSystem "Envoy Gateway" "Gateway API-compatible proxy providing ext-proc filter chain for request interception" "External"
        modelServers = softwareSystem "Model Serving Infrastructure" "LLM model servers (vLLM, SGLang) hosting inference endpoints with Prometheus metrics" "External"
        kubernetes = softwareSystem "Kubernetes API" "Cluster control plane for resource management and CRD reconciliation" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring via ServiceMonitor" "External"
        otlp = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend" "External"

        # System-level relationships
        user -> envoyGateway "Sends inference requests" "HTTPS/443"
        envoyGateway -> igw "ext-proc callouts for routing decisions" "gRPC/9002, 9004 TLS"
        envoyGateway -> modelServers "Forwards routed requests to selected endpoint"
        igw -> modelServers "Scrapes Prometheus metrics" "HTTP(S)"
        igw -> kubernetes "Watches CRDs and Pods" "HTTPS/6443"
        igw -> otlp "Exports traces" "gRPC/4317"
        prometheus -> igw "Scrapes operational metrics" "HTTP/9090"

        # Container-level relationships
        envoyGateway -> bbr "ext-proc body parsing" "gRPC/9004 TLS"
        envoyGateway -> epp "ext-proc endpoint selection" "gRPC/9002 TLS"
        bbr -> envoyGateway "Returns model name header mutation" "gRPC response"
        epp -> envoyGateway "Returns selected endpoint address" "gRPC response"
        dataLayer -> modelServers "Scrapes /metrics every 50ms" "HTTP(S)"
        latencyPredictor -> epp "Provides latency predictions" "HTTP/8001"
        poolController -> dataLayer "Configures endpoint pool"
        podController -> dataLayer "Updates endpoint list"
        objectiveController -> epp "Configures SLO priorities"
        rewriteController -> epp "Configures model aliases"
        poolController -> kubernetes "Watches InferencePool" "HTTPS/6443"
        objectiveController -> kubernetes "Watches InferenceObjective" "HTTPS/6443"
        rewriteController -> kubernetes "Watches InferenceModelRewrite" "HTTPS/6443"
        podController -> kubernetes "Watches Pods" "HTTPS/6443"
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
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
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
                background #85bbf0
                color #000000
                border dashed
            }
        }
    }
}

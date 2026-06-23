workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and manages inference workloads via InferencePool CRDs"
        platformadmin = person "Platform Admin" "Configures gateway routing, priority objectives, and model rewrites"

        gie = softwareSystem "Gateway API Inference Extension" "Provides intelligent request routing for LLM inference workloads via Envoy ext-proc protocol" {
            epp = container "Endpoint Picker Proxy (EPP)" "Intercepts inference requests, evaluates backend metrics, schedules requests to optimal endpoints using pluggable framework" "Go gRPC Service (ext-proc)" {
                scheduler = component "Scheduling Framework" "Filter → Score → Pick pipeline for endpoint selection" "Go"
                director = component "Director" "Model rewriting with weighted traffic splitting" "Go"
                flowcontrol = component "Flow Control Layer" "Priority queuing, admission control, saturation detection" "Go"
                datalayer = component "Data Layer" "Metrics collection from model servers, endpoint state management" "Go"
            }
            bbr = container "Body-Based Router (BBR)" "Extracts request body fields and injects as HTTP headers for routing" "Go gRPC Service (ext-proc)"
            trainingserver = container "Latency Training Server" "Trains latency prediction models (Bayesian Ridge, XGBoost, LightGBM)" "Python FastAPI" "Optional Sidecar"
            predictionserver = container "Latency Prediction Server" "Serves trained models for real-time TTFT/TPOT estimation" "Python FastAPI" "Optional Sidecar"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform with CRD support" "External" {
            apiserver = container "API Server" "REST API for cluster management and CRD watches" "Kubernetes"
        }

        gateway = softwareSystem "Envoy-based Gateway" "Gateway API-compatible ingress (Envoy Gateway, Istio, GKE, nginx Gateway Fabric)" "External"
        modelservers = softwareSystem "Model Servers" "LLM inference serving (vLLM, SGLang, TensorRT-LLM, trtllm-serve)" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otlpcollector = softwareSystem "OTLP Collector" "OpenTelemetry trace collection" "External"

        # User interactions
        datascientist -> gie "Creates InferencePool, deploys model servers"
        platformadmin -> gie "Configures InferenceObjective, InferenceModelRewrite CRDs"

        # Client flow
        gateway -> epp "gRPC ext-proc bidirectional stream" "gRPC/9002 TLS"
        gateway -> bbr "gRPC ext-proc bidirectional stream" "gRPC/9004 TLS"
        epp -> gateway "Returns routing decisions with target endpoint"
        bbr -> gateway "Returns header mutations from body field extraction"
        gateway -> modelservers "Forwards inference requests" "HTTP/gRPC"

        # EPP dependencies
        epp -> apiserver "Watches InferencePool, InferenceObjective, InferenceModelRewrite, Pods" "HTTPS/443"
        epp -> modelservers "Scrapes Prometheus metrics for scheduling" "HTTP (configurable)"
        epp -> trainingserver "Submits training data" "HTTP/8000"
        epp -> predictionserver "Gets TTFT/TPOT predictions" "HTTP/8001"
        trainingserver -> predictionserver "Shares trained models" "Shared volume"

        # BBR dependencies
        bbr -> apiserver "Watches ConfigMaps (LoRA adapter mappings)" "HTTPS/443"

        # Observability
        prometheus -> epp "Scrapes operational metrics" "HTTP/9090"
        prometheus -> bbr "Scrapes operational metrics" "HTTP/9090"
        epp -> otlpcollector "Exports distributed traces" "gRPC/4317"
        bbr -> otlpcollector "Exports distributed traces" "gRPC/4317"
    }

    views {
        systemContext gie "SystemContext" {
            include *
            autoLayout
        }

        container gie "Containers" {
            include *
            autoLayout
        }

        component epp "EPPComponents" {
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
                color #000000
            }
            element "Optional Sidecar" {
                background #fff2cc
                color #000000
                border dashed
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5b9bd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

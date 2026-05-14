workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and queries ML models via inference endpoints"
        platformadmin = person "Platform Admin" "Configures InferencePool, routing rules, and gateway policies"

        igw = softwareSystem "Gateway API Inference Extension" "Extends Gateway API proxies with intelligent, KV-cache-aware endpoint selection for inference workloads" {
            epp = container "Endpoint Picker (EPP)" "Envoy ext-proc server performing intelligent endpoint selection using scheduling plugins, flow control, and model server metrics" "Go gRPC Service" {
                scheduler = component "Scheduling Pipeline" "Filter → Score → Pick pipeline with pluggable plugins" "Go"
                flowcontrol = component "Flow Control" "JSQ-Bytes distribution with priority queuing, fairness, and eviction" "Go"
                datastore = component "In-Memory Datastore" "Stores endpoint metadata, model mappings, and scraped metrics" "Go"
                datalayer = component "Data Layer" "Source/Extractor pattern for metrics collection from model servers" "Go"
                grpcserver = component "gRPC ext-proc Server" "Envoy External Processor service handling request/response streams" "Go gRPC"
            }

            bbr = container "Body-Based Router (BBR)" "Envoy ext-proc server parsing request bodies for model name extraction and LoRA adapter resolution" "Go gRPC Service"

            trainingserver = container "Latency Training Server" "Trains latency prediction models (XGBoost/LightGBM) from inference telemetry" "Python Service" "Optional"

            predictionserver = container "Latency Prediction Server" "Serves TTFT/TPOT latency predictions via HTTP API" "Python Service" "Optional"
        }

        gateway = softwareSystem "Envoy-Compatible Gateway" "Gateway API proxy (Envoy Gateway, kgateway, Istio, GKE Gateway) routing inference traffic" "External"
        k8s = softwareSystem "Kubernetes" "Container orchestration platform providing API server, RBAC, CRDs, and Pod management" "External"
        modelservers = softwareSystem "Model Servers" "ML inference servers (vLLM, SGLang, Triton TensorRT-LLM) serving trained models" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring system" "External"
        otlp = softwareSystem "OpenTelemetry Collector" "Distributed trace collection and export" "External"

        # Person interactions
        datascientist -> gateway "Sends inference requests" "HTTPS/443"
        platformadmin -> k8s "Creates InferencePool, InferenceObjective, InferenceModelRewrite CRDs" "kubectl/HTTPS"

        # Gateway → IGW
        gateway -> epp "Delegates endpoint selection via ext-proc" "gRPC/9002 TLS"
        gateway -> bbr "Delegates body parsing via ext-proc" "gRPC/9004 TLS"
        gateway -> modelservers "Forwards inference requests to selected endpoint" "HTTP/gRPC"

        # IGW → External
        epp -> k8s "Watches CRDs (InferencePool, InferenceObjective, InferenceModelRewrite), Pods, Leases" "HTTPS/443"
        epp -> modelservers "Scrapes Prometheus metrics (KV cache, queue, LoRA)" "HTTP/configurable"
        epp -> trainingserver "Submits training data" "HTTP/8000"
        epp -> predictionserver "Queries latency predictions" "HTTP/8001+"
        epp -> otlp "Exports distributed traces" "gRPC/4317"
        bbr -> k8s "Watches ConfigMaps (bbr-managed)" "HTTPS/443"

        # Monitoring
        prometheus -> epp "Scrapes EPP metrics" "HTTP/9090"
        prometheus -> bbr "Scrapes BBR metrics" "HTTP/9090"
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

        component epp "EPP-Components" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Optional" {
                background #9b59b6
                color #ffffff
                opacity 75
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

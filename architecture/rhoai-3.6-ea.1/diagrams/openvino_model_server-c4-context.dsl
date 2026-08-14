workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and queries ML models for inference"

        ovms = softwareSystem "OpenVINO Model Server (OVMS)" "High-performance C++ inference server supporting TFS V1, KServe V2, and OpenAI V3 APIs" {
            inferenceEngine = container "OVMS Inference Engine" "Loads and serves ML models via REST and gRPC" "C++ Binary (/ovms/bin/ovms)"
            restHandler = container "HTTP REST API Handler" "Routes requests to TFS V1, KServe V2, OpenAI V3 protocol handlers" "C++ Handler"
            grpcService = container "gRPC Inference Service" "Provides ModelInfer, ModelStreamInfer, health, and metadata RPCs" "C++ gRPC Service"
            nginxSidecar = container "nginx-mtls-auth Sidecar" "Optional TLS 1.2 reverse proxy with mutual client certificate authentication" "nginx" "Optional"
        }

        kserve = softwareSystem "KServe" "Manages OVMS pods via ServingRuntime/ClusterServingRuntime CRDs" "Internal RHOAI"
        modelStorage = softwareSystem "Model Storage" "S3, PVC, or other KServe-supported storage backends for ML model artifacts" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Optional service mesh providing traffic management and mTLS" "Internal RHOAI"

        user -> ovms "Sends inference requests via REST or gRPC"
        kserve -> ovms "Deploys and manages via ServingRuntime CRDs"
        ovms -> modelStorage "Loads model artifacts from /mnt/models" "Filesystem / Volume Mount"
        prometheus -> ovms "Scrapes /metrics endpoint" "HTTP/8888"
        ovms -> istio "Optional: traffic routing and mTLS" "Service Mesh"

        inferenceEngine -> restHandler "Dispatches HTTP requests"
        inferenceEngine -> grpcService "Dispatches gRPC requests"
        nginxSidecar -> inferenceEngine "Proxies traffic on loopback" "HTTP/gRPC"
    }

    views {
        systemContext ovms "SystemContext" {
            include *
            autoLayout
        }

        container ovms "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Optional" {
                background #f5a623
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
        }
    }
}

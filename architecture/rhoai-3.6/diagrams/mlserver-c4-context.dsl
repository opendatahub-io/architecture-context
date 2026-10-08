workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models via KServe InferenceService"
        sre = person "SRE / Platform Admin" "Monitors inference services and metrics"

        mlserver = softwareSystem "MLServer" "Python-based inference server implementing KServe V2 Inference Protocol with REST and gRPC APIs" {
            restServer = container "REST Server" "V2 Inference Protocol REST endpoints" "FastAPI + uvicorn" "Server"
            grpcServer = container "gRPC Server" "V2 Inference Protocol gRPC service" "grpc.aio" "Server"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint" "starlette-exporter" "Server"
            dataPlane = container "DataPlane Handler" "Routes inference requests, manages batching" "Python" "Handler"
            modelRegistry = container "Model Registry" "Discovers and manages loaded model runtimes" "Python" "Handler"
            runtimeSecurity = container "Runtime Security" "Enforces trusted runtimes allowlist in PRODUCTION mode" "Python" "Security"
            sklearnRuntime = container "sklearn Runtime" "Scikit-Learn model serving" "Python" "Runtime"
            xgboostRuntime = container "XGBoost Runtime" "XGBoost model serving" "Python" "Runtime"
            lightgbmRuntime = container "LightGBM Runtime" "LightGBM model serving" "Python" "Runtime"
            onnxRuntime = container "ONNX Runtime" "ONNX model serving (CPU/CUDA)" "Python" "Runtime"
            mlflowRuntime = container "MLflow Runtime" "MLflow model serving" "Python" "Runtime"
            hfRuntime = container "HuggingFace Runtime" "HuggingFace Transformers model serving" "Python" "Runtime"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle and pod deployment" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Sidecar for OpenShift OAuth/SA token validation" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform"
        otlpCollector = softwareSystem "OTLP Collector" "Distributed tracing collection" "Platform"
        kafka = softwareSystem "Kafka" "Async inference message bus (optional)" "External"
        modelStorage = softwareSystem "Model Storage" "PVC or S3 storage for model artifacts" "External"

        # External relationships
        dataScientist -> mlserver "Sends inference requests via" "REST/gRPC"
        sre -> prometheus "Monitors via"

        # Platform relationships
        kserve -> mlserver "Manages pod lifecycle" "Kubernetes API"
        kubeRBACProxy -> mlserver "Proxies authenticated requests to" "HTTP/gRPC (pod-local)"
        dataScientist -> kubeRBACProxy "Authenticates via" "OAuth/SA Token"
        prometheus -> mlserver "Scrapes metrics from" "HTTP/8082"
        mlserver -> otlpCollector "Exports traces to" "gRPC (insecure)"
        mlserver -> kafka "Sends/receives async inference via" "TCP/9092"
        mlserver -> modelStorage "Loads model artifacts from" "Filesystem/S3"

        # Internal relationships
        restServer -> dataPlane "Routes requests to"
        grpcServer -> dataPlane "Routes requests to"
        dataPlane -> modelRegistry "Looks up models in"
        modelRegistry -> runtimeSecurity "Validates implementations via"
        modelRegistry -> sklearnRuntime "Dispatches to"
        modelRegistry -> xgboostRuntime "Dispatches to"
        modelRegistry -> lightgbmRuntime "Dispatches to"
        modelRegistry -> onnxRuntime "Dispatches to"
        modelRegistry -> mlflowRuntime "Dispatches to"
        modelRegistry -> hfRuntime "Dispatches to"
    }

    views {
        systemContext mlserver "SystemContext" {
            include *
            autoLayout
        }

        container mlserver "Containers" {
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
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #f5a623
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Server" {
                background #4a90e2
                color #ffffff
            }
            element "Handler" {
                background #5ba3f5
                color #ffffff
            }
            element "Security" {
                background #e74c3c
                color #ffffff
            }
            element "Runtime" {
                background #7ed321
                color #ffffff
            }
        }
    }
}

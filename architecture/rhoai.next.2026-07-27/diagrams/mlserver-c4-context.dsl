workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for inference"
        mlEngineer = person "ML Engineer" "Configures runtimes and manages model serving"

        mlserver = softwareSystem "MLServer" "Python-based ML inference server implementing V2 Inference Protocol over gRPC and REST with 10 pluggable runtime backends" {
            grpcServer = container "gRPC Server" "Implements GRPCInferenceService (11 RPCs) and ModelRepositoryService (3 RPCs) with interceptor chain" "Python grpcio async"
            restServer = container "REST API" "V2 Inference Protocol REST endpoints" "Python FastAPI/uvicorn"
            interceptorChain = container "Interceptor Chain" "LoggingInterceptor, PromServerInterceptor, OpenTelemetry tracing" "Python gRPC interceptors"
            runtimeSklearn = container "sklearn Runtime" "Scikit-Learn model serving" "Python Package"
            runtimeXgboost = container "XGBoost Runtime" "XGBoost model serving" "Python Package"
            runtimeLightgbm = container "LightGBM Runtime" "LightGBM model serving" "Python Package"
            runtimeOnnx = container "ONNX Runtime" "ONNX model serving (CPU/CUDA)" "Python Package"
            runtimeMlflow = container "MLflow Runtime" "MLflow model serving" "Python Package"
            runtimeHuggingface = container "HuggingFace Runtime" "HuggingFace model serving" "Python Package"
            runtimeAlibiDetect = container "Alibi-Detect Runtime" "Outlier/drift detection" "Python Package"
            runtimeAlibiExplain = container "Alibi-Explain Runtime" "Model explainability" "Python Package"
            runtimeCatboost = container "CatBoost Runtime" "CatBoost model serving" "Python Package"
            runtimeMllib = container "Spark MLlib Runtime" "Spark MLlib model serving" "Python Package"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar proxy for authentication and authorization" "Platform"
        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle and model serving pods" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform"
        otlpCollector = softwareSystem "OTLP Collector" "Distributed trace collection" "External"
        kafka = softwareSystem "Kafka" "Message streaming platform" "External"
        triton = softwareSystem "Triton Inference Server" "Protocol-compatible inference server" "External"

        # User interactions
        dataScientist -> mlserver "Sends inference requests" "gRPC/REST via kube-rbac-proxy"
        mlEngineer -> mlserver "Manages model lifecycle" "gRPC ModelRepositoryService"

        # Platform interactions
        kubeRbacProxy -> mlserver "Forwards authenticated requests" "gRPC (insecure, pod-internal)"
        kserve -> mlserver "Deploys and manages" "Kubernetes"

        # Egress
        mlserver -> prometheus "Exposes metrics" "HTTP /metrics"
        mlserver -> otlpCollector "Exports traces" "gRPC OTLP"
        mlserver -> kafka "Publishes events" "Kafka protocol (aiokafka)"
        mlserver -> triton "Protocol compatibility" "HTTP (tritonclient)"

        # Internal container relationships
        grpcServer -> interceptorChain "Processes requests through"
        interceptorChain -> runtimeSklearn "Dispatches to"
        interceptorChain -> runtimeXgboost "Dispatches to"
        interceptorChain -> runtimeLightgbm "Dispatches to"
        interceptorChain -> runtimeOnnx "Dispatches to"
        interceptorChain -> runtimeMlflow "Dispatches to"
        interceptorChain -> runtimeHuggingface "Dispatches to"
        interceptorChain -> runtimeAlibiDetect "Dispatches to"
        interceptorChain -> runtimeAlibiExplain "Dispatches to"
        interceptorChain -> runtimeCatboost "Dispatches to"
        interceptorChain -> runtimeMllib "Dispatches to"
        restServer -> runtimeSklearn "Dispatches to"
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
            element "Software System" {
                background #4a90e2
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
            element "Platform" {
                background #999999
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
        }
    }
}

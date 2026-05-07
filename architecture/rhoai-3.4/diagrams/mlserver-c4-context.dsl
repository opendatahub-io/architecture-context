workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and runtimes"

        mlserver = softwareSystem "MLServer" "Python-based inference server implementing V2 Inference Protocol (Open Inference Protocol) for serving ML models over REST and gRPC" {
            restServer = container "REST Server" "FastAPI/Uvicorn HTTP server implementing V2 Inference Protocol endpoints" "Python (FastAPI)" "WebBrowser"
            grpcServer = container "gRPC Server" "gRPC server implementing V2 Inference Protocol RPCs" "Python (grpc.aio)"
            metricsServer = container "Metrics Server" "Dedicated Prometheus metrics HTTP server" "Python (Uvicorn)"
            dataPlane = container "DataPlane" "Central handler implementing all inference and metadata operations independent of transport" "Python"
            modelRegistry = container "Model Registry" "Model lifecycle management - load, unload, readiness tracking" "Python"
            inferencePool = container "Inference Pool" "Parallel inference via multiprocessing workers to bypass Python GIL" "Python (multiprocessing)"
            sklearnRuntime = container "sklearn Runtime" "Scikit-learn model serving (scikit-learn 1.8.0)" "Python Plugin"
            xgboostRuntime = container "XGBoost Runtime" "XGBoost model serving (XGBoost 3.2.0)" "Python Plugin"
            lightgbmRuntime = container "LightGBM Runtime" "LightGBM model serving (LightGBM 4.6.0)" "Python Plugin"
            onnxRuntime = container "ONNX Runtime" "ONNX model serving (onnxruntime 1.24.4)" "Python Plugin"
            trustedRuntimes = container "Trusted Runtimes Allowlist" "Security mechanism restricting loadable model implementations in production" "JSON Config"
            kafkaServer = container "Kafka Server" "Optional async Kafka consumer/producer for event-driven inference" "Python (aiokafka)"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform that manages InferenceService lifecycle" "External"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization sidecar enforcing Kubernetes RBAC" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring system that scrapes metrics" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing data collection and export" "External"
        kafkaBroker = softwareSystem "Kafka" "Message broker for event-driven inference" "External"
        modelStorage = softwareSystem "Model Storage" "PVC, S3, or ModelCar providing model artifacts at /mnt/models" "External"

        # User interactions
        dataScientist -> kserve "Creates InferenceService CR via kubectl/dashboard"
        mlEngineer -> kserve "Configures ServingRuntime CR referencing MLServer image"

        # KServe deploys MLServer
        kserve -> mlserver "Deploys as inference container within InferenceService pod"

        # External client flow
        dataScientist -> kubeRbacProxy "Sends inference requests" "HTTPS/443, Bearer Token"
        kubeRbacProxy -> restServer "Proxies authenticated requests" "HTTP/8080"
        kubeRbacProxy -> grpcServer "Proxies authenticated requests" "gRPC/8081"

        # Internal flows
        restServer -> dataPlane "Delegates inference/metadata calls"
        grpcServer -> dataPlane "Delegates inference/metadata calls"
        kafkaServer -> dataPlane "Delegates event-driven inference"
        dataPlane -> modelRegistry "Loads/invokes models"
        modelRegistry -> trustedRuntimes "Validates implementation against allowlist"
        dataPlane -> inferencePool "Dispatches parallel inference requests"
        modelRegistry -> sklearnRuntime "Manages sklearn models"
        modelRegistry -> xgboostRuntime "Manages XGBoost models"
        modelRegistry -> lightgbmRuntime "Manages LightGBM models"
        modelRegistry -> onnxRuntime "Manages ONNX models"

        # External integrations
        modelStorage -> modelRegistry "Provides model artifacts" "Filesystem (/mnt/models)"
        prometheus -> metricsServer "Scrapes metrics" "HTTP/8082"
        restServer -> otelCollector "Exports traces" "gRPC (OTLP, insecure)"
        grpcServer -> otelCollector "Exports traces" "gRPC (OTLP, insecure)"
        kafkaServer -> kafkaBroker "Consumes/produces messages" "TCP/9092"
    }

    views {
        systemContext mlserver "SystemContext" {
            include *
            autoLayout
            description "MLServer in the context of RHOAI platform"
        }

        container mlserver "Containers" {
            include *
            autoLayout
            description "Internal structure of MLServer inference server"
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
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "WebBrowser" {
                shape WebBrowser
            }
        }
    }
}

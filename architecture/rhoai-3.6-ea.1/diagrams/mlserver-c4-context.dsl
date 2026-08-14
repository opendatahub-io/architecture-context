workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models via KServe InferenceService"
        application = person "Application" "Sends inference requests to deployed models"

        mlserver = softwareSystem "MLServer" "Python-based model serving runtime implementing KServe V2 Inference Protocol with REST and gRPC endpoints" {
            restServer = container "REST Server" "Serves V2 Inference Protocol via HTTP endpoints" "FastAPI/Uvicorn, Port 8080"
            grpcServer = container "gRPC Server" "Serves V2 Inference Protocol via gRPC services" "gRPC AsyncIO, Port 8081"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics" "starlette-exporter, Port 8082"
            dataPlane = container "DataPlane Handler" "Routes inference requests to appropriate ML runtime" "Python"
            modelRepository = container "Model Repository" "Manages model loading/unloading from filesystem" "Python, /mnt/models"
            trustedRuntimes = container "Trusted Runtimes Allowlist" "Enforces which ML runtime implementations can be loaded" "JSON config, /etc/mlserver/trusted-runtimes.json"

            sklearnRuntime = container "SKLearn Runtime" "Scikit-Learn model serving" "mlserver-sklearn"
            xgboostRuntime = container "XGBoost Runtime" "XGBoost model serving" "mlserver-xgboost"
            lightgbmRuntime = container "LightGBM Runtime" "LightGBM model serving" "mlserver-lightgbm"
            onnxRuntime = container "ONNX Runtime" "ONNX model serving" "mlserver-onnx"
            mlflowRuntime = container "MLflow Runtime" "MLflow model serving" "mlserver-mlflow"
            huggingfaceRuntime = container "HuggingFace Runtime" "HuggingFace model serving" "mlserver-huggingface"
            catboostRuntime = container "CatBoost Runtime" "CatBoost model serving" "mlserver-catboost"
            alibiDetectRuntime = container "Alibi Detect Runtime" "Alibi Detect outlier/drift detection" "mlserver-alibi-detect"
            alibiExplainRuntime = container "Alibi Explain Runtime" "Alibi Explain model explanations" "mlserver-alibi-explain"
            mllibRuntime = container "MLlib Runtime" "Spark MLlib model serving" "mlserver-mllib"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle and ingress routing" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar enforcing OpenShift OAuth/ServiceAccount token authentication" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        modelStorage = softwareSystem "Model Storage" "Persistent storage for ML model artifacts (PVC/S3)" "External"

        # System Context relationships
        application -> mlserver "Sends inference requests" "REST/gRPC via KServe ingress"
        dataScientist -> kserve "Deploys InferenceService" "kubectl/oc"
        kserve -> mlserver "Routes inference traffic, manages pod lifecycle"
        kubeRbacProxy -> mlserver "Proxies authenticated requests" "HTTP/8080, gRPC/8081"
        prometheus -> mlserver "Scrapes metrics" "HTTP/8082"
        mlserver -> otelCollector "Exports traces" "gRPC OTLP"
        mlserver -> modelStorage "Reads model artifacts" "Filesystem mount"

        # Container relationships
        restServer -> dataPlane "Delegates V2 requests"
        grpcServer -> dataPlane "Delegates V2 requests"
        dataPlane -> trustedRuntimes "Validates runtime"
        dataPlane -> modelRepository "Load/unload models"
        dataPlane -> sklearnRuntime "Routes SKLearn inference"
        dataPlane -> xgboostRuntime "Routes XGBoost inference"
        dataPlane -> lightgbmRuntime "Routes LightGBM inference"
        dataPlane -> onnxRuntime "Routes ONNX inference"
        dataPlane -> mlflowRuntime "Routes MLflow inference"
        dataPlane -> huggingfaceRuntime "Routes HuggingFace inference"
        dataPlane -> catboostRuntime "Routes CatBoost inference"
        dataPlane -> alibiDetectRuntime "Routes Alibi Detect inference"
        dataPlane -> alibiExplainRuntime "Routes Alibi Explain inference"
        dataPlane -> mllibRuntime "Routes MLlib inference"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #438dd5
                color #ffffff
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
        }
    }
}

workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models for inference"
        sre = person "SRE / Platform Admin" "Monitors and manages the inference platform"

        mlserver = softwareSystem "MLServer" "Multi-protocol ML inference server implementing V2 Inference Protocol with pluggable runtime adapters" {
            restServer = container "REST Server" "V2 Inference Protocol HTTP endpoints (infer, generate, stream)" "FastAPI/uvicorn, 8080/TCP"
            grpcServer = container "gRPC Server" "V2 Inference Protocol gRPC endpoints (ModelInfer, ModelStreamInfer)" "grpc.aio, 8081/TCP"
            kafkaServer = container "Kafka Server" "Optional message-based inference transport" "aiokafka, 9092/TCP"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint with MultiProcessCollector" "starlette-exporter, 8082/TCP"
            dataPlane = container "DataPlane" "Core inference pipeline: middleware → cache → adaptive batching → model dispatch" "Python"
            modelRegistry = container "Model Registry" "In-memory registry of loaded models and their runtimes" "Python"
            parallelWorkers = container "Parallel Workers" "Multi-process inference for GIL bypass (configurable)" "multiprocessing"
            runtimeSecurity = container "Runtime Security" "Trusted runtimes allowlist, CORS restrictions, environment blocking" "Python"

            restServer -> dataPlane "Routes REST requests"
            grpcServer -> dataPlane "Routes gRPC requests"
            kafkaServer -> dataPlane "Routes Kafka messages"
            dataPlane -> modelRegistry "Dispatches to loaded models"
            modelRegistry -> parallelWorkers "Distributes to workers"
            dataPlane -> runtimeSecurity "Validates runtime loading"
        }

        sklearnRuntime = softwareSystem "mlserver-sklearn" "Scikit-learn model serving runtime" "Runtime Plugin"
        xgboostRuntime = softwareSystem "mlserver-xgboost" "XGBoost model serving runtime" "Runtime Plugin"
        lightgbmRuntime = softwareSystem "mlserver-lightgbm" "LightGBM model serving runtime" "Runtime Plugin"
        onnxRuntime = softwareSystem "mlserver-onnx" "ONNX Runtime model serving (CPU/CUDA)" "Runtime Plugin"
        huggingfaceRuntime = softwareSystem "mlserver-huggingface" "HuggingFace Transformers runtime" "Runtime Plugin"
        mlflowRuntime = softwareSystem "mlserver-mlflow" "MLflow model serving runtime" "Runtime Plugin"
        alibiExplainRuntime = softwareSystem "mlserver-alibi-explain" "Model explainability runtime" "Runtime Plugin"
        alibiDetectRuntime = softwareSystem "mlserver-alibi-detect" "Drift and outlier detection runtime" "Runtime Plugin"

        kserve = softwareSystem "KServe" "Kubernetes inference platform — manages InferenceService pods, ingress, auth" "External Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection and export" "External"
        kafka = softwareSystem "Apache Kafka" "Message broker for optional inference transport" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        modelStorage = softwareSystem "Model Storage" "Model artifacts on /mnt/models (PVC or init container)" "External"
        aipccBaseImages = softwareSystem "AIPCC Base Images" "RHEL 9.6 UBI base images (CPU and CUDA variants)" "Internal Platform"

        datascientist -> kserve "Creates InferenceService via kubectl/dashboard"
        kserve -> mlserver "Routes inference requests to MLServer container" "HTTP/8080, gRPC/8081"
        mlserver -> otelCollector "Exports distributed traces" "gRPC OTLP"
        mlserver -> kafka "Optional message transport" "TCP/9092"
        prometheus -> mlserver "Scrapes metrics" "HTTP/8082"
        mlserver -> modelStorage "Reads model artifacts" "filesystem /mnt/models"
        sre -> prometheus "Monitors inference metrics"
        sre -> otelCollector "Reviews distributed traces"

        mlserver -> sklearnRuntime "Loads runtime"
        mlserver -> xgboostRuntime "Loads runtime"
        mlserver -> lightgbmRuntime "Loads runtime"
        mlserver -> onnxRuntime "Loads runtime"
        mlserver -> huggingfaceRuntime "Loads runtime"
        mlserver -> mlflowRuntime "Loads runtime"
        mlserver -> alibiExplainRuntime "Loads runtime"
        mlserver -> alibiDetectRuntime "Loads runtime"
    }

    views {
        systemContext mlserver "SystemContext" {
            include *
            exclude sklearnRuntime xgboostRuntime lightgbmRuntime onnxRuntime huggingfaceRuntime mlflowRuntime alibiExplainRuntime alibiDetectRuntime
            autoLayout
        }

        container mlserver "Containers" {
            include *
            exclude sklearnRuntime xgboostRuntime lightgbmRuntime onnxRuntime huggingfaceRuntime mlflowRuntime alibiExplainRuntime alibiDetectRuntime
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Platform" {
                background #f5a623
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Runtime Plugin" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

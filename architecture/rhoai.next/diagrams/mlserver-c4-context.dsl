workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models and sends inference requests via REST/gRPC"

        mlserver = softwareSystem "MLServer" "Python-based multi-model inference server implementing KServe v2 dataplane protocol" {
            restServer = container "REST Server" "KServe v2 REST dataplane with OpenAPI docs and Swagger UI" "FastAPI/Uvicorn, Port 8080"
            grpcServer = container "gRPC Server" "KServe v2 gRPC dataplane with bidirectional streaming" "grpc.aio, Port 8081"
            kafkaServer = container "Kafka Server" "Asynchronous inference via Kafka message topics" "aiokafka"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint" "FastAPI/Uvicorn, Port 8082"
            dataPlane = container "DataPlane Handler" "Unified inference/metadata/health handler shared across all protocols" "Python"
            modelRegistry = container "MultiModelRegistry" "Manages multiple models with versioning and ready state tracking" "Python"
            modelRepository = container "Model Repository" "Discovers and loads model configurations from filesystem" "Python"
            adaptiveBatcher = container "Adaptive Batcher" "Time-based and size-based request batching for throughput optimization" "Python"
            parallelWorkers = container "Parallel Workers" "Multiprocess pool distributing inference across worker processes" "Python multiprocessing"
            codecSystem = container "Codec System" "Bidirectional conversion between wire formats and Python types" "Python"
            sklearnRuntime = container "sklearn Runtime" "Serves scikit-learn models (.joblib, .pickle)" "Python MLModel Plugin"
            xgboostRuntime = container "xgboost Runtime" "Serves XGBoost models (.bst, .json)" "Python MLModel Plugin"
            lightgbmRuntime = container "lightgbm Runtime" "Serves LightGBM models (.bst)" "Python MLModel Plugin"
            onnxRuntime = container "onnx Runtime" "Serves ONNX models (.onnx) via onnxruntime" "Python MLModel Plugin"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService pod lifecycle, networking, and autoscaling" "Internal Platform"
        storageInit = softwareSystem "Storage Initializer" "Init container that populates /mnt/models with model artifacts" "Internal Platform"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar that authenticates requests before forwarding to MLServer" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "Internal Platform"
        kafkaBroker = softwareSystem "Kafka Broker" "Message broker for asynchronous inference" "External"
        istio = softwareSystem "Istio / Service Mesh" "Transparent mTLS and traffic management" "External"
        modelStorage = softwareSystem "Model Artifact Storage" "Filesystem storage for ML model files (/mnt/models)" "External"

        # External relationships
        dataScientist -> mlserver "Sends inference requests" "REST/gRPC via KServe Route"
        kserve -> mlserver "Creates and manages pod lifecycle" "Kubernetes API"
        storageInit -> modelStorage "Downloads model artifacts" "Object Storage / PVC"
        modelStorage -> mlserver "Provides model files at /mnt/models" "Filesystem"
        mlserver -> kafkaBroker "Consumes/produces inference messages" "Kafka/9092, Optional SSL"
        mlserver -> otelCollector "Exports distributed traces" "gRPC OTLP"
        prometheus -> mlserver "Scrapes metrics" "HTTP/8082"
        kubeRbacProxy -> mlserver "Forwards authenticated requests" "HTTP/8080, gRPC/8081"
        dataScientist -> kubeRbacProxy "Sends authenticated requests" "HTTPS/443 via Route"
        istio -> mlserver "Provides mTLS and traffic management" "Sidecar proxy"

        # Internal container relationships
        restServer -> dataPlane "Routes REST requests" "Function call"
        grpcServer -> dataPlane "Routes gRPC requests" "Function call"
        kafkaServer -> dataPlane "Routes Kafka messages" "Function call"
        dataPlane -> modelRegistry "Resolves model by name/version" "Function call"
        dataPlane -> adaptiveBatcher "Batches requests" "Function call"
        modelRegistry -> modelRepository "Discovers models" "Filesystem scan"
        adaptiveBatcher -> parallelWorkers "Dispatches batched inference" "Queue messaging"
        parallelWorkers -> sklearnRuntime "Executes predict()" "Function call"
        parallelWorkers -> xgboostRuntime "Executes predict()" "Function call"
        parallelWorkers -> lightgbmRuntime "Executes predict()" "Function call"
        parallelWorkers -> onnxRuntime "Executes predict()" "Function call"
        codecSystem -> dataPlane "Encodes/decodes inference data" "Function call"
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
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

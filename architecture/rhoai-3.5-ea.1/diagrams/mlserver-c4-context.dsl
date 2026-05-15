workspace {
    model {
        user = person "Data Scientist" "Creates ML models and deploys them as InferenceServices via KServe"

        mlserver = softwareSystem "MLServer" "Multi-model inference server implementing KFServing V2 Dataplane over REST, gRPC, and Kafka" {
            restServer = container "REST Server" "KFServing V2 Dataplane REST API" "FastAPI/Uvicorn, 8080/TCP"
            grpcServer = container "gRPC Server" "KFServing V2 Dataplane gRPC API" "grpc.aio, 8081/TCP"
            kafkaAdapter = container "Kafka Adapter" "Async inference via Kafka consumer/producer" "aiokafka, 9092/TCP"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint" "starlette-exporter, 8082/TCP"
            dataPlane = container "DataPlane Handler" "Unified request dispatch, batching, caching, CloudEvents" "Python"
            modelRegistry = container "Model Registry" "Runtime discovery, model lifecycle, trusted allowlist validation" "Python"
            modelRepository = container "Model Repository" "Filesystem-based model discovery from /mnt/models" "Python"
            parallelPool = container "Parallel Worker Pool" "Multiprocessing worker pool for GIL-free inference" "gevent/multiprocessing"
            sklearnRuntime = container "sklearn Runtime" "Scikit-learn model serving (joblib/pickle)" "Python Plugin"
            xgboostRuntime = container "XGBoost Runtime" "XGBoost model serving" "Python Plugin"
            lightgbmRuntime = container "LightGBM Runtime" "LightGBM model serving" "Python Plugin"
            onnxRuntime = container "ONNX Runtime" "ONNX model serving via onnxruntime" "Python Plugin"
        }

        kserve = softwareSystem "KServe" "Deploys and manages MLServer as inference containers in InferenceService pods" "Internal RHOAI"
        istio = softwareSystem "Istio / Service Mesh" "TLS termination, mTLS, traffic routing" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"
        kafkaBrokers = softwareSystem "Kafka Brokers" "Async message streaming for event-driven inference" "External"
        modelStorage = softwareSystem "Model Storage" "S3 or PVC-based model artifact storage" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Pod metadata, service account namespace" "External"

        # External relationships
        user -> kserve "Creates InferenceService CR via kubectl/dashboard"
        kserve -> mlserver "Deploys MLServer container in InferenceService pod"
        user -> mlserver "Sends inference requests via KServe Gateway" "HTTPS/443"
        mlserver -> prometheus "Exposes metrics at /metrics" "HTTP/8082"
        mlserver -> otelCollector "Exports traces via OTLP" "gRPC/4317"
        mlserver -> kafkaBrokers "Consumes/produces async inference messages" "TCP/9092"
        mlserver -> modelStorage "Loads model artifacts from /mnt/models" "HTTPS or Filesystem"
        mlserver -> kubernetesAPI "Reads namespace from service account" "Filesystem"

        # Container relationships
        restServer -> dataPlane "Routes REST requests"
        grpcServer -> dataPlane "Routes gRPC requests"
        kafkaAdapter -> dataPlane "Routes Kafka messages"
        dataPlane -> modelRegistry "Dispatches to model"
        dataPlane -> parallelPool "Parallel inference mode"
        modelRepository -> modelRegistry "Discovers models"
        modelRegistry -> sklearnRuntime "Invokes sklearn predict"
        modelRegistry -> xgboostRuntime "Invokes xgboost predict"
        modelRegistry -> lightgbmRuntime "Invokes lightgbm predict"
        modelRegistry -> onnxRuntime "Invokes onnx predict"
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
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

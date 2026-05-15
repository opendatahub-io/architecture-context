workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models via KServe InferenceService"
        sre = person "SRE / Platform Admin" "Monitors inference server health and performance"

        mlserver = softwareSystem "MLServer" "Python-based inference server implementing KServe V2 Open Inference Protocol with pluggable ML framework runtimes" {
            restServer = container "REST Server" "HTTP/REST interface for inference, health, metadata, and model repository APIs" "FastAPI/uvicorn, 8080/TCP"
            grpcServer = container "gRPC Server" "gRPC interface for inference, health, metadata, and model repository APIs" "grpc.aio, 8081/TCP"
            kafkaServer = container "Kafka Server" "Async message-based inference via Kafka topics" "aiokafka, 9092/TCP"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint" "starlette-exporter, 8082/TCP"
            dataPlane = container "DataPlane Handler" "Core inference routing, CloudEvents injection, response caching, adaptive batching" "Python"
            runtimePlugins = container "Runtime Plugin System" "Pluggable model runtimes: scikit-learn, XGBoost, LightGBM, ONNX (RHOAI curated set)" "Python MLModel base class"
            parallelPool = container "Parallel Inference Pool" "Multiprocessing worker pool for CPU-parallel model inference" "Python multiprocessing"
            modelRepository = container "Model Repository" "File-based model discovery via model-settings.json" "Python"
            codecSystem = container "Codec System" "Content-type negotiation for numpy, pandas, string, base64, datetime, JSON" "Python"
            trustedRuntimes = container "Trusted Runtimes Guard" "Production mode allowlist restricting which model implementations can be loaded" "JSON config at /etc/mlserver/trusted-runtimes.json"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle, creates pods with MLServer container" "Internal RHOAI"
        rhoaiGateway = softwareSystem "RHOAI Gateway" "Platform ingress with TLS termination and kube-rbac-proxy authentication" "Internal RHOAI"
        modelStorage = softwareSystem "Model Storage" "PVC or S3-backed storage for model artifacts, mounted at /mnt/models" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Receives distributed tracing data via OTLP gRPC" "External"
        kafkaBroker = softwareSystem "Kafka Broker" "Message broker for async inference requests" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"

        # External relationships
        dataScientist -> rhoaiGateway "Sends inference requests" "HTTPS/443, Bearer Token"
        rhoaiGateway -> mlserver "Forwards requests (TLS terminated)" "HTTP/8080, gRPC/8081"
        sre -> prometheus "Monitors metrics" "HTTPS"

        # Container relationships
        rhoaiGateway -> restServer "Forwards REST requests" "HTTP/8080, plaintext"
        rhoaiGateway -> grpcServer "Forwards gRPC requests" "gRPC/8081, insecure"
        restServer -> dataPlane "Routes inference" "In-process"
        grpcServer -> dataPlane "Routes inference" "In-process"
        kafkaServer -> dataPlane "Routes async inference" "In-process"
        dataPlane -> codecSystem "Encodes/decodes data" "In-process"
        dataPlane -> runtimePlugins "Invokes MLModel.predict()" "In-process"
        dataPlane -> parallelPool "Dispatches to workers" "multiprocessing.Queue IPC"
        modelRepository -> runtimePlugins "Discovers and loads models" "In-process"
        trustedRuntimes -> modelRepository "Restricts allowed runtimes" "In-process"

        # External integrations
        kserve -> mlserver "Deploys as container image in InferenceService pods" "Container Image"
        modelStorage -> modelRepository "Provides model artifacts" "Filesystem mount at /mnt/models"
        mlserver -> otelCollector "Exports traces" "gRPC/4317, insecure"
        kafkaBroker -> kafkaServer "Delivers/receives messages" "TCP/9092"
        prometheus -> metricsServer "Scrapes metrics" "HTTP/8082"
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

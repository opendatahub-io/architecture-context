workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        sre = person "SRE / Platform Admin" "Monitors and operates the inference platform"

        mlserver = softwareSystem "MLServer" "Dual-protocol ML inference server implementing V2 Dataplane API (Open Inference Protocol) over REST and gRPC with pluggable runtime architecture" {
            restServer = container "REST Server" "HTTP server implementing V2 Dataplane API for inference, health, metadata, and model repository" "Python / FastAPI / Uvicorn" "Port 8080"
            grpcServer = container "gRPC Server" "gRPC server implementing V2 GRPCInferenceService for inference, health, metadata, and model repository" "Python / grpcio" "Port 8081"
            metricsServer = container "Metrics Server" "Dedicated HTTP server exposing Prometheus metrics" "Python / FastAPI / Uvicorn" "Port 8082"
            kafkaServer = container "Kafka Server" "Optional async Kafka consumer/producer for event-driven inference" "Python / aiokafka" "Port 9092"
            dataPlane = container "DataPlane Handler" "Central request processing layer with inference middleware, batching, caching, and codec system" "Python"
            modelRepository = container "Model Repository" "Filesystem-based model discovery, loading, and lifecycle management" "Python"
            runtimes = container "Runtime Plugins" "Pluggable ML framework runtimes: SKLearn, XGBoost, LightGBM, ONNX, HuggingFace, MLflow, CatBoost, Alibi Detect/Explain, MLlib" "Python"
            parallelPool = container "Parallel Inference Pool" "Process pool for isolated model inference with per-model environment support" "Python / multiprocessing"
            runtimeSecurity = container "Runtime Security" "Trusted runtimes allowlist enforcement in PRODUCTION mode" "Python / Pydantic"
        }

        kserve = softwareSystem "KServe" "Deploys MLServer as a serving runtime via InferenceService CRD" "Internal RHOAI"
        istio = softwareSystem "Istio / Service Mesh" "Provides TLS termination, mTLS, traffic management, and auth at ingress" "External"
        modelStorage = softwareSystem "Model Storage" "PVC or S3-compatible storage for ML model artifacts" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Receives distributed traces via OTLP gRPC" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes metrics from /metrics endpoint" "External"
        kafkaBrokers = softwareSystem "Apache Kafka" "Message broker for event-driven inference pipelines (optional)" "External"

        # Relationships - External
        dataScientist -> kserve "Creates InferenceService CR"
        kserve -> mlserver "Deploys as serving runtime container"
        dataScientist -> mlserver "Sends inference requests via REST/gRPC"
        sre -> prometheus "Monitors MLServer metrics"

        # Relationships - Internal
        restServer -> dataPlane "Routes requests"
        grpcServer -> dataPlane "Routes RPCs"
        kafkaServer -> dataPlane "Routes events"
        dataPlane -> runtimes "Dispatches inference"
        dataPlane -> parallelPool "Distributes to workers (optional)"
        parallelPool -> runtimes "Worker process inference"
        modelRepository -> runtimes "Loads model artifacts"
        runtimeSecurity -> runtimes "Validates allowed implementations"

        # Relationships - External services
        mlserver -> modelStorage "Loads model artifacts from /mnt/models" "Filesystem / HTTPS"
        mlserver -> otelCollector "Exports traces" "OTLP gRPC/4317 (insecure)"
        mlserver -> kafkaBrokers "Event-driven inference I/O" "AMQP/9092"
        prometheus -> mlserver "Scrapes metrics" "HTTP/8082"
        istio -> mlserver "Routes traffic with TLS/mTLS" "HTTP/8080, gRPC/8081"
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
                background #f5a623
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

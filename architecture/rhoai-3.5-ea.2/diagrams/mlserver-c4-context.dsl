workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models via InferenceService"
        sre = person "SRE / Platform Engineer" "Monitors and operates the RHOAI platform"

        mlserver = softwareSystem "MLServer" "Python-based ML inference server implementing V2 Dataplane API (Open Inference Protocol) over REST and gRPC" {
            restServer = container "REST Server" "FastAPI/Uvicorn HTTP server implementing V2 Dataplane API" "Python (FastAPI)" "Service"
            grpcServer = container "gRPC Server" "gRPC server implementing V2 Dataplane API" "Python (grpcio)" "Service"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint" "Python (starlette-exporter)" "Service"
            dataPlane = container "DataPlane" "Core inference orchestrator: model registry, middleware chain, response caching" "Python" "Component"
            modelRepository = container "Model Repository" "Loads model artifacts from filesystem, validates against trusted runtimes allowlist" "Python" "Component"
            sklearnRuntime = container "SKLearn Runtime" "Scikit-learn model serving" "Python (mlserver-sklearn)" "Runtime"
            xgboostRuntime = container "XGBoost Runtime" "XGBoost model serving" "Python (mlserver-xgboost)" "Runtime"
            lightgbmRuntime = container "LightGBM Runtime" "LightGBM model serving" "Python (mlserver-lightgbm)" "Runtime"
            onnxRuntime = container "ONNX Runtime" "ONNX model serving" "Python (mlserver-onnx)" "Runtime"
            adaptiveBatcher = container "Adaptive Batcher" "Accumulates requests into batches for efficient batch inference" "Python" "Component"
            parallelWorkers = container "Parallel Workers" "Multiprocessing pool for CPU-bound inference (escapes GIL)" "Python (gevent)" "Component"
            kafkaHandler = container "Kafka Handler" "Async inference via Kafka topics" "Python (aiokafka)" "Component"
            trustedRuntimes = container "Trusted Runtimes Allowlist" "Production security: restricts loadable model implementations" "JSON config" "Security"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle, deploys MLServer as runtime container, routes traffic" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving controller, can use MLServer as ServingRuntime" "Internal RHOAI"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for traffic management, mTLS, and authorization" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing span collection" "External"
        kafka = softwareSystem "Kafka" "Event streaming for async inference requests" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration, health probes, RBAC" "External"
        modelStorage = softwareSystem "Model Storage" "PVC or init-container populated volume at /mnt/models" "External"

        # User interactions
        dataScientist -> kserve "Creates InferenceService CR via kubectl/dashboard"
        dataScientist -> mlserver "Sends inference requests" "HTTPS/443 (via platform ingress)"
        sre -> prometheus "Monitors MLServer metrics"

        # KServe deploys MLServer
        kserve -> mlserver "Deploys as runtime container, sets MLSERVER_MODELS_DIR, routes traffic"
        modelMesh -> mlserver "Uses as ServingRuntime for multi-model serving"

        # MLServer internal flows
        restServer -> dataPlane "Routes V2 API requests" "In-process"
        grpcServer -> dataPlane "Routes V2 API requests" "In-process"
        kafkaHandler -> dataPlane "Routes async requests" "In-process"
        dataPlane -> modelRepository "Loads and manages models" "In-process"
        dataPlane -> adaptiveBatcher "Batches requests" "In-process"
        dataPlane -> sklearnRuntime "Dispatches inference" "In-process"
        dataPlane -> xgboostRuntime "Dispatches inference" "In-process"
        dataPlane -> lightgbmRuntime "Dispatches inference" "In-process"
        dataPlane -> onnxRuntime "Dispatches inference" "In-process"
        modelRepository -> trustedRuntimes "Validates model implementations" "In-process"
        parallelWorkers -> dataPlane "IPC queues for parallel inference" "Multiprocessing"

        # External integrations
        mlserver -> prometheus "Exposes metrics" "HTTP/8082"
        mlserver -> otel "Exports tracing spans" "gRPC OTLP"
        mlserver -> kafka "Consumes/produces inference messages" "Kafka/9092"
        mlserver -> modelStorage "Loads model artifacts" "Filesystem /mnt/models"
        kubernetes -> mlserver "Health probes" "HTTP/8080 /v2/health/live, /v2/health/ready"
    }

    views {
        systemContext mlserver "SystemContext" {
            include *
            autoLayout
            description "MLServer in the RHOAI ecosystem"
        }

        container mlserver "Containers" {
            include *
            autoLayout
            description "MLServer internal architecture"
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
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Runtime" {
                background #50c878
                color #ffffff
            }
            element "Component" {
                background #5b6abf
                color #ffffff
            }
            element "Security" {
                background #e74c3c
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

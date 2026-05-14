workspace {
    model {
        datascientist = person "Data Scientist" "Creates, deploys, and queries ML models for inference"

        mlserver = softwareSystem "MLServer" "Python-based ML inference server implementing V2 Inference Protocol (REST + gRPC) for traditional ML frameworks" {
            restServer = container "REST Server" "FastAPI/Uvicorn HTTP server implementing V2 Inference Protocol endpoints" "Python / FastAPI" "Server"
            grpcServer = container "gRPC Server" "gRPC server implementing V2 Inference Protocol services" "Python / grpcio" "Server"
            metricsServer = container "Metrics Server" "Dedicated Prometheus metrics endpoint" "Python / prometheus-client" "Server"
            kafkaServer = container "Kafka Server" "Optional async inference via Kafka topics" "Python / aiokafka" "Server"
            dataPlane = container "DataPlane Handler" "Central orchestration for inference requests across all protocols" "Python" "Component"
            modelRegistry = container "Model Registry" "Manages model loading, versioning, and runtime selection" "Python" "Component"
            adaptiveBatcher = container "Adaptive Batcher" "Groups multiple inference requests into batched predictions" "Python" "Component"
            parallelPool = container "Parallel Worker Pool" "Multiprocessing workers to bypass Python GIL" "Python / multiprocessing" "Component"
            trustedRuntimes = container "Trusted Runtimes Security" "Allowlist-based validation of permitted ML implementations" "Python / Pydantic" "Security"
            sklearnRuntime = container "SKLearn Runtime" "Scikit-learn model serving plugin" "Python / scikit-learn" "Runtime"
            xgboostRuntime = container "XGBoost Runtime" "XGBoost model serving plugin" "Python / xgboost" "Runtime"
            lightgbmRuntime = container "LightGBM Runtime" "LightGBM model serving plugin" "Python / lightgbm" "Runtime"
            onnxRuntime = container "ONNX Runtime" "ONNX model serving plugin" "Python / onnxruntime" "Runtime"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle, ingress routing, scaling, and auth" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Platform monitoring and metrics collection" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing infrastructure" "Internal RHOAI"
        istio = softwareSystem "Istio / Gateway API" "Service mesh providing TLS termination and traffic management" "Internal RHOAI"
        kafkaBrokers = softwareSystem "Kafka Brokers" "Message broker for async inference workloads" "External"
        modelStorage = softwareSystem "Model Storage" "PVC or S3-backed storage for ML model artifacts" "External"

        # External relationships
        datascientist -> mlserver "Sends inference requests via REST/gRPC" "HTTPS/443 (via KServe)"
        datascientist -> kserve "Deploys InferenceService resources" "kubectl / API"

        # KServe manages MLServer
        kserve -> mlserver "Manages pod lifecycle, routes traffic, handles auth" "Kubernetes / Istio"
        istio -> mlserver "Terminates TLS, provides ingress" "HTTPS → HTTP"

        # MLServer → external
        mlserver -> modelStorage "Loads model artifacts" "Filesystem /mnt/models"
        mlserver -> kafkaBrokers "Async inference (optional)" "TCP/9092"
        mlserver -> otelCollector "Exports OTLP traces" "gRPC (insecure)"
        prometheus -> mlserver "Scrapes /metrics" "HTTP/8082"

        # Internal container relationships
        restServer -> dataPlane "Routes REST requests"
        grpcServer -> dataPlane "Routes gRPC requests"
        kafkaServer -> dataPlane "Routes Kafka messages"
        dataPlane -> modelRegistry "Resolves model + version"
        dataPlane -> adaptiveBatcher "Batches requests (optional)"
        dataPlane -> parallelPool "Dispatches to workers (optional)"
        modelRegistry -> sklearnRuntime "Loads scikit-learn models"
        modelRegistry -> xgboostRuntime "Loads XGBoost models"
        modelRegistry -> lightgbmRuntime "Loads LightGBM models"
        modelRegistry -> onnxRuntime "Loads ONNX models"
        modelRegistry -> trustedRuntimes "Validates allowed implementations"
    }

    views {
        systemContext mlserver "SystemContext" {
            include *
            autoLayout
            description "MLServer in the context of the RHOAI platform ecosystem"
        }

        container mlserver "Containers" {
            include *
            autoLayout
            description "Internal architecture of the MLServer inference server"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Server" {
                shape Hexagon
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Runtime" {
                shape RoundedBox
                background #7ed321
                color #ffffff
            }
            element "Security" {
                shape Diamond
                background #d0021b
                color #ffffff
            }
        }
    }
}

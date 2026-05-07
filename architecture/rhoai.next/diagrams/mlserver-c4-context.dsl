workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and pipelines"

        mlserver = softwareSystem "MLServer" "Python-based ML inference server implementing V2/Open Inference Protocol over REST and gRPC, used as the default multi-model serving runtime in RHOAI" {
            restServer = container "REST Server" "Serves V2 Inference Protocol over HTTP, handles model inference, health checks, repository management, and Swagger docs" "FastAPI/Uvicorn, Port 8080"
            grpcServer = container "gRPC Server" "Serves V2 Inference Protocol over gRPC, supports unary and bidirectional streaming inference" "grpcio, Port 8081"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics for inference request counts, latencies, and batch queue metrics" "prometheus-client, Port 8082"
            kafkaServer = container "Kafka Server" "Optional async inference via Kafka topic consumption and production" "aiokafka"
            dataPlane = container "DataPlane Handler" "Central orchestration for all inference protocols, applies consistent metrics, caching, and batching" "Python"
            adaptiveBatcher = container "Adaptive Batcher" "Groups multiple inference requests into batched predictions for throughput optimization" "Python"
            responseCache = container "Response Cache" "Local in-memory cache for repeated inference responses" "Python"
            modelRegistry = container "Model Registry" "Manages model lifecycle (load, unload, version), validates against trusted runtimes allowlist" "Python"
            sklearnRuntime = container "sklearn Runtime" "Scikit-learn model serving" "mlserver-sklearn"
            xgboostRuntime = container "XGBoost Runtime" "XGBoost model serving" "mlserver-xgboost"
            lightgbmRuntime = container "LightGBM Runtime" "LightGBM model serving" "mlserver-lightgbm"
            onnxRuntime = container "ONNX Runtime" "ONNX model serving via onnxruntime" "mlserver-onnx"
            inferencePool = container "Inference Pool" "Parallel worker processes to bypass Python GIL, with self-healing and model replay" "multiprocessing"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle, ingress routing, autoscaling, and model storage initialization" "Internal RHOAI"
        istio = softwareSystem "Istio / Gateway API" "Service mesh providing TLS termination, traffic routing, and mTLS between services" "External"
        prometheus = softwareSystem "Prometheus" "Platform monitoring system, scrapes MLServer metrics" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Collects and exports distributed traces via OTLP" "Internal RHOAI"
        kafka = softwareSystem "Apache Kafka" "Message broker for asynchronous inference workloads" "External"
        modelStorage = softwareSystem "Model Storage" "PVC or S3-backed storage for ML model artifacts, mounted at /mnt/models" "External"

        # External relationships
        dataScientist -> kserve "Creates InferenceService CR via kubectl/dashboard"
        mlEngineer -> kserve "Manages serving runtimes and model deployment"
        kserve -> mlserver "Deploys MLServer as serving container, manages model load/unload via agent"
        mlserver -> istio "Ingress traffic routed through Istio/Gateway API (TLS termination)"
        mlserver -> modelStorage "Reads model artifacts from /mnt/models volume" "Filesystem"
        mlserver -> prometheus "Exposes /metrics endpoint for scraping" "HTTP/8082"
        mlserver -> otelCollector "Exports OTLP traces" "gRPC (insecure)"
        mlserver -> kafka "Consumes/produces async inference messages" "TCP/9092"

        # Internal relationships
        restServer -> dataPlane "Routes inference requests"
        grpcServer -> dataPlane "Routes inference requests"
        kafkaServer -> dataPlane "Routes async inference requests"
        dataPlane -> adaptiveBatcher "Batches requests (optional)"
        dataPlane -> responseCache "Checks/stores cached responses"
        dataPlane -> modelRegistry "Resolves model and runtime"
        dataPlane -> inferencePool "Dispatches to parallel workers (optional)"
        modelRegistry -> sklearnRuntime "Loads sklearn models"
        modelRegistry -> xgboostRuntime "Loads XGBoost models"
        modelRegistry -> lightgbmRuntime "Loads LightGBM models"
        modelRegistry -> onnxRuntime "Loads ONNX models"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

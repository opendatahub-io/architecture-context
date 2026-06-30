workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models via InferenceService"
        sre = person "SRE / Platform Admin" "Monitors model serving health and performance"

        mlserver = softwareSystem "MLServer" "Multi-model inference server implementing KServe V2 Inference Protocol over REST and gRPC" {
            restServer = container "REST Server" "KServe V2 dataplane over HTTP with FastAPI/Uvicorn" "Python (FastAPI)" "Web Server"
            grpcServer = container "gRPC Server" "KServe V2 dataplane over gRPC with grpc.aio" "Python (grpcio)" "gRPC Server"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint" "Python (prometheus-client)" "Metrics"
            dataplaneHandlers = container "DataPlane Handlers" "Shared business logic for inference, metadata, health, repository operations" "Python"
            modelRegistry = container "MultiModelRegistry" "Model lifecycle management — load, unload, readiness tracking" "Python"
            adaptiveBatcher = container "Adaptive Batcher" "Groups inference requests into batches based on size/time thresholds" "Python"
            responseCache = container "Response Cache" "In-memory LRU cache for inference responses" "Python"
            codecSystem = container "Codec System" "Type-safe conversion between V2 wire format and Python types (numpy, pandas, string)" "Python"
            parallelPool = container "Parallel Inference Pool" "Multiprocessing worker pool for horizontal model scaling within a pod" "Python (multiprocessing)"
            sklearnRuntime = container "sklearn Runtime" "Scikit-learn model serving (predict, predict_proba, transform)" "Python (scikit-learn)" "Runtime Plugin"
            xgboostRuntime = container "XGBoost Runtime" "XGBoost model serving with auto regressor/classifier detection" "Python (xgboost)" "Runtime Plugin"
            lightgbmRuntime = container "LightGBM Runtime" "LightGBM Booster model serving" "Python (lightgbm)" "Runtime Plugin"
            onnxRuntime = container "ONNX Runtime" "ONNX model serving with configurable execution providers" "Python (onnxruntime)" "Runtime Plugin"

            restServer -> dataplaneHandlers "Routes requests to"
            grpcServer -> dataplaneHandlers "Routes requests to"
            dataplaneHandlers -> modelRegistry "Dispatches inference to"
            dataplaneHandlers -> adaptiveBatcher "Batches requests via"
            dataplaneHandlers -> responseCache "Checks/stores cache via"
            dataplaneHandlers -> codecSystem "Encodes/decodes via"
            modelRegistry -> sklearnRuntime "Loads and invokes"
            modelRegistry -> xgboostRuntime "Loads and invokes"
            modelRegistry -> lightgbmRuntime "Loads and invokes"
            modelRegistry -> onnxRuntime "Loads and invokes"
            modelRegistry -> parallelPool "Distributes to workers via"
        }

        kserve = softwareSystem "KServe" "Deploys MLServer as inference container, manages routing, scaling, storage initialization" "External"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar for TLS termination and Bearer Token authentication/authorization" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        kafka = softwareSystem "Apache Kafka" "Streaming inference input/output (optional)" "External"
        modelStorage = softwareSystem "Model Storage" "Model artifacts via PVC or KServe storage initializer (/mnt/models)" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Service account namespace for CloudEvents" "External"

        # User interactions
        dataScientist -> kubeRbacProxy "Sends inference requests via" "HTTPS/8443"
        sre -> prometheus "Monitors MLServer via"

        # Platform interactions
        kubeRbacProxy -> mlserver "Forwards authenticated traffic to" "HTTP/8080, gRPC/8081"
        kserve -> mlserver "Deploys and manages lifecycle of"
        mlserver -> prometheus "Exposes metrics to" "HTTP/8082"
        mlserver -> otelCollector "Exports trace spans to" "gRPC/4317"
        mlserver -> kafka "Consumes/produces inference messages" "Kafka/9092"
        mlserver -> modelStorage "Loads model artifacts from" "Filesystem /mnt/models"
        mlserver -> kubernetesAPI "Reads namespace from" "ServiceAccount mount"
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
            element "Runtime Plugin" {
                background #7ed321
                color #ffffff
            }
            element "Web Server" {
                background #4a90e2
                color #ffffff
            }
            element "gRPC Server" {
                background #4a90e2
                color #ffffff
            }
            element "Metrics" {
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
        }
    }
}

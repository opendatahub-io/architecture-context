workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and runtimes"

        mlserver = softwareSystem "MLServer" "Python-based ML inference server implementing V2 Inference Protocol (REST + gRPC) for traditional ML frameworks" {
            restServer = container "REST Server" "FastAPI/Uvicorn HTTP server exposing V2 Inference Protocol endpoints" "Python / FastAPI" "WebApp"
            grpcServer = container "gRPC Server" "gRPC server exposing V2 Inference Protocol services with streaming support" "Python / grpcio" "WebApp"
            metricsServer = container "Metrics Server" "Dedicated Prometheus metrics endpoint" "Python / prometheus-client" "WebApp"
            dataPlane = container "DataPlane Handler" "Central orchestration layer for inference requests, shared by REST/gRPC/Kafka" "Python"
            adaptiveBatcher = container "Adaptive Batcher" "Time-window/size-limit request batching for improved throughput" "Python"
            responseCache = container "Response Cache" "Local response cache for repeated inference requests" "Python"
            workerPool = container "Worker Process Pool" "Parallel inference via multiprocessing to bypass Python GIL" "Python / multiprocessing"
            sklearnRuntime = container "sklearn Runtime" "Scikit-learn model serving plugin" "Python / scikit-learn"
            xgboostRuntime = container "XGBoost Runtime" "XGBoost model serving plugin" "Python / xgboost"
            lightgbmRuntime = container "LightGBM Runtime" "LightGBM model serving plugin" "Python / lightgbm"
            onnxRuntime = container "ONNX Runtime" "ONNX model serving plugin" "Python / onnxruntime"
            kafkaServer = container "Kafka Server" "Optional async inference via Kafka message consumption/production" "Python / aiokafka"
            trustedRuntimes = container "Trusted Runtimes" "Production-mode allowlist restricting which model implementations can load" "JSON Config"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle, scaling, routing, and ingress" "External Platform"
        istio = softwareSystem "Istio / Gateway API" "Service mesh providing TLS termination, mTLS, and traffic routing" "External Platform"
        prometheus = softwareSystem "Prometheus" "Monitoring system that scrapes inference metrics" "External Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Receives OTLP traces for distributed tracing" "External Platform"
        kafkaBrokers = softwareSystem "Kafka Brokers" "Message broker for async inference workloads" "External"
        modelStorage = softwareSystem "Model Storage" "PVC or S3-backed storage for model artifacts mounted at /mnt/models" "External"

        # User interactions
        dataScientist -> kserve "Creates InferenceService CR via kubectl/API"
        dataScientist -> mlserver "Sends inference requests (REST/gRPC) via KServe ingress"
        mlEngineer -> kserve "Configures serving runtimes and model deployments"

        # Platform interactions
        kserve -> mlserver "Deploys as serving container in InferenceService pods; manages model load/unload via REST API"
        istio -> mlserver "Routes external traffic; provides TLS termination and auth sidecars"
        mlserver -> prometheus "Exposes /metrics on port 8082 for scraping" "HTTP/8082"
        mlserver -> otelCollector "Exports OTLP traces" "gRPC (insecure)"
        mlserver -> kafkaBrokers "Consumes/produces async inference messages" "TCP/9092"
        mlserver -> modelStorage "Reads model artifacts from /mnt/models" "Filesystem"
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
                background #438dd5
                color #ffffff
            }
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "WebApp" {
                shape WebBrowser
            }
        }
    }
}

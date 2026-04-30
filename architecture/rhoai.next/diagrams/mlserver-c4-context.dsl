workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        sre = person "SRE / Platform Admin" "Monitors and operates the RHOAI platform"

        mlserver = softwareSystem "MLServer" "Inference server implementing the Open Inference Protocol (V2 Dataplane API) for serving ML models over REST and gRPC" {
            restServer = container "REST Server" "HTTP server for V2 REST inference, health, metadata, and model repository endpoints" "Python / FastAPI / Uvicorn" "Port 8080"
            grpcServer = container "gRPC Server" "gRPC server for V2 gRPC inference, health, metadata, and model repository RPCs" "Python / grpcio" "Port 8081"
            metricsServer = container "Metrics Server" "Dedicated HTTP server exposing Prometheus metrics" "Python / Uvicorn" "Port 8082"
            kafkaServer = container "Kafka Server" "Optional async Kafka consumer/producer for event-driven inference" "Python / aiokafka"
            dataPlane = container "DataPlane Handler" "Shared request processing: routing, middleware, batching, caching" "Python"
            runtimes = container "Runtime Plugins" "Pluggable ML framework runtimes: SKLearn, XGBoost, LightGBM, ONNX, HuggingFace, MLflow, CatBoost, Alibi, Spark" "Python Plugins"
            parallelPool = container "Parallel Inference Pool" "Process pool for isolated model inference with environment support" "Python / multiprocessing"
            modelRepo = container "Model Repository" "Filesystem-based model discovery and lifecycle management" "Python"
            runtimeSecurity = container "Runtime Security" "PRODUCTION mode enforces trusted-runtimes.json allowlist" "Python / Pydantic"

            restServer -> dataPlane "Routes V2 REST requests"
            grpcServer -> dataPlane "Routes V2 gRPC requests"
            kafkaServer -> dataPlane "Routes event-driven requests"
            dataPlane -> runtimes "Invokes MLModel.predict()"
            dataPlane -> parallelPool "Dispatches to worker processes"
            parallelPool -> runtimes "Workers invoke MLModel.predict()"
            runtimeSecurity -> runtimes "Validates runtime allowlist"
            modelRepo -> runtimes "Discovers and loads models"
        }

        kserve = softwareSystem "KServe" "Deploys MLServer as a serving runtime via InferenceService CRD" "Internal RHOAI"
        istio = softwareSystem "Istio / Service Mesh" "Ingress gateway, TLS termination, mTLS, AuthN/AuthZ" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "External"
        kafkaBrokers = softwareSystem "Apache Kafka" "Event streaming platform for event-driven inference" "External"
        modelStorage = softwareSystem "Model Storage" "PVC or S3 storage for model artifacts" "External"

        # User relationships
        dataScientist -> kserve "Creates InferenceService CR"
        dataScientist -> mlserver "Sends inference requests (REST/gRPC)"
        sre -> prometheus "Monitors metrics"

        # Platform relationships
        kserve -> mlserver "Deploys as serving runtime container"
        modelStorage -> mlserver "Provides model artifacts at /mnt/models"

        # Egress relationships
        mlserver -> otelCollector "Exports traces" "gRPC/OTLP 4317"
        mlserver -> kafkaBrokers "Event-driven inference" "AMQP/9092"

        # Monitoring relationships
        prometheus -> mlserver "Scrapes /metrics" "HTTP/8082"

        # Ingress relationship
        istio -> mlserver "Routes traffic after TLS termination" "HTTP/8080, gRPC/8081"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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
        }
    }
}

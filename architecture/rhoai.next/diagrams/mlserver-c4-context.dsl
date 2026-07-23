workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries ML models via InferenceService"
        sre = person "SRE / Platform Admin" "Monitors inference server health and performance"

        mlserver = softwareSystem "MLServer" "Multi-model inference server implementing KServe V2 Inference Protocol with REST and gRPC endpoints" {
            restServer = container "REST Server" "FastAPI/Uvicorn HTTP server implementing V2 Inference Protocol endpoints" "Python - FastAPI" "Web Server"
            grpcServer = container "gRPC Server" "gRPC server implementing V2 Inference Protocol services" "Python - grpc.aio" "RPC Server"
            dataPlane = container "DataPlane Handler" "Protocol-agnostic inference logic: model lookup, caching, batching, CloudEvents" "Python" "Core"
            modelRegistry = container "Model Registry" "Multi-model lifecycle management with versioning, readiness gating, hot-reload" "Python" "Registry"
            runtimePlugins = container "Runtime Plugin System" "Pluggable ML framework adapters (scikit-learn, XGBoost, LightGBM, ONNX)" "Python" "Plugin System"
            adaptiveBatcher = container "Adaptive Batcher" "Request batching engine with configurable max batch size and time window" "Python" "Performance"
            parallelPool = container "Parallel Inference Pool" "Multiprocessing worker pool with round-robin dispatch for CPU-bound inference" "Python" "Performance"
            metricsServer = container "Metrics Server" "Prometheus metrics exposition with multiprocess aggregation" "Python" "Observability"
            kafkaServer = container "Kafka Server" "Async inference via Apache Kafka consumer/producer (optional)" "Python" "Messaging"
            trustedRuntimes = container "Trusted Runtimes Security" "Image-baked allowlist restricting loadable model implementations in PRODUCTION" "JSON Config" "Security"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native model serving controller managing InferenceService lifecycle" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization sidecar performing SubjectAccessReview" "Internal RHOAI"
        storageInitializer = softwareSystem "KServe Storage Initializer" "Init container that downloads model artifacts to PVC" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting platform" "Internal RHOAI"
        modelStorage = softwareSystem "Model Storage" "PVC or S3-compatible storage for model artifacts" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection and export" "External"
        kafkaCluster = softwareSystem "Apache Kafka" "Distributed event streaming platform for async inference" "External"

        # User interactions
        datascientist -> kubeRbacProxy "Sends inference requests via V2 protocol" "HTTPS/8443"
        sre -> prometheus "Monitors inference metrics" "HTTP"

        # Proxy to MLServer
        kubeRbacProxy -> mlserver "Forwards authenticated requests" "HTTP/8080, gRPC/8081"

        # Internal container interactions
        restServer -> dataPlane "Routes HTTP requests"
        grpcServer -> dataPlane "Routes gRPC requests"
        dataPlane -> modelRegistry "Model lookup and lifecycle"
        dataPlane -> adaptiveBatcher "Batches requests"
        adaptiveBatcher -> parallelPool "Dispatches to workers"
        modelRegistry -> runtimePlugins "Loads ML models"
        runtimePlugins -> trustedRuntimes "Validates allowed implementations"
        kafkaServer -> dataPlane "Async inference requests"

        # External integrations
        kserve -> mlserver "Manages pod lifecycle"
        storageInitializer -> mlserver "Mounts model artifacts at /mnt/models" "Filesystem"
        prometheus -> mlserver "Scrapes metrics" "HTTP/8082"
        mlserver -> otelCollector "Exports traces" "gRPC OTLP (insecure)"
        mlserver -> kafkaCluster "Pub/sub async inference" "TCP/9092"
        mlserver -> modelStorage "Reads model artifacts" "Filesystem (/mnt/models)"
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
            element "Software System" {
                background #438DD5
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
                background #438DD5
                color #ffffff
            }
            element "Core" {
                background #1168BD
                color #ffffff
            }
            element "Security" {
                background #C62828
                color #ffffff
            }
            element "Performance" {
                background #7B1FA2
                color #ffffff
            }
            element "Observability" {
                background #E65100
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
        }
    }
}

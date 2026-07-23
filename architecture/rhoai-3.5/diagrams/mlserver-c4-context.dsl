workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        sre = person "SRE / Platform Admin" "Monitors inference services and infrastructure"

        mlserver = softwareSystem "MLServer" "Multi-framework ML inference server implementing KServe V2 Dataplane protocol over REST and gRPC" {
            restServer = container "REST Server" "HTTP/1.1 inference, health, metadata, model repository, and streaming endpoints" "FastAPI / uvicorn" "8080/TCP"
            grpcServer = container "gRPC Server" "gRPC inference, health, metadata, and model repository service" "grpc.aio" "8081/TCP"
            metricsServer = container "Metrics Server" "Dedicated Prometheus metrics scraping endpoint" "FastAPI" "8082/TCP"
            dataPlane = container "DataPlane Handler" "Central request routing, inference dispatch, adaptive batching" "Python"
            sklearnRuntime = container "SKLearn Runtime" "scikit-learn model loading and inference" "mlserver-sklearn"
            onnxRuntime = container "ONNX Runtime" "ONNX model inference with CPU or CUDA execution providers" "mlserver-onnx"
            xgboostRuntime = container "XGBoost Runtime" "XGBoost model loading and inference" "mlserver-xgboost"
            lightgbmRuntime = container "LightGBM Runtime" "LightGBM model loading and inference" "mlserver-lightgbm"
            kafkaServer = container "Kafka Server" "Optional Kafka-based inference request/response pipeline" "aiokafka"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native ML model serving platform managing InferenceService lifecycle" "External"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar proxy injected by RHOAI operator" "External"
        modelStorage = softwareSystem "Model Storage" "PVC-mounted model artifact storage at /mnt/models" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing via OTLP export (optional)" "External"
        kafkaBrokers = softwareSystem "Kafka Brokers" "Event streaming for inference requests/responses (optional)" "External"

        # Relationships
        dataScientist -> kserve "Creates InferenceService via kubectl/API"
        kserve -> mlserver "Deploys as inference container in pod"
        sre -> prometheus "Monitors inference metrics"

        kubeRbacProxy -> restServer "Forwards authenticated REST requests" "HTTP/8080"
        kubeRbacProxy -> grpcServer "Forwards authenticated gRPC requests" "gRPC/8081"

        restServer -> dataPlane "Delegates inference requests" "in-process"
        grpcServer -> dataPlane "Delegates inference requests" "in-process"
        kafkaServer -> dataPlane "Delegates inference requests" "in-process"

        dataPlane -> sklearnRuntime "Dispatches to runtime" "in-process"
        dataPlane -> onnxRuntime "Dispatches to runtime" "in-process"
        dataPlane -> xgboostRuntime "Dispatches to runtime" "in-process"
        dataPlane -> lightgbmRuntime "Dispatches to runtime" "in-process"

        mlserver -> modelStorage "Loads model artifacts" "Filesystem /mnt/models"
        prometheus -> metricsServer "Scrapes metrics" "HTTP/8082"
        mlserver -> otelCollector "Exports trace spans" "gRPC/OTLP (plaintext)"
        kafkaServer -> kafkaBrokers "Consumes/produces inference messages" "TCP/9092"
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

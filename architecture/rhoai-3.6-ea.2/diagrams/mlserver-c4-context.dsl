workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries ML models via KServe InferenceService"
        sre = person "SRE / Platform Admin" "Monitors inference workloads and platform health"

        mlserver = softwareSystem "MLServer" "Python-based inference server implementing KServe V2 Inference Protocol over REST and gRPC, supporting multiple ML framework runtimes" {
            restServer = container "REST Server" "FastAPI/uvicorn HTTP server exposing V2 Inference Protocol endpoints" "Python (FastAPI)" "Web Server"
            grpcServer = container "gRPC Server" "gRPC server exposing V2 Inference Protocol services" "Python (grpcio)" "gRPC Service"
            metricsServer = container "Metrics Server" "Prometheus-compatible metrics endpoint" "Python (starlette-exporter)" "Metrics"
            dataPlane = container "DataPlane Handler" "Shared handler layer for REST and gRPC, implements V2 protocol logic" "Python"
            modelManager = container "Model Manager" "Manages model lifecycle, multi-model serving, parallel workers" "Python"
            trustedRuntimes = container "Trusted Runtimes Enforcer" "Validates model implementations against build-time allowlist" "Python" "Security"
            adaptiveBatcher = container "Adaptive Batcher" "Groups inference requests to optimize throughput" "Python"
            sklearnRuntime = container "SKLearn Runtime" "Scikit-Learn model serving" "mlserver-sklearn" "Runtime"
            xgboostRuntime = container "XGBoost Runtime" "XGBoost model serving" "mlserver-xgboost" "Runtime"
            lightgbmRuntime = container "LightGBM Runtime" "LightGBM model serving" "mlserver-lightgbm" "Runtime"
            onnxRuntime = container "ONNX Runtime" "ONNX model serving (CPU and CUDA variants)" "mlserver-onnx" "Runtime"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle and pod deployment" "Internal Platform"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Sidecar proxy enforcing OpenShift OAuth authentication" "Internal Platform"
        istio = softwareSystem "OpenShift Service Mesh (Istio)" "Provides mTLS transport encryption between services" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        otlpCollector = softwareSystem "OTLP Collector" "Distributed tracing collection" "External Optional"
        kafka = softwareSystem "Kafka" "Async inference via message queues" "External Optional"

        # External relationships
        datascientist -> kubeRBACProxy "Sends inference requests" "HTTPS/443, Bearer Token"
        kubeRBACProxy -> mlserver "Forwards validated requests" "HTTP/8080, gRPC/8081"
        sre -> prometheus "Monitors metrics" "HTTPS"
        kserve -> mlserver "Manages pod lifecycle" "Kubernetes API"
        istio -> mlserver "Wraps traffic in mTLS" "mTLS STRICT"
        prometheus -> mlserver "Scrapes metrics" "HTTP/8082"
        mlserver -> otlpCollector "Exports traces" "gRPC (insecure, optional)"
        mlserver -> kafka "Async inference" "TCP/9092 (optional)"

        # Internal relationships
        restServer -> dataPlane "Routes requests"
        grpcServer -> dataPlane "Routes requests"
        dataPlane -> modelManager "Resolves and invokes models"
        modelManager -> trustedRuntimes "Validates implementation"
        modelManager -> adaptiveBatcher "Batches requests"
        adaptiveBatcher -> sklearnRuntime "Executes predict()"
        adaptiveBatcher -> xgboostRuntime "Executes predict()"
        adaptiveBatcher -> lightgbmRuntime "Executes predict()"
        adaptiveBatcher -> onnxRuntime "Executes predict()"
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
            element "Internal Platform" {
                background #9b59b6
                color #ffffff
            }
            element "External Optional" {
                background #999999
                color #ffffff
            }
            element "Runtime" {
                background #7ed321
                color #000000
            }
            element "Security" {
                background #e74c3c
                color #ffffff
            }
            element "Web Server" {
                background #4a90e2
                color #ffffff
            }
            element "gRPC Service" {
                background #4a90e2
                color #ffffff
            }
            element "Metrics" {
                background #f5a623
                color #000000
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for inference"
        mlEngineer = person "ML Engineer" "Manages model serving configurations and runtimes"

        mlserver = softwareSystem "MLServer" "Multi-model inference server implementing V2 Inference Protocol (KServe/Open Inference Protocol) over REST and gRPC" {
            restServer = container "REST Server" "Implements V2 Inference Protocol over HTTP with FastAPI/Uvicorn" "Python (FastAPI)" "Service"
            grpcServer = container "gRPC Server" "Implements V2 Inference Protocol over gRPC with grpc.aio" "Python (grpcio)" "Service"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics for inference request counts, latency, and batch queue" "Python (starlette-exporter)" "Service"
            dataPlane = container "DataPlane" "Routes inference requests to model instances, handles batching and parallel dispatch" "Python" "Component"
            modelRegistry = container "ModelRegistry" "Manages model lifecycle: loading, unloading, versioning, and readiness tracking" "Python" "Component"
            sklearnRuntime = container "sklearn Runtime" "Serves scikit-learn models (.joblib, .pickle)" "Python (mlserver-sklearn)" "Runtime"
            xgboostRuntime = container "XGBoost Runtime" "Serves XGBoost models (.bst, .json)" "Python (mlserver-xgboost)" "Runtime"
            lightgbmRuntime = container "LightGBM Runtime" "Serves LightGBM models (.bst)" "Python (mlserver-lightgbm)" "Runtime"
            onnxRuntime = container "ONNX Runtime" "Serves ONNX models (.onnx) via onnxruntime" "Python (mlserver-onnx)" "Runtime"
            trustedRuntimes = container "Trusted Runtimes Validator" "Enforces allowlist of permitted runtime import paths from /etc/mlserver/trusted-runtimes.json" "Python" "Security"
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform that manages InferenceService lifecycle" "External Platform"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving platform that manages ServingRuntime pods" "External Platform"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh providing TLS termination, mTLS, and traffic management" "External Platform"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar providing authentication and authorization enforcement" "External Platform"
        modelStorage = softwareSystem "Model Storage (PVC/S3)" "Persistent storage for ML model artifacts" "External Storage"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring system" "External Monitoring"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection and export" "External Monitoring"
        kafka = softwareSystem "Kafka Cluster" "Message broker for asynchronous inference (optional)" "External Optional"

        # User interactions
        dataScientist -> kserve "Creates InferenceService via kubectl/API"
        dataScientist -> mlserver "Sends inference requests via REST/gRPC" "HTTPS/443 (via platform ingress)"
        mlEngineer -> kserve "Configures ServingRuntimes and InferenceServices"

        # Platform deploys MLServer
        kserve -> mlserver "Deploys as inference container in InferenceService pods" "Container Image"
        modelMesh -> mlserver "Deploys as serving runtime container" "Container Image"

        # Ingress path
        istio -> mlserver "Forwards requests after TLS termination" "HTTP/8080, gRPC/8081 (plaintext)"
        kubeRbacProxy -> mlserver "Forwards requests after auth enforcement" "HTTP/8080 (plaintext)"

        # MLServer internal
        restServer -> dataPlane "Routes REST requests"
        grpcServer -> dataPlane "Routes gRPC requests"
        dataPlane -> modelRegistry "Looks up model instances"
        modelRegistry -> sklearnRuntime "Loads and invokes sklearn models"
        modelRegistry -> xgboostRuntime "Loads and invokes XGBoost models"
        modelRegistry -> lightgbmRuntime "Loads and invokes LightGBM models"
        modelRegistry -> onnxRuntime "Loads and invokes ONNX models"
        trustedRuntimes -> modelRegistry "Validates runtime import paths before loading"

        # Egress
        mlserver -> modelStorage "Loads model artifacts from /mnt/models" "Filesystem (Volume Mount)"
        mlserver -> otelCollector "Exports distributed traces" "gRPC/4317 (plaintext, insecure=True)"
        mlserver -> kafka "Async inference input/output" "Kafka/9092 (configurable encryption)"
        prometheus -> mlserver "Scrapes inference metrics" "HTTP/8082"
    }

    views {
        systemContext mlserver "SystemContext" {
            include *
            autoLayout
            description "MLServer system context showing the inference server within the RHOAI platform ecosystem"
        }

        container mlserver "Containers" {
            include *
            autoLayout
            description "MLServer internal container structure showing REST/gRPC servers, data plane, and pluggable ML runtimes"
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External Storage" {
                background #f5a623
                color #ffffff
            }
            element "External Monitoring" {
                background #7B68EE
                color #ffffff
            }
            element "External Optional" {
                background #CCCCCC
                color #333333
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Runtime" {
                background #7ed321
                color #ffffff
            }
            element "Component" {
                background #85BBF0
                color #333333
            }
            element "Security" {
                background #f5a623
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

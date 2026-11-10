workspace "MLServer (RHOAI 3.7-ea.1)" "C4 context for the MLServer model serving runtime" {
    model {
        user = person "Data Scientist / Application" "Deploys InferenceServices and sends V2 inference requests"

        mlserver = softwareSystem "MLServer" "Python Open Inference Protocol (KServe V2) server for sklearn, XGBoost, LightGBM and ONNX models. Images: odh-mlserver-rhel9, odh-mlserver-cuda-rhel9" {
            rest = container "REST server" "V2 dataplane, /v2/runtimes, model repository extension, Swagger docs. 0.0.0.0:8080 plaintext" "Python, FastAPI/uvicorn"
            grpc = container "gRPC server" "GRPCInferenceService (incl. RHOAI RuntimeSecurity RPC) and ModelRepositoryService. 0.0.0.0:8081 add_insecure_port" "Python, grpc.aio"
            metrics = container "Metrics server" "Prometheus /metrics. 0.0.0.0:8082" "Python, uvicorn"
            core = container "MLServer core" "Model registry, dataplane handlers, codecs, adaptive batching, trusted runtime allowlist" "Python"
            pool = container "Parallel inference pool" "Worker processes running model inference" "Python multiprocessing"
            runtimes = container "Runtime plugins" "mlserver-sklearn, -xgboost, -lightgbm, -onnx (CPU); mlserver-onnx with CUDA EP (CUDA)" "Python"
            kafkaSrv = container "Kafka server" "Optional inference over Kafka topics (disabled by default)" "Python, aiokafka"
        }

        kserve = softwareSystem "KServe" "Deploys MLServer as a ServingRuntime, creates Services and routing, injects storage-initializer and auth sidecar" "Internal RHOAI"
        rhods = softwareSystem "RHOAI operator" "Ships the MLServer ServingRuntime template" "Internal RHOAI"
        krp = softwareSystem "kube-rbac-proxy" "Token authentication sidecar (TokenReview/SAR) when InferenceService auth is enabled" "Internal RHOAI"
        storageInit = softwareSystem "KServe storage-initializer" "Downloads model artifacts into /mnt/models" "Internal RHOAI"
        gateway = softwareSystem "Platform Gateway / Route" "External exposure via Gateway API HTTPRoute or OpenShift Route" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / User Workload Monitoring" "Scrapes MLServer metrics" "External"
        otlp = softwareSystem "OTLP collector" "Optional trace collector" "External"
        kafka = softwareSystem "Kafka brokers" "Optional Kafka inference transport" "External"
        storage = softwareSystem "Model storage" "S3-compatible object storage, PVC or OCI registry" "External"
        aipcc = softwareSystem "AIPCC base images and RHEL AI PyPI" "Build-time base OS/Python/CUDA and hashed MLServer wheels" "Internal RHOAI"

        user -> kserve "Creates InferenceService selecting MLServer runtime"
        rhods -> kserve "Provides ServingRuntime template"
        kserve -> mlserver "Deploys image as predictor pod"
        user -> gateway "V2 inference" "HTTPS/443, Bearer token"
        gateway -> krp "Forwards" "HTTPS/8443"
        krp -> rest "Forwards authenticated requests" "HTTP/8080 localhost, plaintext"
        krp -> grpc "Forwards authenticated requests" "gRPC/8081 localhost, plaintext"
        storageInit -> storage "Downloads model artifacts" "HTTPS/443"
        storageInit -> mlserver "Populates /mnt/models" "filesystem"
        prometheus -> metrics "Scrapes /metrics" "HTTP/8082, no auth"
        core -> otlp "Exports traces" "OTLP/gRPC, insecure=True"
        kafkaSrv -> kafka "Consumes/produces inference messages" "Kafka, no SSL/SASL"
        aipcc -> mlserver "Base image and wheels" "Build-time"

        rest -> core "Calls dataplane"
        grpc -> core "Calls dataplane"
        kafkaSrv -> core "Calls dataplane"
        core -> pool "Dispatches inference"
        core -> runtimes "Loads allowlisted implementations"
        pool -> runtimes "Runs predict"
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
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}

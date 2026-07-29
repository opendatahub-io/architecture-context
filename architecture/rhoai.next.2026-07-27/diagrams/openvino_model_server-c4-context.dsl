workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models and creates InferenceService resources"
        appDeveloper = person "Application Developer" "Sends inference requests to deployed models"

        ovms = softwareSystem "OpenVINO Model Server" "High-performance inference server built on the OpenVINO toolkit, serving ML models via KServe v2, TensorFlow Serving, and OpenAI-compatible APIs" {
            restAPI = container "REST API Server" "Serves KServe v2, TensorFlow Serving, and OpenAI-compatible REST endpoints" "C++ / Port 8888"
            grpcAPI = container "gRPC API Server" "Serves KServe v2 and TensorFlow Serving gRPC endpoints including bidirectional streaming" "C++ / Port 8001"
            inferenceEngine = container "OpenVINO Inference Engine" "Executes model inference on Intel hardware with optimized performance" "C++ / OpenVINO Toolkit"
            modelLoader = container "Model Loader" "Loads model artifacts from storageUri mount at /mnt/models" "C++"
            mediaPipe = container "MediaPipe Graph Engine" "Handles stateful streaming inference sessions" "C++ / MediaPipe"
            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus metrics at /metrics on port 8888" "C++"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle and creates OVMS pods as ServingRuntime" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, and policy enforcement" "External"
        modelStorage = softwareSystem "Model Storage" "Stores ML model artifacts (S3, GCS, PVC, or other storageUri-compatible backends)" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes and stores inference server metrics" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "Manages pods, services, and custom resources" "External"

        # User interactions
        dataScientist -> kserve "Creates InferenceService CR" "kubectl / RHOAI Dashboard"
        appDeveloper -> ovms "Sends inference requests" "REST :8888 / gRPC :8001"

        # OVMS internal flows
        restAPI -> inferenceEngine "Executes inference"
        grpcAPI -> inferenceEngine "Executes inference"
        grpcAPI -> mediaPipe "Instantiates streaming sessions"
        mediaPipe -> inferenceEngine "Processes inference packets"
        modelLoader -> inferenceEngine "Loads model into runtime"

        # External integrations
        kserve -> ovms "Creates OVMS pods as ServingRuntime" "Kubernetes API"
        ovms -> modelStorage "Downloads model artifacts" "storageUri mount /mnt/models"
        ovms -> istio "Traffic routed through sidecar" "mTLS"
        prometheus -> ovms "Scrapes metrics" "HTTP GET /metrics :8888"
        kserve -> k8sAPI "Manages InferenceService resources" "HTTPS/443"
    }

    views {
        systemContext ovms "SystemContext" {
            include *
            autoLayout
        }

        container ovms "Containers" {
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
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

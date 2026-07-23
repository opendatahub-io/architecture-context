workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys models and runs inference via KServe InferenceService"
        mlEngineer = person "ML Engineer" "Integrates model serving into applications"

        ovms = softwareSystem "OpenVINO Model Server" "High-performance C++ inference server exposing gRPC and REST APIs for AI model serving" {
            grpcFrontend = container "gRPC Frontend" "Serves KServe v2 and TFS v1 gRPC inference APIs" "C++ Module"
            httpFrontend = container "HTTP/REST Frontend" "Serves KServe v2, TFS v1, OpenAI-compatible REST APIs, and metrics" "C++ Module (Drogon)"
            llmModule = container "LLM Module" "LLM text generation with continuous batching and streaming" "C++ MediaPipe Calculator"
            embeddingsModule = container "Embeddings Module" "Vector embeddings generation" "C++ MediaPipe Calculator"
            rerankModule = container "Rerank Module" "Cross-encoder document reranking" "C++ MediaPipe Calculator"
            imageGenModule = container "Image Generation Module" "Text-to-image with LoRA adapter support" "C++ MediaPipe Calculator"
            audioModule = container "Audio Module" "Speech-to-text and text-to-speech" "C++ MediaPipe Calculator"
            mediapipe = container "MediaPipe Integration" "Graph-based pipeline composition framework" "C++ Module"
            pythonBackend = container "Python Backend" "Custom Python processing nodes" "C++ Module (PyBind11)"
            filesystemBackends = container "Filesystem Backends" "Abstract storage layer for model loading" "C++ Module"
            metricsModule = container "Metrics Module" "Request/response metrics and monitoring" "Prometheus C++"
            openvinoRuntime = container "OpenVINO Runtime" "Core inference engine for all model types" "C++ Library (2026.2)"
            openvinoGenAI = container "OpenVINO GenAI" "LLM, image generation, speech processing" "C++ Library (2026.2)"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native model serving framework - deploys and manages OVMS pods" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication enforcement sidecar" "Internal RHOAI"
        platformGateway = softwareSystem "Platform Gateway (Envoy)" "Ingress gateway for external traffic routing" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"

        s3 = softwareSystem "Amazon S3" "Model artifact storage" "External Cloud"
        azureBlob = softwareSystem "Azure Blob Storage" "Model artifact storage" "External Cloud"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage" "External Cloud"
        huggingface = softwareSystem "HuggingFace Hub" "Model download and metadata" "External Cloud"

        dataScientist -> kserve "Creates InferenceService CR"
        kserve -> ovms "Deploys and manages OVMS container"
        mlEngineer -> platformGateway "Sends inference requests" "HTTPS/443"
        platformGateway -> kubeRBACProxy "Routes to pod" "HTTPS/8443"
        kubeRBACProxy -> ovms "Proxies authenticated requests" "HTTP/configurable (plaintext)"
        prometheus -> ovms "Scrapes metrics" "HTTP /metrics"

        ovms -> s3 "Downloads model artifacts" "HTTPS/443 AWS IAM"
        ovms -> azureBlob "Downloads model artifacts" "HTTPS/443 Storage Keys"
        ovms -> gcs "Downloads model artifacts" "HTTPS/443 GCP SA"
        ovms -> huggingface "Downloads models and metadata" "HTTPS/443 HF Token"
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
            element "External Cloud" {
                background #f5a623
                shape RoundedBox
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

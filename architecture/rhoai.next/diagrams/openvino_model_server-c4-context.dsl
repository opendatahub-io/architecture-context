workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models via InferenceService"
        mlEngineer = person "ML Engineer" "Configures serving runtimes and model pipelines"
        sre = person "SRE / Platform Admin" "Monitors inference workloads and platform health"

        ovms = softwareSystem "OpenVINO Model Server" "High-performance C++ inference server for serving AI models via OpenAI-compatible, KServe v2, and TFS APIs using Intel OpenVINO" {
            httpFrontend = container "HTTP/REST Frontend" "Drogon-based HTTP server handling /v1/*, /v2/*, /v3/* API families" "C++ (Drogon)" "Port 8888/TCP"
            grpcFrontend = container "gRPC Frontend" "gRPC server for KServe v2 and TFS inference protocols" "C++ (gRPC)" "Port 8001/TCP"
            llmModule = container "LLM Module" "OpenAI-compatible chat/completions with continuous batching" "C++ MediaPipe Calculator"
            embeddingsModule = container "Embeddings Module" "OpenAI-compatible text embeddings" "C++ MediaPipe Calculator"
            rerankModule = container "Rerank Module" "Cohere-compatible document reranking" "C++ MediaPipe Calculator"
            imageGenModule = container "Image Generation Module" "OpenAI-compatible image generation" "C++ MediaPipe Calculator"
            audioModules = container "Audio Modules" "Speech-to-text and text-to-speech" "C++ MediaPipe Calculators"
            servableManager = container "Servable Manager" "Model loading, lifecycle management, and hot-reloading" "C++"
            dagScheduler = container "DAG Scheduler" "Directed Acyclic Graph inference pipeline engine" "C++"
            mediapipe = container "MediaPipe Integration" "Graph-based orchestration for GenAI workloads" "C++ (MediaPipe)"
            metricsModule = container "Metrics Module" "Prometheus-compatible metrics collection and exposition" "C++ (Prometheus Client)"
            storageBackends = container "Storage Backends" "Model storage abstraction for local, S3, GCS, Azure, HuggingFace" "C++ (AWS SDK, Azure SDK, GCS SDK, libgit2)"
            openvinoRuntime = container "OpenVINO Runtime" "Core inference engine for model compilation and execution" "C++ Library" "v2026.2"
            openvinoGenAI = container "OpenVINO GenAI" "LLM, VLM, embeddings, image gen, speech pipelines" "C++ Library" "v2026.2"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native model serving controller that deploys OVMS as a ServingRuntime" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Auth enforcement sidecar for RHOAI 3.x deployments" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "OpenShift AI Dashboard" "UI for managing ServingRuntimes and InferenceServices" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"

        s3 = softwareSystem "S3-Compatible Storage" "Object storage for ML model artifacts" "External"
        gcs = softwareSystem "Google Cloud Storage" "Object storage for ML model artifacts" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Object storage for ML model artifacts" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository for downloading pre-trained models" "External"
        openvinoUpstream = softwareSystem "OpenVINO Toolkit" "Intel's inference optimization toolkit (upstream)" "External"

        # User interactions
        dataScientist -> ovms "Sends inference requests via REST/gRPC"
        mlEngineer -> kserve "Creates InferenceService with OVMS ServingRuntime"
        sre -> prometheus "Monitors OVMS metrics"

        # Platform interactions
        kserve -> ovms "Deploys as ServingRuntime container in InferenceService pods"
        kubeRBACProxy -> ovms "Proxies authenticated requests to REST endpoint" "HTTPS/8443 → HTTP/8888"
        rhoaiDashboard -> kserve "Lists OVMS as available ServingRuntime"
        prometheus -> ovms "Scrapes /metrics endpoint" "HTTP/8888"

        # External service interactions
        ovms -> s3 "Loads model artifacts" "HTTPS/443, AWS IAM"
        ovms -> gcs "Loads model artifacts" "HTTPS/443, GCP SA"
        ovms -> azureBlob "Loads model artifacts" "HTTPS/443, Azure Key/SAS"
        ovms -> huggingface "Downloads models via git clone" "HTTPS/443, HF_TOKEN"

        # Internal container relationships
        httpFrontend -> servableManager "Routes inference requests"
        httpFrontend -> llmModule "Routes OpenAI chat/completions"
        httpFrontend -> embeddingsModule "Routes embeddings requests"
        httpFrontend -> rerankModule "Routes reranking requests"
        httpFrontend -> imageGenModule "Routes image generation requests"
        httpFrontend -> audioModules "Routes audio requests"
        grpcFrontend -> servableManager "Routes gRPC inference"
        llmModule -> mediapipe "Executes via MediaPipe graph"
        embeddingsModule -> mediapipe "Executes via MediaPipe graph"
        rerankModule -> mediapipe "Executes via MediaPipe graph"
        imageGenModule -> mediapipe "Executes via MediaPipe graph"
        audioModules -> mediapipe "Executes via MediaPipe graph"
        mediapipe -> openvinoGenAI "Calls GenAI pipelines"
        servableManager -> dagScheduler "Executes DAG pipelines"
        servableManager -> openvinoRuntime "Compiles and runs models"
        openvinoGenAI -> openvinoRuntime "Uses for inference execution"
        servableManager -> storageBackends "Loads models from storage"
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
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

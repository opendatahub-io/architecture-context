workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models for inference"
        application = person "Application / Client" "Sends inference requests to deployed models"

        ovms = softwareSystem "OpenVINO Model Server (OVMS)" "High-performance C++ inference server serving AI/ML models via gRPC, REST, and OpenAI-compatible APIs using Intel OpenVINO runtime" {
            restServer = container "REST Server" "Serves KServe v2, TFS, and OpenAI-compatible REST APIs" "C++ (HTTP)" "rest_port/TCP"
            grpcServer = container "gRPC Server" "Serves KServe v2 and TFS gRPC APIs" "C++ (gRPC)" "grpc_port/TCP"
            kfsInference = container "KServe v2 / TFS Inference Service" "Handles inference request routing and response formatting" "C++ Module"
            openaiHandler = container "OpenAI/Cohere API Handler" "Chat completions, embeddings, rerank via MediaPipe graphs" "C++ (MediaPipe)"
            llmEngine = container "LLM Continuous Batching Engine" "Text generation with dynamic batching" "C++ (OpenVINO GenAI)"
            modelManager = container "Model Manager" "Model lifecycle — loading, versioning, hot-reload" "C++ Module"
            modelPull = container "Model Pull Module" "Downloads models from HuggingFace Hub" "C++ (libgit2, curl)"
            metricsModule = container "Metrics Module" "Exposes Prometheus-compatible metrics" "C++ Module"
            openvinoRuntime = container "OpenVINO Runtime" "Core inference engine for model execution" "C++ Library" "2025.3"
        }

        kserve = softwareSystem "KServe" "Standardized ML inference platform — deploys OVMS as InferenceService runtime" "Internal RHOAI"
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform — deploys OVMS as serving runtime" "Internal RHOAI"
        authProxy = softwareSystem "Auth Proxy" "kube-rbac-proxy (3.x) / oauth-proxy (2.x) — TLS termination and auth enforcement" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        istio = softwareSystem "Istio Service Mesh" "mTLS between services, traffic management" "Internal Platform"

        s3 = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3, Ceph, MinIO)" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Model artifact storage" "External"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Public model repository" "External"
        toolEndpoints = softwareSystem "External Tool Endpoints" "External APIs for LLM function/tool calling" "External"

        # Relationships
        datascientist -> ovms "Deploys models and sends inference requests"
        application -> ovms "Sends inference requests via REST/gRPC"

        application -> authProxy "HTTPS/8443, Bearer Token / OAuth"
        authProxy -> ovms "HTTP/gRPC (plaintext, pre-authenticated)"

        ovms -> s3 "Downloads model artifacts" "HTTPS/443, AWS IAM"
        ovms -> azureBlob "Downloads model artifacts" "HTTPS/443, Azure Creds"
        ovms -> gcs "Downloads model artifacts" "HTTPS/443, GCP Creds"
        ovms -> huggingface "Downloads models" "HTTPS/443, HF Token"
        ovms -> toolEndpoints "LLM tool/function calls" "HTTPS, Bearer Token"

        kserve -> ovms "Deploys as InferenceService runtime container"
        modelmesh -> ovms "Deploys as ModelMesh serving runtime"
        istio -> ovms "Provides mTLS between services"
        prometheus -> ovms "Scrapes /metrics endpoint" "HTTP rest_port"

        # Internal container relationships
        restServer -> kfsInference "Routes KServe v2 / TFS requests"
        restServer -> openaiHandler "Routes /v3/* requests"
        grpcServer -> kfsInference "Routes gRPC inference requests"
        kfsInference -> modelManager "Resolves model, executes inference"
        openaiHandler -> llmEngine "Chat/completions requests"
        llmEngine -> openvinoRuntime "Token generation"
        modelManager -> openvinoRuntime "Model inference execution"
        modelManager -> modelPull "Triggers model download"
        modelPull -> huggingface "Git clone / HTTPS download"
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

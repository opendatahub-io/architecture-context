workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries ML/LLM models via InferenceService"
        sre = person "SRE / Platform Admin" "Monitors and operates the RHOAI platform"

        ovms = softwareSystem "OpenVINO Model Server" "High-performance C++ inference server hosting AI models via gRPC, REST, and OpenAI-compatible APIs using OpenVINO runtime" {
            restServer = container "REST Server" "HTTP server exposing TFS v1, KServe v2, and OpenAI v3 APIs" "C++ / Drogon"
            grpcServer = container "gRPC Server" "gRPC server for TFS and KServe v2 protocols" "C++ / gRPC"
            modelManager = container "Model Manager" "Model lifecycle management with version control, hot-reload, and multi-backend storage" "C++"
            llmPipeline = container "LLM Pipeline" "Continuous batching engine for text generation with streaming" "C++ / OpenVINO GenAI"
            vlmPipeline = container "VLM Pipeline" "Vision-language model inference combining image and text inputs" "C++ / OpenVINO GenAI"
            embeddingsEngine = container "Embeddings Engine" "Text embedding generation with pooling modes" "C++"
            rerankEngine = container "Reranking Engine" "Document relevance scoring and reranking" "C++"
            imageGenEngine = container "Image Generation Engine" "Diffusion pipeline for image generation" "C++"
            audioEngine = container "Audio Engine" "Speech-to-text (Whisper) and text-to-speech" "C++"
            mediapipeExecutor = container "MediaPipe Graph Executor" "Custom DAG pipeline execution" "C++ / MediaPipe"
            hfPullModule = container "HuggingFace Pull Module" "Model downloading from HuggingFace Hub via Git LFS" "C++ / libgit2"
            metricsModule = container "Metrics Module" "Prometheus-compatible metrics collection" "C++ / Prometheus Client"
            capi = container "C API Library" "libovms_shared.so for embedding OVMS in other applications" "C++ Shared Library"
        }

        # Platform systems
        kserve = softwareSystem "KServe" "Manages InferenceService pod lifecycle, scaling, and routing" "Internal RHOAI"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Manages ServingRuntime CRs and platform configuration" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar for external access control" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "Internal Platform"

        # External systems
        openvinoRuntime = softwareSystem "OpenVINO Runtime" "Core inference engine for model execution on Intel CPU/GPU/NPU" "Linked Library"
        openvinoGenAI = softwareSystem "OpenVINO GenAI SDK" "LLM continuous batching, tokenizer, text generation" "Linked Library"
        s3 = softwareSystem "Amazon S3" "Model artifact cloud storage" "External Cloud"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact cloud storage" "External Cloud"
        azure = softwareSystem "Azure Blob Storage" "Model artifact cloud storage" "External Cloud"
        huggingface = softwareSystem "HuggingFace Hub" "Public model repository with Git LFS" "External Cloud"

        # Relationships - User
        datascientist -> ovms "Sends inference requests via" "HTTPS/8443 (via kube-rbac-proxy)"
        sre -> prometheus "Monitors OVMS via" "Grafana Dashboards"

        # Relationships - Internal containers
        restServer -> modelManager "Routes inference to"
        grpcServer -> modelManager "Routes inference to"
        restServer -> llmPipeline "Dispatches LLM requests"
        restServer -> vlmPipeline "Dispatches VLM requests"
        restServer -> embeddingsEngine "Dispatches embedding requests"
        restServer -> rerankEngine "Dispatches reranking requests"
        restServer -> imageGenEngine "Dispatches image gen requests"
        restServer -> audioEngine "Dispatches audio requests"
        modelManager -> hfPullModule "Triggers model downloads"
        metricsModule -> restServer "Exposes /metrics via"

        # Relationships - Platform
        kserve -> ovms "Manages pod lifecycle" "Kubernetes API"
        rhoaiOperator -> kserve "Configures ServingRuntime CR" "Kubernetes API"
        kubeRbacProxy -> restServer "Forwards authenticated requests" "HTTP localhost"
        prometheus -> ovms "Scrapes metrics" "HTTP /metrics"

        # Relationships - Runtime
        modelManager -> openvinoRuntime "Executes inference via" "Function call (linked)"
        llmPipeline -> openvinoGenAI "Text generation via" "Function call (linked)"
        vlmPipeline -> openvinoGenAI "Multimodal inference via" "Function call (linked)"
        openvinoGenAI -> openvinoRuntime "Delegates inference to" "Function call (linked)"

        # Relationships - External
        modelManager -> s3 "Downloads model artifacts" "HTTPS/443 AWS IAM"
        modelManager -> gcs "Downloads model artifacts" "HTTPS/443 OAuth2"
        modelManager -> azure "Downloads model artifacts" "HTTPS/443 Azure MI"
        hfPullModule -> huggingface "Clones model repos" "HTTPS/443 HF_TOKEN Git LFS"
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
            element "Linked Library" {
                background #0d47a1
                color #ffffff
            }
            element "Person" {
                shape Person
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

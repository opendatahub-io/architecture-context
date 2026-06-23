workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for inference"
        application = person "Client Application" "Sends inference requests to model endpoints"

        ovms = softwareSystem "OpenVINO Model Server (OVMS)" "High-performance AI model inference server built on OpenVINO, exposing TFS, KServe v2, and OpenAI-compatible APIs over gRPC and REST" {
            httpServer = container "HTTP Server (Drogon)" "REST API handler for TFS, KServe v2, OpenAI, and metrics endpoints" "C++ / Drogon" "Port 8080/TCP"
            grpcServer = container "gRPC Server" "TFS and KServe v2 gRPC inference services" "C++ / gRPC" "Port 8443/TCP"
            modelManager = container "Model Manager" "Model lifecycle management, versioning, hot-reload, cloud storage backends" "C++"
            mediapipeExecutor = container "MediaPipe Graph Executor" "Node-based pipeline framework for LLM, embeddings, rerank, image gen, audio" "C++ / MediaPipe"
            llmServable = container "LLM Servable" "OpenAI-compatible chat/completion serving with continuous batching" "C++ / OpenVINO GenAI"
            embeddingsServable = container "Embeddings Servable" "Text embedding generation with OpenAI API compatibility" "C++ / OpenVINO GenAI"
            rerankServable = container "Rerank Servable" "Document reranking with Cohere API compatibility" "C++ / OpenVINO GenAI"
            imageGenServable = container "Image Gen Servable" "Text-to-image, image-to-image, inpainting" "C++ / OpenVINO GenAI"
            speechToText = container "Speech-to-Text" "Whisper-based speech recognition" "C++ / OpenVINO GenAI"
            textToSpeech = container "Text-to-Speech" "Speech synthesis with speaker embeddings" "C++ / OpenVINO GenAI"
            pythonBackend = container "Python Backend" "pybind11-based Python execution for Jinja2 templates and custom nodes" "C++ / pybind11"
            metricsModule = container "Metrics Module" "Prometheus-compatible metrics collection and exposure" "C++"
            hfPullModule = container "HF Pull Module" "Hugging Face model downloading via git clone, Optimum CLI, or GGUF" "C++ / libgit2"
        }

        openvinoRuntime = softwareSystem "OpenVINO Runtime" "Intel's inference engine for model compilation and execution" "External"
        openvinoGenAI = softwareSystem "OpenVINO GenAI" "LLM pipeline with continuous batching, tokenization, image gen, audio" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform - deploys OVMS as ServingRuntime" "Internal RHOAI"
        rhoaiGateway = softwareSystem "RHOAI Gateway (Envoy)" "Platform ingress for TLS termination and traffic routing" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization sidecar for RHOAI deployments" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics scraping and monitoring" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO, Ceph)" "External"
        gcsStorage = softwareSystem "Google Cloud Storage" "Model artifact storage on GCP" "External"
        azureStorage = softwareSystem "Azure Blob/File Storage" "Model artifact storage on Azure" "External"
        hfHub = softwareSystem "Hugging Face Hub" "Model repository for downloading and converting models" "External"

        # System-level relationships
        application -> ovms "Sends inference requests" "HTTPS/443 via Gateway, gRPC/8443"
        dataScientist -> kserve "Creates InferenceService CR" "kubectl"
        kserve -> ovms "Deploys as ServingRuntime container"
        rhoaiGateway -> ovms "Routes external traffic" "HTTPS/443 → HTTP/8080"
        kubeRbacProxy -> ovms "Enforces auth" "HTTPS/8443 → HTTP/8080"
        ovms -> openvinoRuntime "Compiles and runs models" "In-process C++ API"
        ovms -> openvinoGenAI "LLM/embedding/image/audio pipelines" "In-process C++ API"
        ovms -> s3Storage "Downloads model artifacts" "HTTPS/443, AWS IAM"
        ovms -> gcsStorage "Downloads model artifacts" "HTTPS/443, GCS SA"
        ovms -> azureStorage "Downloads model artifacts" "HTTPS/443, Connection String"
        ovms -> hfHub "Pulls models" "HTTPS/443, HF_TOKEN"
        prometheus -> ovms "Scrapes metrics" "HTTP/8080 /metrics"

        # Container-level relationships
        httpServer -> modelManager "TFS/KServe inference requests"
        httpServer -> mediapipeExecutor "OpenAI API requests"
        grpcServer -> modelManager "gRPC inference requests"
        mediapipeExecutor -> llmServable "Chat/completion requests"
        mediapipeExecutor -> embeddingsServable "Embedding requests"
        mediapipeExecutor -> rerankServable "Reranking requests"
        mediapipeExecutor -> imageGenServable "Image generation requests"
        mediapipeExecutor -> speechToText "Audio transcription requests"
        mediapipeExecutor -> textToSpeech "Speech synthesis requests"
        llmServable -> pythonBackend "Jinja2 chat template processing"
        modelManager -> hfPullModule "Model downloading"
        httpServer -> metricsModule "Metrics exposure"
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

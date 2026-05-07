workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries ML/AI models for inference"
        application = person "Application" "External application consuming inference APIs"

        ovms = softwareSystem "OpenVINO Model Server" "High-performance AI model inference server optimized for Intel architectures. Serves models via gRPC, REST (TFS v1, KServe v2, OpenAI-compatible, Cohere reranking, image generation)." {
            drogonServer = container "Drogon HTTP Server" "Serves REST API endpoints for TFS v1, KServe v2, OpenAI v1, Cohere, and v3 image generation" "C++ / Drogon Framework"
            grpcServer = container "gRPC Server" "Serves TFS PredictionService, ModelService, and KServe GRPCInferenceService with streaming" "C++ / gRPC"
            modelManager = container "Model Manager" "Manages model lifecycle: loading, versioning, configuration, hot-reload" "C++"
            mediapipeExecutor = container "MediaPipe Graph Executor" "Executes composable inference pipelines via DAG graphs for LLM, embeddings, reranking, image gen, audio" "C++ / MediaPipe"
            openvinoRuntime = container "OpenVINO Runtime 2026.0" "Model inference engine with CPU/GPU/NPU acceleration" "C++ / OpenVINO"
            openvinoGenAI = container "OpenVINO GenAI" "Generative AI extensions: continuous batching, LLM/VLM serving" "C++ / OpenVINO GenAI"
            openvinoTokenizers = container "OpenVINO Tokenizers" "Tokenization support for NLP models" "C++ / OpenVINO Tokenizers"
            filesystemFactory = container "Filesystem Factory" "Abstraction layer for model storage: local, S3, Azure, GCS, HuggingFace" "C++"
            metricsExporter = container "Prometheus Metrics" "Exports server and model metrics in Prometheus format on /metrics" "C++ / prometheus-cpp"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native serverless ML inference platform" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS, traffic management, and TLS termination" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        s3 = softwareSystem "AWS S3" "Object storage for ML model artifacts" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Object storage for ML model artifacts" "External"
        gcs = softwareSystem "Google Cloud Storage" "Object storage for ML model artifacts" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository hosting pre-trained models" "External"
        gpuDrivers = softwareSystem "Intel GPU Drivers" "GPU compute drivers for hardware acceleration" "External"

        # User interactions
        datascientist -> kserve "Deploys InferenceService CR" "kubectl"
        application -> ovms "Inference requests" "REST/gRPC via Istio"

        # System interactions
        kserve -> ovms "Routes inference requests using KServe v2 protocol" "gRPC/REST"
        istio -> ovms "TLS termination, mTLS proxy" "Envoy sidecar"
        prometheus -> ovms "Scrapes /metrics endpoint" "HTTP"
        ovms -> s3 "Downloads model artifacts" "HTTPS/443"
        ovms -> azureBlob "Downloads model artifacts" "HTTPS/443"
        ovms -> gcs "Downloads model artifacts" "HTTPS/443"
        ovms -> huggingface "Downloads models via libgit2" "HTTPS/443"
        ovms -> gpuDrivers "GPU-accelerated inference" "Device API"

        # Container relationships
        drogonServer -> modelManager "Routes traditional inference requests"
        drogonServer -> mediapipeExecutor "Routes GenAI requests (LLM, embeddings, rerank, image gen)"
        grpcServer -> modelManager "Routes gRPC inference requests"
        grpcServer -> mediapipeExecutor "Routes streaming LLM requests"
        modelManager -> openvinoRuntime "Executes model inference"
        modelManager -> filesystemFactory "Resolves model storage paths"
        mediapipeExecutor -> openvinoGenAI "Executes GenAI inference with continuous batching"
        mediapipeExecutor -> openvinoRuntime "Executes standard model inference"
        openvinoGenAI -> openvinoRuntime "Uses for underlying model execution"
        openvinoGenAI -> openvinoTokenizers "Uses for tokenization"
        filesystemFactory -> s3 "Downloads models" "HTTPS/443 AWS IAM"
        filesystemFactory -> azureBlob "Downloads models" "HTTPS/443 Azure SDK"
        filesystemFactory -> gcs "Downloads models" "HTTPS/443 GCS SA"
        filesystemFactory -> huggingface "Clones model repos" "HTTPS/443 libgit2"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

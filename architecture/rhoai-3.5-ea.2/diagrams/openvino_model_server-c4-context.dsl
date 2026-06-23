workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for inference"
        appDeveloper = person "Application Developer" "Integrates inference APIs into applications"

        ovms = softwareSystem "OpenVINO Model Server" "High-performance C++ inference serving system with gRPC/REST APIs using OpenVINO backend" {
            tfsFrontend = container "TFS Frontend" "TensorFlow Serving compatible gRPC/REST API for predict, classify, regress" "C++ gRPC Service"
            kserveFrontend = container "KServe Frontend" "KServe Inference Protocol v2 with streaming support" "C++ gRPC Service"
            httpHandler = container "HTTP REST Handler" "Central HTTP dispatcher for OpenAI-compatible API, embeddings, rerank, audio, image gen" "C++ Drogon Service"
            llmEngine = container "LLM Engine" "Text generation with continuous batching and speculative decoding" "C++ Module (OpenVINO GenAI)"
            vlmEngine = container "VLM Engine" "Visual language model inference combining image and text" "C++ Module (OpenVINO GenAI)"
            embeddingsModule = container "Embeddings Module" "OpenAI-compatible text embedding generation" "C++ Module"
            rerankModule = container "Rerank Module" "Cohere-compatible document relevance ranking" "C++ Module"
            sttModule = container "Audio STT Module" "Speech-to-text via WhisperPipeline" "C++ Module (OpenVINO GenAI)"
            ttsModule = container "Audio TTS Module" "Text-to-speech via Text2SpeechPipeline" "C++ Module (OpenVINO GenAI)"
            imageGenModule = container "Image Generation Module" "Text-to-image, image-to-image, inpainting" "C++ Module (OpenVINO GenAI)"
            mediapipe = container "MediaPipe Graph Executor" "Complex multi-step inference pipelines" "C++ Module (MediaPipe)"
            dagScheduler = container "DAG Pipeline Scheduler" "Directed acyclic graph for chained multi-model inference" "C++ Module"
            modelManager = container "Model Manager" "Model lifecycle with versioning, hot-reload, cloud storage backends" "C++ Module"
            metricsModule = container "Metrics Module" "Prometheus-compatible metrics" "C++ Module"
            hfPull = container "HuggingFace Pull Module" "Model downloading from HuggingFace Hub with GGUF support" "C++ Module"
            capi = container "C API" "Embeddable inference library (libovms_shared.so)" "C Shared Library"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Kubernetes-native model serving platform" "Internal RHOAI"
        openvinoRuntime = softwareSystem "OpenVINO Runtime" "Neural network inference engine (opendatahub-io fork)" "External Library"
        openvinoGenAI = softwareSystem "OpenVINO GenAI" "LLM/VLM/STT/TTS pipeline execution" "External Library"
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (S3, MinIO, Ceph)" "External"
        azureStorage = softwareSystem "Azure Blob Storage" "Model artifact storage" "External"
        gcsStorage = softwareSystem "Google Cloud Storage" "Model artifact storage" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model repository and download service" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        platformGateway = softwareSystem "Platform Gateway (Envoy)" "TLS termination and routing" "Internal RHOAI"

        dataScientist -> ovms "Deploys models and sends inference requests"
        appDeveloper -> ovms "Sends inference requests via REST/gRPC APIs"

        dataScientist -> kserve "Creates InferenceService CRs via kubectl"
        kserve -> ovms "Manages as serving container in InferenceService pods"

        appDeveloper -> platformGateway "Sends requests" "HTTPS/443"
        platformGateway -> ovms "Routes inference requests" "HTTP/gRPC (via kube-rbac-proxy)"

        ovms -> openvinoRuntime "Executes neural network inference" "C++ API (in-process)"
        ovms -> openvinoGenAI "Runs LLM/VLM/STT/TTS pipelines" "C++ API (in-process)"
        ovms -> s3Storage "Downloads model artifacts" "HTTPS/443, AWS IAM"
        ovms -> azureStorage "Downloads model artifacts" "HTTPS/443, Azure Key"
        ovms -> gcsStorage "Downloads model artifacts" "HTTPS/443, GCS SA"
        ovms -> hfHub "Downloads models and GGUF files" "HTTPS/443, HF Token"
        prometheus -> ovms "Scrapes metrics" "HTTP /metrics"
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
            element "External Library" {
                background #e74c3c
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

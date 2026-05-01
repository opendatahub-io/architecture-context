workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models and sends inference requests"
        mlEngineer = person "ML Engineer" "Configures model serving pipelines and DAGs"

        ovms = softwareSystem "OpenVINO Model Server" "High-performance C++ inference server supporting TFS v1, KServe v2, and OpenAI-compatible APIs" {
            grpcFrontend = container "gRPC Frontend" "Serves TFS PredictionService, ModelService, and KServe GRPCInferenceService" "C++ gRPC"
            httpFrontend = container "HTTP/REST Frontend" "Serves TFS v1, KServe v2, OpenAI-compatible, and v3 REST APIs" "C++ Drogon"
            modelManager = container "Model Manager" "Manages model lifecycle: loading, versioning, config monitoring, dynamic reloading" "C++"
            dagScheduler = container "DAG Scheduler" "Executes multi-step inference pipelines as directed acyclic graphs" "C++"
            mediaPipeExecutor = container "MediaPipe Graph Executor" "Executes calculator graphs for LLM, embeddings, reranking, image gen, audio" "C++ MediaPipe"
            llmEngine = container "LLM Engine" "Text generation via OpenVINO GenAI with continuous batching and legacy sequential" "C++ OpenVINO GenAI"
            embeddingsEngine = container "Embeddings Engine" "Text embedding generation with pooling and normalization" "C++"
            rerankEngine = container "Reranking Engine" "Document reranking with cross-encoder models" "C++"
            imageGenEngine = container "Image Generation Engine" "Image generation with configurable parameters" "C++"
            speechToText = container "Speech-to-Text Engine" "Audio transcription with optional word timestamps" "C++"
            textToSpeech = container "Text-to-Speech Engine" "Speech synthesis with multi-voice speaker embeddings" "C++"
            pythonBackend = container "Python Backend" "Embedded Python interpreter for custom Python nodes" "C++ pybind11"
            storageBackends = container "Storage Backends" "Filesystem abstraction for local, S3, GCS, Azure storage" "C++ AWS/GCS/Azure SDK"
            metricsModule = container "Metrics Module" "Prometheus-compatible metrics (request counts, latencies, queue depths)" "C++"
            modelPulling = container "Model Pulling Module" "Downloads models from HuggingFace Hub (libgit2) and GGUF files (curl)" "C++"
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform - deploys OVMS as InferenceService runtime" "Internal RHOAI"
        rhoaiPlatform = softwareSystem "RHOAI Platform" "Red Hat OpenShift AI platform managing ServingRuntime CRs" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal"

        s3 = softwareSystem "Amazon S3" "Cloud object storage for ML model artifacts" "External"
        gcs = softwareSystem "Google Cloud Storage" "Cloud object storage for ML model artifacts" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Cloud object storage for ML model artifacts" "External"
        azureFile = softwareSystem "Azure File Shares" "Cloud file storage for ML model artifacts" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Model repository hosting and GGUF file distribution" "External"
        openvinoRuntime = softwareSystem "OpenVINO Runtime" "Intel inference engine for model compilation and execution on CPU/GPU/NPU" "External"

        # User interactions
        dataScientist -> ovms "Sends inference requests via REST/gRPC"
        mlEngineer -> ovms "Configures models and DAG pipelines"
        dataScientist -> kserve "Creates InferenceService CRs"

        # Platform interactions
        kserve -> ovms "Deploys as model serving runtime" "KServe v2 Protocol"
        rhoaiPlatform -> kserve "Manages ServingRuntime CRs"
        prometheus -> ovms "Scrapes /metrics endpoint" "HTTP"

        # External service interactions
        ovms -> s3 "Downloads model artifacts" "HTTPS/443"
        ovms -> gcs "Downloads model artifacts" "HTTPS/443"
        ovms -> azureBlob "Downloads model artifacts" "HTTPS/443"
        ovms -> azureFile "Downloads model artifacts" "HTTPS/443"
        ovms -> huggingFace "Clones model repos, downloads GGUF" "HTTPS/443"
        ovms -> openvinoRuntime "Compiles and executes model inference" "In-process C++ API"

        # Internal container relationships
        httpFrontend -> modelManager "Routes inference requests"
        grpcFrontend -> modelManager "Routes inference requests"
        httpFrontend -> mediaPipeExecutor "Dispatches streaming/pipeline requests"
        grpcFrontend -> dagScheduler "Dispatches DAG pipeline requests"
        dagScheduler -> modelManager "Executes inference nodes"
        mediaPipeExecutor -> llmEngine "Text generation"
        mediaPipeExecutor -> embeddingsEngine "Embedding generation"
        mediaPipeExecutor -> rerankEngine "Document reranking"
        mediaPipeExecutor -> imageGenEngine "Image generation"
        mediaPipeExecutor -> speechToText "Audio transcription"
        mediaPipeExecutor -> textToSpeech "Speech synthesis"
        mediaPipeExecutor -> pythonBackend "Custom Python nodes"
        modelManager -> storageBackends "Downloads/syncs model files"
        modelPulling -> storageBackends "HuggingFace model download"
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
            element "Internal" {
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
                background #5ba8f7
                color #ffffff
            }
        }
    }
}

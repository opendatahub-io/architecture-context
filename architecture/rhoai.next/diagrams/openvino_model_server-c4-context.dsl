workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models and sends inference requests"
        mlEngineer = person "ML Engineer" "Builds and optimizes model serving pipelines"
        sre = person "SRE / Platform Admin" "Monitors and manages the inference platform"

        ovms = softwareSystem "OpenVINO Model Server" "High-performance C++ inference server supporting TFS, KServe v2, and OpenAI APIs" {
            drogonHTTP = container "Drogon HTTP Server" "Async HTTP server serving REST APIs (TFS v1, KServe v2, OpenAI, v3)" "C++ (Drogon Framework)"
            grpcServer = container "gRPC Server" "Serves TFS PredictionService, ModelService, KServe GRPCInferenceService" "C++ (gRPC)"
            modelManager = container "Model Manager" "Manages model lifecycle: loading, versioning, config watching, dynamic reloading" "C++"
            mediapipeExecutor = container "MediaPipe Graph Executor" "Executes calculator graphs for LLM, embeddings, reranking, image gen, audio" "C++ (MediaPipe)"
            llmEngine = container "LLM Engine" "Text generation with continuous batching, speculative decoding, prefix caching" "C++ (OpenVINO GenAI)"
            embeddingsEngine = container "Embeddings Engine" "Text embedding generation with CLS/LAST/MEAN pooling" "C++"
            rerankEngine = container "Reranking Engine" "Document reranking with cross-encoder models" "C++"
            dagScheduler = container "DAG Scheduler" "Executes multi-step inference pipelines as directed acyclic graphs" "C++"
            storageBackends = container "Storage Backends" "Filesystem abstraction for local, S3, GCS, Azure Blob/File" "C++ (AWS/GCS/Azure SDKs)"
            modelPulling = container "Model Pulling Module" "Downloads models from HuggingFace Hub (libgit2/curl)" "C++"
            metricsModule = container "Metrics Module" "Prometheus-compatible metrics (request counts, latencies, queue depths)" "C++"
            pythonBackend = container "Python Backend" "Embedded Python interpreter for custom nodes in MediaPipe graphs" "C++ (pybind11)"
        }

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform on Kubernetes" "Internal RHOAI"
        rhoaiPlatform = softwareSystem "RHOAI Platform" "Red Hat OpenShift AI platform (ServingRuntime CRs, Dashboard)" "Internal RHOAI"
        openvinoRuntime = softwareSystem "OpenVINO Runtime" "Intel inference engine for model compilation and execution (CPU, GPU, NPU)" "External"
        openvinoGenAI = softwareSystem "OpenVINO GenAI" "LLM pipeline library (continuous batching, tokenization, streaming)" "External"

        s3 = softwareSystem "Amazon S3" "Model artifact storage" "External"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Model artifact storage" "External"
        azureFile = softwareSystem "Azure File Shares" "Model artifact storage" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository hosting" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"

        # Person relationships
        dataScientist -> ovms "Sends inference requests (REST/gRPC)" "HTTPS/gRPC"
        mlEngineer -> rhoaiPlatform "Configures InferenceService with OVMS runtime" "kubectl/Dashboard"
        sre -> prometheus "Monitors inference metrics" "HTTP"

        # Platform relationships
        kserve -> ovms "Deploys as KServe v2 model runtime" "Runtime contract"
        rhoaiPlatform -> kserve "Creates InferenceService referencing OVMS ServingRuntime" "Kubernetes API"

        # Internal container relationships
        drogonHTTP -> modelManager "Routes inference requests"
        drogonHTTP -> mediapipeExecutor "Dispatches LLM/embedding/rerank requests"
        grpcServer -> modelManager "Routes gRPC inference requests"
        grpcServer -> mediapipeExecutor "Dispatches streaming requests"
        mediapipeExecutor -> llmEngine "Executes LLM calculator nodes"
        mediapipeExecutor -> embeddingsEngine "Executes embedding calculator nodes"
        mediapipeExecutor -> rerankEngine "Executes reranking calculator nodes"
        mediapipeExecutor -> pythonBackend "Executes Python calculator nodes"
        modelManager -> dagScheduler "Dispatches DAG pipeline requests"
        modelManager -> storageBackends "Loads model artifacts"
        modelManager -> openvinoRuntime "Compiles and executes models" "In-process C++ API"
        llmEngine -> openvinoGenAI "Runs LLM pipelines" "In-process C++ API"
        modelPulling -> huggingface "Clones model repositories" "HTTPS/443"

        # External service relationships
        storageBackends -> s3 "Downloads model artifacts" "HTTPS/443 AWS IAM"
        storageBackends -> gcs "Downloads model artifacts" "HTTPS/443 ADC"
        storageBackends -> azureBlob "Downloads model artifacts" "HTTPS/443 Conn String"
        storageBackends -> azureFile "Downloads model artifacts" "HTTPS/443 Conn String"
        metricsModule -> prometheus "Exposes /metrics endpoint" "HTTP"
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
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

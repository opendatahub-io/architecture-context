workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models via KServe InferenceService"
        mlEngineer = person "ML Engineer" "Configures model serving pipelines and LoRA adapters"

        ovms = softwareSystem "OpenVINO Model Server (OVMS)" "High-performance C++ inference server with OpenAI-compatible, KServe, and TF Serving APIs optimized for Intel architectures" {
            httpFrontend = container "HTTP Frontend" "Drogon-based HTTP/REST server exposing v1/v2/v3 API endpoints" "C++ (Drogon)"
            grpcFrontend = container "gRPC Frontend" "gRPC server supporting KServe and TF Serving protocols" "C++ (gRPC)"
            servableManager = container "Servable Manager" "Model lifecycle management, version policy, and hot-reload" "C++ Module"
            dagEngine = container "DAG Pipeline Engine" "Directed Acyclic Graph scheduler for multi-model pipelines" "C++ Module"
            mediaPipeIntegration = container "MediaPipe Integration" "Streaming graph-based pipeline execution for v3 generative tasks" "C++ (MediaPipe)"
            pythonInterpreter = container "Python Interpreter" "Python code execution within pipelines via pybind11" "C++ / Python 3.12"
            hfPullModule = container "HuggingFace Pull Module" "Model downloading from HuggingFace Hub with Git LFS and GGUF support" "C++ (libgit2/curl)"
            filesystemAbstraction = container "Filesystem Abstraction" "Pluggable storage backends for model loading" "C++ Module"
            metricModule = container "Metric Module" "Prometheus metrics collection and exposition at /metrics" "C++ Module"
            capiLibrary = container "libovms_shared.so" "C API for embedding OVMS inference in other applications" "C++ Shared Library"

            httpFrontend -> servableManager "Routes v1/v2 requests"
            httpFrontend -> mediaPipeIntegration "Routes v3 requests"
            grpcFrontend -> servableManager "Routes gRPC requests"
            servableManager -> filesystemAbstraction "Loads models from storage"
            dagEngine -> servableManager "Orchestrates multi-model inference"
            mediaPipeIntegration -> pythonInterpreter "Executes Python nodes"
            hfPullModule -> filesystemAbstraction "Stores downloaded models"
        }

        openvinoRuntime = softwareSystem "OpenVINO Runtime" "Intel's core inference engine for model execution (v2026.2)" "External"
        openvinoGenAI = softwareSystem "OpenVINO GenAI" "LLM continuous batching and generative task execution (v2026.2)" "External"
        openvinoTokenizers = softwareSystem "OpenVINO Tokenizers" "Tokenizer support for LLM pipelines (v2026.2)" "External"

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform managing InferenceService pods" "Internal RHOAI"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Red Hat OpenShift AI operator managing ServingRuntime custom resources" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"

        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model repository for downloading pre-trained models and LoRA adapters" "External"
        awsS3 = softwareSystem "AWS S3" "Amazon S3 object storage for model artifacts" "External"
        googleCloudStorage = softwareSystem "Google Cloud Storage" "GCS object storage for model artifacts" "External"
        azureBlobStorage = softwareSystem "Azure Blob Storage" "Azure object storage for model artifacts" "External"
        intelGPU = softwareSystem "Intel GPU (OpenCL)" "GPU inference acceleration via OpenCL driver" "External"

        dataScientist -> ovms "Sends inference requests (HTTP/gRPC)" "HTTPS/443 via Platform Ingress"
        mlEngineer -> kserve "Creates InferenceService with OVMS ServingRuntime" "kubectl / RHOAI Dashboard"

        kserve -> ovms "Runs OVMS as container in InferenceService pod" "Container Runtime"
        rhoaiOperator -> ovms "References OVMS image in ServingRuntime CR" "Container Image Reference"

        ovms -> openvinoRuntime "Executes model inference" "In-process C++ API"
        ovms -> openvinoGenAI "Generates LLM tokens with continuous batching" "In-process C++ API"
        ovms -> openvinoTokenizers "Tokenizes input for LLM pipelines" "In-process shared library"
        ovms -> huggingfaceHub "Downloads models and LoRA adapters" "HTTPS/443 (libgit2/curl)"
        ovms -> awsS3 "Loads model artifacts" "HTTPS/443 (AWS SDK)"
        ovms -> googleCloudStorage "Loads model artifacts" "HTTPS/443 (GCS SDK)"
        ovms -> azureBlobStorage "Loads model artifacts" "HTTPS/443 (Azure SDK)"
        ovms -> intelGPU "Accelerates inference on Intel GPUs" "OpenCL driver"
        prometheus -> ovms "Scrapes metrics" "HTTP GET /metrics"
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
                background #4a90e2
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

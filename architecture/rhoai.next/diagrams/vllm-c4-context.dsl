workspace {
    model {
        user = person "Data Scientist / Application" "Sends inference requests to deployed models"

        vllm = softwareSystem "vLLM Inference Server" "GPU-accelerated LLM inference with dual-protocol support (OpenAI HTTP + TGIS gRPC)" {
            adapter = container "vllm_tgis_adapter" "Bridges vLLM OpenAI API with TGIS gRPC protocol" "Python Module"
            engine = container "vLLM Engine" "High-throughput LLM inference engine with PagedAttention" "Python / CUDA"
        }

        kserve = softwareSystem "KServe" "Deploys and manages InferenceService pods using this container as a model serving runtime" "Internal RHOAI"
        modelController = softwareSystem "ODH Model Controller" "Orchestrates lifecycle of model serving infrastructure" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS encryption and auth enforcement for all traffic" "External"
        gpuPlugin = softwareSystem "NVIDIA GPU Device Plugin" "Allocates GPU resources to inference pods via Kubernetes device plugin" "External"
        modelStorage = softwareSystem "Model Storage (S3 / PVC)" "Stores model weight artifacts for loading at startup" "External"
        huggingface = softwareSystem "Hugging Face Hub" "Public model repository for downloading model weights" "External"
        konflux = softwareSystem "Konflux / Tekton" "CI/CD build pipeline for producing the vllm-cuda container image" "External"
        rhaiis = softwareSystem "RHAIIS Base Image" "Provides vLLM, TGIS adapter, CUDA runtime, and all Python dependencies" "External"

        user -> vllm "Sends inference requests" "HTTP/8000, gRPC/8033"
        kserve -> vllm "Deploys as InferenceService runtime container"
        modelController -> kserve "Orchestrates model serving lifecycle"
        vllm -> istio "Traffic encrypted and authenticated via sidecar" "mTLS"
        vllm -> gpuPlugin "Uses GPU resources for CUDA inference"
        vllm -> modelStorage "Loads model weights at startup" "HTTPS/443, filesystem"
        vllm -> huggingface "Downloads models when not using local storage" "HTTPS/443"
        konflux -> vllm "Builds container image from Dockerfile" "Tekton pipeline"
        rhaiis -> vllm "Provides base image with all runtime dependencies" "FROM directive"
    }

    views {
        systemContext vllm "SystemContext" {
            include *
            autoLayout
        }

        container vllm "Containers" {
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

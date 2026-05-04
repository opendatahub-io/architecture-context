workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        application = person "Application Client" "Sends inference requests via OpenAI-compatible or TGIS gRPC API"

        vllm = softwareSystem "vLLM CUDA Runtime" "GPU-accelerated LLM inference runtime with dual-protocol support (OpenAI HTTP + TGIS gRPC)" {
            vllmEngine = container "vLLM Inference Engine" "Serves OpenAI-compatible HTTP API for text/chat completions" "Python / CUDA" "Component"
            tgisAdapter = container "vllm_tgis_adapter" "gRPC-to-HTTP bridge exposing TGIS GenerationService protocol" "Python" "Component"
            cudaRuntime = container "CUDA Runtime" "GPU computation for model inference" "NVIDIA CUDA" "Component"
        }

        kserve = softwareSystem "KServe" "Manages model serving lifecycle via ServingRuntime and InferenceService CRs" "Internal Platform"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, and ingress gateway" "Internal Platform"
        nvidiaPlugin = softwareSystem "NVIDIA GPU Device Plugin" "Allocates GPU resources to inference pods" "Internal Platform"
        modelRegistry = softwareSystem "Model Storage" "Stores LLM model weights (S3, PVC, or Hugging Face Hub)" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Public model and tokenizer repository" "External"
        konflux = softwareSystem "Konflux Build System" "Multi-arch container image builds and vulnerability scanning" "External"
        rhaiis = softwareSystem "RHAIIS Base Image" "Provides pre-built vLLM engine, CUDA runtime, Python env, and TGIS adapter" "External"

        # Relationships
        application -> kserve "Sends inference requests" "HTTPS/443"
        dataScientist -> kserve "Creates InferenceService CRs" "kubectl / API"
        kserve -> vllm "Deploys as inference container in ServingRuntime pods"
        kserve -> istio "Uses for traffic routing and mTLS"
        istio -> vllm "Forwards requests with mTLS" "HTTP/8000, gRPC/8033"

        vllm -> modelRegistry "Downloads model weights at startup" "HTTPS/443"
        vllm -> huggingFace "Downloads models and tokenizer configs" "HTTPS/443"
        vllm -> nvidiaPlugin "Requests GPU resources" "nvidia.com/gpu"

        rhaiis -> vllm "Provides base image with all runtime components" "Container inheritance"
        konflux -> vllm "Builds multi-arch container image" "Tekton pipeline"

        # Internal container relationships
        tgisAdapter -> vllmEngine "Bridges gRPC to HTTP" "HTTP/8000 localhost"
        vllmEngine -> cudaRuntime "Runs inference computations" "CUDA API"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Component" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

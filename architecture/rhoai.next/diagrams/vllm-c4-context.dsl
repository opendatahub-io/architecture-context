workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for inference"
        applicationDev = person "Application Developer" "Integrates inference APIs into applications"

        vllm = softwareSystem "vLLM CUDA Runtime" "GPU-accelerated LLM inference runtime with dual-protocol support (OpenAI HTTP + TGIS gRPC), packaged as RHOAI container image" {
            vllmEngine = container "vLLM HTTP Server" "OpenAI-compatible inference engine with GPU acceleration" "Python / CUDA" "Port 8000/TCP"
            tgisAdapter = container "vllm_tgis_adapter" "gRPC-to-HTTP bridge implementing TGIS GenerationService protocol" "Python" "Port 8033/TCP"
        }

        kserve = softwareSystem "KServe" "Model serving platform that manages ServingRuntime and InferenceService lifecycle" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, and ingress gateway" "Internal Platform"
        gpuPlugin = softwareSystem "NVIDIA GPU Device Plugin" "Allocates GPU resources to pods via nvidia.com/gpu resource requests" "External"
        rhaiis = softwareSystem "RHAIIS Base Image" "Pre-built vLLM CUDA base image (registry.redhat.io/rhaiis/vllm-cuda-rhel9:3.2.2) providing runtime, CUDA libs, and TGIS adapter" "External"
        s3 = softwareSystem "S3 Storage" "Object storage for LLM model weights" "External"
        pvc = softwareSystem "PVC Storage" "Persistent volume for local model weights" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Model registry for downloading weights and tokenizer configs" "External"
        konflux = softwareSystem "Konflux Build System" "Multi-arch container image build and vulnerability scanning pipeline" "External"

        dataScientist -> kserve "Creates InferenceService CR via kubectl/dashboard"
        applicationDev -> vllm "Sends inference requests" "HTTPS/443"

        kserve -> vllm "Deploys and manages as ServingRuntime container"
        istio -> vllm "Injects sidecar for mTLS and traffic management"
        gpuPlugin -> vllm "Allocates NVIDIA GPU resources"
        rhaiis -> vllm "Provides base container image with vLLM + CUDA + TGIS adapter"

        vllm -> s3 "Downloads model weights at startup" "HTTPS/443 TLS 1.2+ IAM"
        vllm -> pvc "Reads model weights from volume mount" "Filesystem"
        vllm -> huggingFace "Downloads model weights and tokenizer configs" "HTTPS/443 TLS 1.2+"

        konflux -> vllm "Builds multi-arch container image (amd64/arm64)"

        tgisAdapter -> vllmEngine "Bridges gRPC to HTTP" "HTTP/8000 localhost"
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

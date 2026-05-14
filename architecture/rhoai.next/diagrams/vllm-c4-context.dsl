workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for inference"
        application = person "Application / Service" "Sends inference requests to deployed models"

        vllm = softwareSystem "vLLM CUDA Runtime" "GPU-accelerated LLM inference runtime with TGIS gRPC adapter, built on RHAIIS base image" {
            vllmEngine = container "vLLM HTTP Server" "OpenAI-compatible inference API serving LLM predictions" "Python / CUDA" "Port 8000/TCP"
            tgisAdapter = container "vllm_tgis_adapter" "gRPC-to-HTTP bridge exposing TGIS-compatible GenerationService" "Python" "Port 8033/TCP"
            cudaRuntime = container "CUDA Runtime" "GPU compute runtime for model inference" "NVIDIA CUDA"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform managing InferenceService lifecycle" "Internal ODH"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS, traffic management, and auth enforcement" "Internal ODH"
        gpuPlugin = softwareSystem "NVIDIA GPU Device Plugin" "Kubernetes device plugin for GPU resource allocation" "External"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and version information" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science workloads" "Internal ODH"

        s3 = softwareSystem "S3 / Object Storage" "Cloud object storage for LLM model weights" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Public model repository for downloading model weights and tokenizers" "External"
        pvc = softwareSystem "PVC / Persistent Volume" "Kubernetes persistent storage for pre-staged model weights" "External"

        rhaiisBase = softwareSystem "RHAIIS Base Image" "Red Hat AI Infrastructure & Services vLLM CUDA base image (registry.redhat.io/rhaiis/vllm-cuda-rhel9)" "External"
        konflux = softwareSystem "Konflux Build System" "CI/CD build system for multi-arch container image builds" "External"

        # Relationships - User interactions
        dataScientist -> kserve "Creates InferenceService / ServingRuntime via kubectl"
        application -> kserve "Sends inference requests via HTTPS/443"

        # Relationships - Platform integration
        kserve -> vllm "Deploys as inference container in ServingRuntime pods"
        istio -> vllm "Injects sidecar for mTLS and traffic management"
        gpuPlugin -> vllm "Allocates nvidia.com/gpu resources to inference pod"

        # Relationships - Internal container
        tgisAdapter -> vllmEngine "Translates TGIS gRPC to HTTP" "HTTP/8000 localhost"
        vllmEngine -> cudaRuntime "Runs model inference on GPU" "CUDA"

        # Relationships - Model loading (egress)
        vllm -> s3 "Downloads model weights at startup" "HTTPS/443 TLS 1.2+"
        vllm -> huggingFace "Downloads model weights and tokenizers" "HTTPS/443 TLS 1.2+"
        vllm -> pvc "Reads pre-staged model weights" "Filesystem"

        # Relationships - Build
        rhaiisBase -> vllm "Provides base image with vLLM, CUDA, TGIS adapter" "FROM registry.redhat.io/rhaiis/vllm-cuda-rhel9:3.2.2"
        konflux -> vllm "Builds multi-arch container images (amd64/arm64)" "Tekton Pipeline"
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
            element "Internal ODH" {
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

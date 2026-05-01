workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Sends inference requests to deployed LLM models"

        vllmRocm = softwareSystem "vllm-rocm" "GPU-accelerated vLLM inference runtime for AMD ROCm GPUs with TGIS adapter" {
            adapter = container "vllm_tgis_adapter" "Dual-protocol entrypoint providing OpenAI HTTP and TGIS gRPC APIs" "Python Module"
            vllmEngine = container "vLLM Engine" "High-performance LLM inference with PagedAttention and continuous batching" "Python / C++ / ROCm"
            httpApi = container "OpenAI HTTP API" "OpenAI-compatible REST endpoints for completions, chat, models, health" "HTTP Server, Port 8000"
            grpcApi = container "TGIS gRPC API" "Text Generation Inference Server gRPC protocol for KServe integration" "gRPC Server, Port 8033"
        }

        kserve = softwareSystem "KServe" "Serverless inference platform managing ServingRuntime and InferenceService CRs" "Internal RHOAI"
        platformIngress = softwareSystem "Platform Ingress" "Gateway API with kube-rbac-proxy for TLS termination and auth enforcement" "Internal RHOAI"
        modelStorageS3 = softwareSystem "S3-Compatible Storage" "Object storage for LLM model weights" "External"
        modelStoragePVC = softwareSystem "PersistentVolumeClaim" "Kubernetes volume for local model weight storage" "Internal Kubernetes"
        huggingFaceHub = softwareSystem "Hugging Face Hub" "Public model and tokenizer repository" "External"
        amdGpu = softwareSystem "AMD ROCm GPU" "Hardware GPU accelerator for inference compute" "Hardware"
        rhaiisRegistry = softwareSystem "RHAIIS Base Image Registry" "registry.redhat.io providing vllm-rocm-rhel9 base image" "External"
        konflux = softwareSystem "Konflux CI/CD" "Tekton-based build pipeline in rhoai-tenant namespace" "Internal Build"

        user -> platformIngress "Sends inference requests" "HTTPS"
        platformIngress -> vllmRocm "Routes requests after auth" "HTTP/8000, gRPC/8033"
        kserve -> vllmRocm "Deploys and orchestrates via ServingRuntime CR"
        vllmRocm -> modelStorageS3 "Downloads model weights" "HTTPS/443, TLS 1.2+, IAM"
        vllmRocm -> modelStoragePVC "Reads model weights" "Filesystem"
        vllmRocm -> huggingFaceHub "Downloads models/tokenizers" "HTTPS/443, TLS 1.2+"
        vllmRocm -> amdGpu "GPU compute for inference" "HIP/ROCm"
        konflux -> rhaiisRegistry "Pulls base image during build" "HTTPS/443"
        konflux -> vllmRocm "Builds container image" "Tekton PipelineRun"

        adapter -> httpApi "Serves"
        adapter -> grpcApi "Serves"
        adapter -> vllmEngine "Delegates inference"
        vllmEngine -> amdGpu "GPU kernels" "HIP/ROCm"
    }

    views {
        systemContext vllmRocm "SystemContext" {
            include *
            autoLayout
        }

        container vllmRocm "Containers" {
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
            element "Internal Kubernetes" {
                background #4a90e2
                color #ffffff
            }
            element "Internal Build" {
                background #9b59b6
                color #ffffff
            }
            element "Hardware" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
        }
    }
}

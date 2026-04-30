workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and queries LLM models for inference"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and KServe runtimes"

        vllmRocm = softwareSystem "vllm-rocm" "GPU-accelerated vLLM inference runtime for AMD ROCm GPUs with TGIS adapter for dual-protocol serving (OpenAI HTTP + TGIS gRPC)" {
            adapter = container "vllm_tgis_adapter" "Entrypoint module providing dual-protocol serving" "Python Module"
            httpApi = container "OpenAI HTTP API" "OpenAI-compatible REST API for completions and chat" "HTTP Server" "Port 8000"
            grpcApi = container "TGIS gRPC API" "Text Generation Inference Server gRPC interface" "gRPC Server" "Port 8033"
            vllmEngine = container "vLLM Engine" "High-performance LLM inference with PagedAttention and continuous batching" "Python/C++"
            rocmRuntime = container "ROCm Runtime" "AMD GPU compute libraries (HIP, ROCr)" "Native Libraries"
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform managing ServingRuntime and InferenceService CRs" "Internal RHOAI"
        platformIngress = softwareSystem "Platform Ingress" "Gateway API / kube-rbac-proxy providing TLS termination and auth enforcement" "Internal RHOAI"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for ML model weights and artifacts" "External"
        pvcStorage = softwareSystem "PVC Storage" "Kubernetes Persistent Volume for model weights" "Internal"
        hfHub = softwareSystem "Hugging Face Hub" "Public model and tokenizer repository" "External"
        amdGpu = softwareSystem "AMD ROCm GPU" "Hardware GPU accelerator for LLM inference" "Hardware"
        rhaiisRegistry = softwareSystem "RHAIIS Base Image Registry" "registry.redhat.io providing pre-built vllm-rocm-rhel9 base image" "External"
        konflux = softwareSystem "Konflux CI/CD" "Tekton-based build pipeline in rhoai-tenant namespace" "Internal"

        user -> platformIngress "Sends inference requests" "HTTPS/443"
        platformIngress -> vllmRocm "Forwards requests (auth enforced)" "HTTP/8000, gRPC/8033"
        platformAdmin -> kserve "Creates ServingRuntime / InferenceService CRs" "kubectl"
        kserve -> vllmRocm "Deploys and manages container pods" "Kubernetes API"
        vllmRocm -> amdGpu "Executes LLM inference" "HIP/ROCm"
        vllmRocm -> s3Storage "Downloads model weights" "HTTPS/443"
        vllmRocm -> pvcStorage "Reads model weights" "Filesystem"
        vllmRocm -> hfHub "Downloads model/tokenizer" "HTTPS/443"
        konflux -> rhaiisRegistry "Pulls base image during build" "HTTPS/443"
        konflux -> vllmRocm "Builds container image" "Tekton Pipeline"
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
            element "Internal" {
                background #4a90e2
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
        }
    }
}

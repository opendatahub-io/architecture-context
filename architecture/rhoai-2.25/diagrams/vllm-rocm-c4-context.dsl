workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        application = person "Application" "Sends inference requests via API"

        vllmRocm = softwareSystem "vllm-rocm" "GPU-accelerated vLLM inference runtime for AMD ROCm with TGIS adapter" {
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication/authorization sidecar proxy" "Go Service" "Security Sidecar"
            vllmServer = container "vLLM HTTP Server" "OpenAI-compatible inference API server" "Python/vLLM" "Port 8000"
            tgisAdapter = container "TGIS gRPC Adapter" "TGIS-compatible gRPC interface wrapping vLLM" "Python/vllm_tgis_adapter" "Port 8033"
            vllmEngine = container "vLLM Inference Engine" "High-performance LLM inference with ROCm GPU acceleration" "Python/vLLM/ROCm"
        }

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving platform" "Internal RHOAI"
        rhaiis = softwareSystem "RHAIIS" "Red Hat AI Inference Server - upstream base image provider" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3, MinIO, Ceph)" "External"
        pvcStorage = softwareSystem "PVC Storage" "Kubernetes persistent volume for model weights" "Internal"
        huggingFace = softwareSystem "Hugging Face Hub" "Public model registry and weights repository" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        amdGpu = softwareSystem "AMD GPU (ROCm)" "Hardware GPU acceleration via ROCm/HIP runtime" "Hardware"

        # User interactions
        datascientist -> kserve "Creates InferenceService CR" "kubectl/API"
        application -> vllmRocm "Sends inference requests" "HTTPS/8443, gRPC/8033"

        # Platform interactions
        kserve -> vllmRocm "Deploys as ServingRuntime container" "Container Image"
        modelMesh -> vllmRocm "Deploys as ServingRuntime container" "Container Image"

        # Container interactions
        kubeRbacProxy -> vllmServer "Proxies authenticated requests" "HTTP/8000 localhost"
        tgisAdapter -> vllmEngine "In-process inference calls" "In-process"
        vllmServer -> vllmEngine "In-process inference calls" "In-process"

        # External service interactions
        vllmRocm -> s3Storage "Downloads model weights" "HTTPS/443"
        vllmRocm -> pvcStorage "Loads model from filesystem" "Volume Mount"
        vllmRocm -> huggingFace "Downloads models/tokenizers (optional)" "HTTPS/443"
        vllmRocm -> amdGpu "GPU inference execution" "ROCm/HIP Runtime"
        prometheus -> vllmRocm "Scrapes metrics" "HTTP/8000"

        # Supply chain
        rhaiis -> vllmRocm "Provides base container image" "Container Registry"
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
                background #7ed321
                color #ffffff
            }
            element "Hardware" {
                background #e74c3c
                color #ffffff
            }
            element "Security Sidecar" {
                background #f5a623
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
        }
    }
}

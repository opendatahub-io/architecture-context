workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models on AMD ROCm GPUs"
        application = person "Application / Service" "Sends inference requests via OpenAI-compatible API or TGIS gRPC"

        vllmrocm = softwareSystem "vllm-rocm" "GPU-accelerated vLLM inference server for AMD ROCm, serving via OpenAI HTTP API and TGIS gRPC adapter" {
            vllmEngine = container "vLLM Engine" "Core inference engine with ROCm acceleration" "Python / vLLM"
            tgisAdapter = container "TGIS Adapter" "Bridges TGIS gRPC protocol to vLLM engine" "Python / vllm_tgis_adapter"
            httpAPI = container "OpenAI HTTP API" "OpenAI-compatible REST API for completions and chat" "Python / FastAPI" {
                tags "API"
            }
        }

        kserve = softwareSystem "KServe" "Deploys and manages InferenceService pods with serving runtimes" "Internal RHOAI"
        istio = softwareSystem "Istio / Service Mesh" "Provides mTLS, traffic routing, ingress gateway, and telemetry" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Sidecar for authentication and RBAC enforcement (RHOAI 3.x)" "Internal RHOAI"
        caikit = softwareSystem "Caikit" "AI runtime that sends inference requests via TGIS gRPC protocol" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Monitoring system that scrapes vLLM metrics" "Internal RHOAI"

        rhaiis = softwareSystem "RHAIIS Base Image" "registry.redhat.io/rhaiis/vllm-rocm-rhel9 — provides complete vLLM + ROCm runtime" "External"
        hfhub = softwareSystem "Hugging Face Hub" "Public model repository for downloading LLM weights" "External"
        s3storage = softwareSystem "S3-compatible Storage" "Object storage for model weights (AWS S3, MinIO, Ceph)" "External"
        rocmGPU = softwareSystem "AMD ROCm GPU" "AMD Instinct series GPU hardware with ROCm 7.14+ runtime" "External"
        konflux = softwareSystem "Konflux / Tekton" "CI/CD build pipeline for container image builds" "External"

        # Relationships
        datascientist -> kserve "Deploys InferenceService with vllm-rocm runtime"
        application -> istio "Sends inference requests via HTTPS/443"
        application -> vllmrocm "Queries models" "OpenAI HTTP / TGIS gRPC"

        istio -> kubeRBACProxy "Routes authenticated traffic" "mTLS/8443"
        kubeRBACProxy -> httpAPI "Forwards validated requests" "HTTP/8000"
        istio -> tgisAdapter "Routes gRPC traffic" "mTLS → plaintext/8033"
        caikit -> tgisAdapter "Sends TGIS inference requests" "gRPC/8033"

        tgisAdapter -> vllmEngine "In-process call"
        httpAPI -> vllmEngine "In-process call"

        vllmEngine -> rocmGPU "Tensor compute for inference" "PCIe/Infinity Fabric"
        vllmEngine -> hfhub "Downloads model weights" "HTTPS/443"
        vllmEngine -> s3storage "Loads model weights" "HTTPS/443"

        kserve -> vllmrocm "Deploys as serving runtime container"
        prometheus -> httpAPI "Scrapes metrics" "HTTP/8000"

        rhaiis -> vllmrocm "Base image (FROM)" "Container build"
        konflux -> vllmrocm "Builds container image" "Tekton PipelineRun"
    }

    views {
        systemContext vllmrocm "SystemContext" {
            include *
            autoLayout
        }

        container vllmrocm "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "API" {
                shape RoundedBox
            }
        }
    }
}

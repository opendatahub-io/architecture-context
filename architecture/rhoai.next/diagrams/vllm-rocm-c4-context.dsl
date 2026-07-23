workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models on AMD GPUs via RHOAI"
        application = person "Application" "Upstream application consuming inference API"

        vllmRocm = softwareSystem "vllm-rocm" "Thin wrapper container image extending RHAIIS vLLM ROCm base with TGIS adapter for AMD GPU inference serving" {
            vllmEngine = container "vLLM Engine" "LLM inference engine with PagedAttention for AMD ROCm GPUs" "Python (inherited from RHAIIS base)"
            tgisAdapter = container "TGIS Adapter" "Bridges vLLM engine with KServe TGIS gRPC protocol" "Python module (vllm_tgis_adapter)"
            httpApi = container "OpenAI-Compatible HTTP API" "REST API for inference (chat completions, completions, models)" "HTTP/8000"
            grpcApi = container "TGIS gRPC Service" "TGIS-compatible gRPC interface for text generation" "gRPC/8033"
        }

        kserve = softwareSystem "KServe" "Manages ServingRuntime and InferenceService CRs that deploy this image" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator managing ServingRuntime CRs referencing this image" "Internal RHOAI"
        gatewayApi = softwareSystem "Gateway API" "Platform ingress for TLS termination and routing" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Auth sidecar validating Bearer tokens via SubjectAccessReview" "Internal RHOAI"
        rhaiisBaseImage = softwareSystem "RHAIIS Base Image" "Pre-built vLLM + ROCm + TGIS adapter runtime (registry.redhat.io/rhaiis/vllm-rocm-rhel9:3.2.1)" "External"
        amdRocmGpu = softwareSystem "AMD ROCm GPU" "AMD Instinct/Radeon GPU hardware with ROCm device plugin" "Infrastructure"
        s3Storage = softwareSystem "S3 Storage" "Object storage for model weights" "External"
        hfHub = softwareSystem "Hugging Face Hub" "Model weights and tokenizer repository" "External"
        konfluxCentral = softwareSystem "Konflux Central" "Tekton pipeline definitions for building the container image" "External"

        # User interactions
        dataScientist -> kserve "Creates InferenceService CR via kubectl/dashboard"
        application -> gatewayApi "Sends inference requests" "HTTPS/443"

        # Platform flow
        gatewayApi -> kubeRbacProxy "Routes traffic" "HTTPS/8443"
        kubeRbacProxy -> vllmRocm "Proxies authenticated requests" "HTTP/8000, gRPC/8033"

        # Internal container relationships
        tgisAdapter -> vllmEngine "Starts and bridges to engine"
        vllmEngine -> httpApi "Serves REST API"
        tgisAdapter -> grpcApi "Serves TGIS protocol"

        # KServe management
        kserve -> vllmRocm "Deploys as ServingRuntime pod"
        rhodsOperator -> kserve "Manages ServingRuntime CRs"

        # Dependencies
        vllmRocm -> rhaiisBaseImage "Extends via FROM (Dockerfile)"
        vllmRocm -> amdRocmGpu "GPU compute for inference" "ROCm device driver"
        vllmRocm -> s3Storage "Downloads model weights at startup" "HTTPS/443"
        vllmRocm -> hfHub "Downloads models and tokenizers" "HTTPS/443"

        # Build
        konfluxCentral -> vllmRocm "Provides Tekton build pipeline" "PipelinesAsCode"
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
            element "Infrastructure" {
                background #9673a6
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
                background #5ba3f5
                color #ffffff
            }
        }
    }
}

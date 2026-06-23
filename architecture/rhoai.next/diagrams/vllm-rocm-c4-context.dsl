workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM inference endpoints on RHOAI"
        mlEngineer = person "ML Engineer" "Configures ServingRuntimes and InferenceServices"

        vllmRocm = softwareSystem "vllm-rocm" "vLLM inference runtime for AMD ROCm GPUs, providing OpenAI-compatible HTTP and TGIS gRPC APIs" {
            vllmEngine = container "vLLM Engine" "Core LLM inference engine with tensor parallelism and continuous batching" "Python / vLLM"
            tgisAdapter = container "vllm_tgis_adapter" "Bridges vLLM with TGIS gRPC protocol for KServe compatibility" "Python / gRPC"
            rocmRuntime = container "ROCm Runtime" "AMD GPU compute libraries (HIP, MIOpen, RCCL, hipBLAS)" "ROCm 7.1.1"
        }

        kserve = softwareSystem "KServe" "Manages ML model serving lifecycle via ServingRuntime and InferenceService CRDs" "Internal RHOAI"
        rhoaiPlatform = softwareSystem "RHOAI Platform" "Red Hat OpenShift AI platform operator and dashboard" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Sidecar enforcing Kubernetes RBAC on inference endpoints" "Internal RHOAI"
        platformIngress = softwareSystem "Platform Ingress" "Gateway API / HTTPRoute for external access routing" "OpenShift"

        rhaiisBaseImage = softwareSystem "RHAIIS Base Image" "AIPCC Ecosystems vLLM ROCm base image (rhaiis/vllm-rocm-rhel9)" "Internal AIPCC"
        amdGPU = softwareSystem "AMD Instinct GPU" "MI200/MI300 series GPU hardware with ROCm driver" "External Hardware"
        huggingFaceHub = softwareSystem "Hugging Face Hub" "Model weights and artifacts repository" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts" "External"

        # Relationships
        dataScientist -> rhoaiPlatform "Creates InferenceService via Dashboard or kubectl"
        mlEngineer -> kserve "Configures ServingRuntime with vllm-rocm image"

        rhoaiPlatform -> kserve "Manages inference service lifecycle"
        kserve -> vllmRocm "Deploys and manages via ServingRuntime CRD"

        dataScientist -> platformIngress "Sends inference requests" "HTTPS/443"
        platformIngress -> kubeRBACProxy "Routes to pod sidecar" "HTTPS/8443"
        kubeRBACProxy -> vllmRocm "Forwards authenticated requests" "HTTP/8000, gRPC/8033"

        vllmEngine -> rocmRuntime "Uses for GPU compute" "HIP API"
        tgisAdapter -> vllmEngine "Wraps inference engine" "Internal"
        rocmRuntime -> amdGPU "Executes on GPU hardware" "HIP API"

        vllmRocm -> huggingFaceHub "Downloads model weights (optional)" "HTTPS/443"
        vllmRocm -> s3Storage "Fetches model artifacts (optional)" "HTTPS/443"

        rhaiisBaseImage -> vllmRocm "Provides complete runtime via FROM directive" "Container Base Image"
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
            element "Internal AIPCC" {
                background #4a90e2
                color #ffffff
            }
            element "OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "External Hardware" {
                background #666666
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

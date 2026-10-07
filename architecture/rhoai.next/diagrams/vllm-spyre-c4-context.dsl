workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models via RHOAI"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and ServingRuntimes"

        vllmSpyre = softwareSystem "vllm-spyre" "IBM Spyre-accelerated vLLM inference server with TGIS adapter for RHOAI" {
            tgisAdapter = container "vllm_tgis_adapter" "TGIS gRPC protocol adapter wrapping vLLM engine" "Python Module" "gRPC :8033"
            vllmEngine = container "vLLM Engine" "LLM inference engine with PagedAttention, serving OpenAI-compatible HTTP API" "Python" "HTTP :8000"
            spyreSDK = container "IBM Spyre SDK" "Hardware acceleration runtime for IBM Spyre AI accelerators" "SDK 1.3.1"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Kubernetes-native model serving platform, manages ServingRuntimes and InferenceServices" "Internal RHOAI"
        modelController = softwareSystem "Model Controller" "RHOAI operator managing model deployment lifecycle" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS, traffic management, and AuthorizationPolicy enforcement" "External"
        modelStorage = softwareSystem "Model Storage" "S3-compatible object storage or PVC for model weight artifacts" "External"
        spyreHW = softwareSystem "IBM Spyre Accelerator" "IBM Spyre AI accelerator hardware, accessed via Kubernetes device plugin" "External"
        rhaiisBase = softwareSystem "RHAIIS Base Image" "Product image registry.redhat.io/rhaiis/vllm-spyre-rhel9:3.2.2 providing vLLM, TGIS adapter, and Spyre SDK" "Internal RHAIIS"
        aipccBase = softwareSystem "AIPCC Spyre Base Image" "Base image providing Python 3.12, RHEL 9.8, IBM Spyre SDK, and AIPCC content channels" "Internal AIPCC"

        dataScientist -> vllmSpyre "Sends inference requests via KServe route" "gRPC/HTTP"
        platformAdmin -> kserve "Configures ServingRuntime and InferenceService" "kubectl/console"

        kserve -> vllmSpyre "Deploys and routes inference requests" "gRPC :8033 / HTTP :8000"
        modelController -> vllmSpyre "References container image in ServingRuntime" "Image reference"
        istio -> vllmSpyre "Enforces mTLS and AuthorizationPolicy" "Sidecar injection"
        vllmSpyre -> modelStorage "Loads model weights at startup" "HTTPS :443 / NFS"
        vllmSpyre -> spyreHW "Accesses hardware accelerator" "Kernel/driver"
        vllmSpyre -> rhaiisBase "Built from (Dockerfile extends)" "Container image"
        rhaiisBase -> aipccBase "Built from (extends)" "Container image"

        tgisAdapter -> vllmEngine "Translates TGIS gRPC to vLLM calls"
        vllmEngine -> spyreSDK "Delegates compute to accelerator"
    }

    views {
        systemContext vllmSpyre "SystemContext" {
            include *
            autoLayout
        }

        container vllmSpyre "Containers" {
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
            element "Internal RHAIIS" {
                background #4a90e2
                color #ffffff
            }
            element "Internal AIPCC" {
                background #4a90e2
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

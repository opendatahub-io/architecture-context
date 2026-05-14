workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        application = person "Application Client" "Sends inference requests to deployed models"

        vllmRocm = softwareSystem "vllm-rocm" "GPU-accelerated LLM inference runtime for AMD ROCm, exposing OpenAI-compatible HTTP and TGIS gRPC APIs" {
            tgisAdapter = container "vllm_tgis_adapter" "Python entrypoint wrapping vLLM with TGIS gRPC protocol support" "Python"
            vllmEngine = container "vLLM Engine" "High-throughput LLM inference engine with PagedAttention" "Python/C++"
            rocmRuntime = container "ROCm Runtime" "AMD GPU compute libraries for inference acceleration" "ROCm/HIP"

            tgisAdapter -> vllmEngine "Wraps and delegates inference requests"
            vllmEngine -> rocmRuntime "Uses for GPU computation"
        }

        kserve = softwareSystem "KServe" "Deploys and manages ServingRuntime containers for ML inference" "Internal RHOAI"
        modelStorageS3 = softwareSystem "S3-compatible Storage" "Object storage for model weights" "External"
        modelStoragePVC = softwareSystem "PVC Storage" "Persistent volume for model weights" "Internal"
        huggingFaceHub = softwareSystem "Hugging Face Hub" "Model and tokenizer download hub" "External"
        amdGPU = softwareSystem "AMD ROCm GPU" "Hardware GPU accelerator for inference computation" "Infrastructure"
        rhaiisBaseImage = softwareSystem "RHAIIS Base Image" "Red Hat AI Infrastructure Services vLLM ROCm image (registry.redhat.io/rhaiis/vllm-rocm-rhel9)" "External"

        # Relationships
        datascientist -> kserve "Creates InferenceService via kubectl/Dashboard"
        application -> vllmRocm "Sends inference requests" "HTTP/8000, gRPC/8033"
        kserve -> vllmRocm "Deploys as ServingRuntime, manages lifecycle"
        vllmRocm -> modelStorageS3 "Downloads model weights at startup" "HTTPS/443"
        vllmRocm -> modelStoragePVC "Reads model weights via volume mount" "Filesystem"
        vllmRocm -> huggingFaceHub "Downloads model/tokenizer (optional)" "HTTPS/443"
        vllmRocm -> amdGPU "Performs inference computation" "PCIe/ROCm"
        rhaiisBaseImage -> vllmRocm "Provides base container layer" "Build-time"
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
            element "Infrastructure" {
                background #e74c3c
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

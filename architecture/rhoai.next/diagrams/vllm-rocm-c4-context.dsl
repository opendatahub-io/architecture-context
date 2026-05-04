workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        application = person "Application" "Sends inference requests to deployed models"

        vllmRocm = softwareSystem "vllm-rocm" "GPU-accelerated LLM inference runtime for AMD ROCm, exposing OpenAI-compatible HTTP and TGIS gRPC APIs" {
            vllmEngine = container "vLLM Engine" "High-performance LLM inference engine with PagedAttention" "Python / ROCm"
            tgisAdapter = container "TGIS Adapter" "Wraps vLLM to expose TGIS gRPC protocol alongside OpenAI HTTP API" "Python"
            openaiApi = container "OpenAI HTTP API" "REST API for text/chat completions" "HTTP/8000"
            tgisGrpc = container "TGIS gRPC Service" "GenerationService for model serving" "gRPC/8033"
        }

        kserve = softwareSystem "KServe" "Deploys and manages inference services via ServingRuntime CRs" "Internal RHOAI"
        modelStorageS3 = softwareSystem "S3 Storage" "S3-compatible object storage for model weights" "External"
        modelStoragePVC = softwareSystem "PVC Storage" "Persistent volume for pre-cached model weights" "Internal"
        amdGpu = softwareSystem "AMD ROCm GPU" "Hardware GPU accelerator for inference computation" "Infrastructure"
        huggingFaceHub = softwareSystem "Hugging Face Hub" "Public model and tokenizer repository" "External"
        rhaiisBase = softwareSystem "RHAIIS Base Image" "Red Hat AI Infrastructure Services vLLM ROCm base image" "External"

        # Relationships
        dataScientist -> kserve "Creates InferenceService CR via kubectl/dashboard"
        application -> vllmRocm "Sends inference requests" "HTTPS (via KServe ingress)"

        kserve -> vllmRocm "Deploys as ServingRuntime container and routes traffic"

        tgisAdapter -> vllmEngine "Wraps and delegates inference"
        tgisAdapter -> openaiApi "Exposes" "HTTP/8000"
        tgisAdapter -> tgisGrpc "Exposes" "gRPC/8033"

        vllmEngine -> amdGpu "Runs inference computation" "PCIe/ROCm"
        vllmEngine -> modelStorageS3 "Downloads model weights" "HTTPS/443"
        vllmEngine -> modelStoragePVC "Reads model weights" "Filesystem"
        vllmEngine -> huggingFaceHub "Downloads weights/tokenizer (optional)" "HTTPS/443"

        vllmRocm -> rhaiisBase "Built on base image" "Container Image v3.2.1"
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
                background #e74c3c
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
                background #438dd5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        user = person "Data Scientist / Application" "Sends inference requests to deployed models"

        vllmRocm = softwareSystem "vllm-rocm" "AMD ROCm GPU-accelerated LLM inference runtime exposing OpenAI-compatible HTTP and TGIS gRPC APIs" {
            tgisAdapter = container "vllm_tgis_adapter" "Wraps vLLM engine, exposes dual-protocol API (HTTP + gRPC)" "Python Module"
            vllmEngine = container "vLLM Engine" "High-throughput LLM inference with PagedAttention" "Python / ROCm"
            openaiApi = container "OpenAI HTTP API" "Serves /v1/completions, /v1/chat/completions, /v1/models, /health" "HTTP 8000/TCP"
            tgisGrpc = container "TGIS gRPC Service" "Text Generation Inference Server protocol" "gRPC 8033/TCP"
        }

        kserve = softwareSystem "KServe" "Deploys and manages ServingRuntime lifecycle, routes inference traffic" "Internal RHOAI"
        modelStorageS3 = softwareSystem "S3-Compatible Storage" "Stores model weight artifacts" "External"
        modelStoragePVC = softwareSystem "PVC Volume" "Provides model weights via persistent volume" "Internal"
        amdGpu = softwareSystem "AMD ROCm GPU" "GPU compute for LLM inference" "Hardware"
        huggingFace = softwareSystem "Hugging Face Hub" "Public model and tokenizer repository" "External"
        rhaiisBase = softwareSystem "RHAIIS Base Image" "registry.redhat.io/rhaiis/vllm-rocm-rhel9 — provides vLLM runtime, ROCm libs, TGIS adapter" "External"

        user -> vllmRocm "Sends inference requests" "HTTP/8000, gRPC/8033"
        kserve -> vllmRocm "Deploys as ServingRuntime, routes traffic"
        vllmRocm -> modelStorageS3 "Downloads model artifacts" "HTTPS/443, TLS 1.2+, IAM"
        vllmRocm -> modelStoragePVC "Reads model weights" "Filesystem mount"
        vllmRocm -> amdGpu "Runs inference computation" "PCIe/ROCm"
        vllmRocm -> huggingFace "Downloads model/tokenizer (optional)" "HTTPS/443, TLS 1.2+"
        rhaiisBase -> vllmRocm "Provides base image layer" "Container image inheritance"

        tgisAdapter -> vllmEngine "Delegates inference"
        tgisAdapter -> openaiApi "Exposes HTTP endpoint"
        tgisAdapter -> tgisGrpc "Exposes gRPC endpoint"
        vllmEngine -> amdGpu "GPU inference" "PCIe/ROCm"
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
            element "Hardware" {
                background #9b59b6
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
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

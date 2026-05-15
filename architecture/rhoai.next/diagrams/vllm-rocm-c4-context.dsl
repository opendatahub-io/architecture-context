workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and queries LLM inference endpoints on OpenShift AI"

        vllmRocm = softwareSystem "vllm-rocm" "GPU-accelerated LLM inference serving runtime using AMD ROCm with TGIS adapter for dual-protocol serving (HTTP + gRPC)" {
            container_image = container "odh-vllm-rocm-rhel9" "Container image wrapping RHAIIS vllm-rocm base with TGIS adapter entrypoint" "Python / vllm_tgis_adapter" {
                httpApi = component "OpenAI-Compatible HTTP API" "Serves /v1/completions, /v1/chat/completions, /v1/models, /health" "HTTP/8000"
                grpcApi = component "TGIS gRPC Service" "TGIS-compatible text generation interface" "gRPC/8033"
                vllmEngine = component "vLLM Engine" "Core inference engine for LLM serving" "Python"
                rocmRuntime = component "ROCm Runtime" "AMD GPU compute libraries (HIP)" "C++/ROCm"
            }
        }

        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle, autoscaling, and traffic routing" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that references this image in ServingRuntime CR templates" "Internal RHOAI"
        rhaiisBase = softwareSystem "RHAIIS Base Image" "registry.redhat.io/rhaiis/vllm-rocm-rhel9 — provides vLLM, ROCm, Python, vllm-tgis-adapter" "External Red Hat"
        modelStorage = softwareSystem "Model Storage" "S3-compatible object storage or PersistentVolumeClaim for model weights" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Public model and tokenizer repository" "External"
        rocmGPU = softwareSystem "AMD ROCm GPU" "Hardware GPU with ROCm driver on host node" "Infrastructure"

        user -> vllmRocm "Sends inference requests via KServe gateway" "HTTPS/443"
        kserve -> vllmRocm "Deploys as InferenceService serving runtime, manages pod lifecycle" "Kubernetes API"
        rhodsOperator -> vllmRocm "References image in ServingRuntime CR templates" "Image reference"
        vllmRocm -> rhaiisBase "Built FROM base image (all runtime dependencies)" "Container build"
        vllmRocm -> modelStorage "Downloads model weights at startup" "HTTPS/443 or filesystem"
        vllmRocm -> huggingFace "Downloads models/tokenizers (optional)" "HTTPS/443"
        vllmRocm -> rocmGPU "Executes tensor operations for inference" "PCIe/HIP Device API"
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

        component container_image "Components" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Red Hat" {
                background #cc0000
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

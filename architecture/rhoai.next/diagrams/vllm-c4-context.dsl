workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        application = person "Application / Service" "Sends inference requests programmatically"

        vllm = softwareSystem "vLLM CUDA Runtime" "GPU-accelerated LLM inference serving runtime with OpenAI-compatible HTTP API and TGIS gRPC interface" {
            tgisAdapter = container "vllm_tgis_adapter" "Python entrypoint that wraps vLLM engine, exposing dual-protocol serving (HTTP + gRPC)" "Python Module"
            vllmEngine = container "vLLM Engine" "High-performance LLM inference with PagedAttention, continuous batching, speculative decoding, tensor/pipeline parallelism" "Python / CUDA"
            httpApi = container "OpenAI HTTP API" "REST API for completions, chat, embeddings, model listing" "HTTP/8000"
            grpcApi = container "TGIS gRPC Service" "Text Generation Inference Service compatible gRPC interface" "gRPC/8033"
        }

        kserve = softwareSystem "KServe" "Manages model serving lifecycle via ServingRuntime and InferenceService CRDs" "Internal RHOAI"
        rhoaiModelServing = softwareSystem "RHOAI Model Serving" "Platform-level model serving configuration and orchestration" "Internal RHOAI"
        gateway = softwareSystem "RHOAI Gateway" "Platform ingress with TLS termination and authentication (kube-rbac-proxy / Gateway API)" "Internal RHOAI"
        gpuPlugin = softwareSystem "NVIDIA GPU Device Plugin" "Allocates GPU resources to inference pods" "External"
        modelStorage = softwareSystem "Model Storage" "S3-compatible storage or HuggingFace Hub for model weight artifacts" "External"
        rhaiisBase = softwareSystem "RHAIIS Base Image" "Pre-built container image providing vLLM runtime, Python, CUDA libraries, TGIS adapter" "External (Red Hat)"
        konflux = softwareSystem "Konflux / Tekton" "CI/CD build pipeline for multi-arch container images" "External"

        datascientist -> gateway "Sends inference requests via HTTPS/443"
        application -> gateway "Sends inference requests via HTTPS/443"
        application -> grpcApi "Sends gRPC inference requests (cluster-internal) via gRPC/8033"

        gateway -> httpApi "Proxies authenticated requests via HTTP/8000"
        tgisAdapter -> vllmEngine "Delegates inference"
        vllmEngine -> httpApi "Serves HTTP responses"
        vllmEngine -> grpcApi "Serves gRPC responses"

        kserve -> vllm "Manages pod lifecycle via ServingRuntime CR"
        rhoaiModelServing -> kserve "Configures model deployments"
        vllm -> modelStorage "Downloads model weights at startup via HTTPS/443"
        vllm -> gpuPlugin "Requests GPU allocation"
        rhaiisBase -> vllm "Provides base container image"
        konflux -> vllm "Builds and publishes container image"
    }

    views {
        systemContext vllm "SystemContext" {
            include *
            autoLayout
            description "vLLM CUDA Runtime in the RHOAI ecosystem"
        }

        container vllm "Containers" {
            include *
            autoLayout
            description "Internal structure of the vLLM CUDA serving runtime"
        }

        styles {
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External (Red Hat)" {
                background #cc0000
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

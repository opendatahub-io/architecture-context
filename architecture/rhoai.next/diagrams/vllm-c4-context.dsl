workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        application = person "Application / Client" "Sends inference requests via HTTP or gRPC"

        vllm = softwareSystem "vLLM CUDA" "GPU-accelerated LLM inference server with TGIS adapter, wrapping RHAIIS vLLM CUDA product image" {
            tgisAdapter = container "vllm_tgis_adapter" "Entrypoint module launching dual-protocol server" "Python Module"
            httpServer = container "OpenAI-Compatible HTTP Server" "Serves /v1/completions, /v1/chat/completions, /v1/models, /v1/embeddings" "vLLM HTTP Server, Port 8000"
            grpcServer = container "TGIS gRPC Server" "TGIS GenerationService for backward-compatible inference" "gRPC Server, Port 8033"
            engine = container "vLLM Inference Engine" "Core LLM inference engine with CUDA acceleration" "Python/C++ (from RHAIIS base)"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle and deploys ServingRuntimes" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization sidecar using SubjectAccessReview" "Internal RHOAI"
        gatewayAPI = softwareSystem "Gateway API (Envoy)" "Ingress routing for inference traffic via HTTPRoute" "Internal RHOAI"
        nvidiaGPU = softwareSystem "NVIDIA GPU" "GPU compute via CUDA runtime (cuDNN, cuBLAS, NCCL)" "Infrastructure"
        s3 = softwareSystem "S3 Storage" "Model artifact storage (AWS S3 or compatible)" "External"
        hfHub = softwareSystem "Hugging Face Hub" "Public/private model and tokenizer repository" "External"
        pvc = softwareSystem "Persistent Volume" "Kubernetes PVC for local model storage" "Infrastructure"
        rhaiisBase = softwareSystem "RHAIIS vLLM CUDA Image" "Pre-built product image providing vLLM engine, CUDA runtime, and dependencies" "Internal Red Hat"
        konfluxCentral = softwareSystem "konflux-central" "Tekton pipeline definitions for CI/CD" "Internal Red Hat"

        application -> gatewayAPI "Sends inference requests" "HTTPS/443, TLS 1.2+"
        gatewayAPI -> kubeRbacProxy "Routes to serving pod" "HTTPS/8443, TLS"
        kubeRbacProxy -> httpServer "Proxies HTTP requests (pre-authorized)" "HTTP/8000"
        kubeRbacProxy -> grpcServer "Proxies gRPC requests (pre-authorized)" "gRPC/8033"
        tgisAdapter -> httpServer "Launches HTTP server"
        tgisAdapter -> grpcServer "Launches gRPC server"
        httpServer -> engine "Inference request" "In-process"
        grpcServer -> engine "Inference request" "In-process"
        engine -> nvidiaGPU "CUDA compute" "CUDA Runtime"
        engine -> s3 "Downloads model weights" "HTTPS/443"
        engine -> hfHub "Downloads models and tokenizers" "HTTPS/443"
        engine -> pvc "Loads model from volume" "Filesystem"
        kserve -> vllm "Deploys as ServingRuntime" "InferenceService CR"
        datascientist -> kserve "Creates InferenceService via kubectl"
        rhaiisBase -> vllm "Base image (FROM)" "Build-time"
        konfluxCentral -> vllm "Pipeline definitions" "Git sync"
    }

    views {
        systemContext vllm "SystemContext" {
            include *
            autoLayout
        }

        container vllm "Containers" {
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
            element "Internal Red Hat" {
                background #ee0000
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

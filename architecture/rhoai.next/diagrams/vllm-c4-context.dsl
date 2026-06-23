workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and queries LLM inference services on RHOAI"
        application = person "Client Application" "Sends inference requests to deployed models"

        vllm = softwareSystem "vLLM (CUDA + TGIS Adapter)" "GPU-accelerated LLM inference server with OpenAI-compatible HTTP API and TGIS gRPC interface" {
            tgisAdapter = container "TGIS Adapter" "Wraps vLLM engine, provides gRPC interface alongside HTTP API" "Python (vllm_tgis_adapter)"
            vllmEngine = container "vLLM Inference Engine" "High-performance LLM inference with PagedAttention, continuous batching, speculative decoding" "Python/C++ (inherited from RHAIIS base)"
            openaiAPI = container "OpenAI-Compatible HTTP API" "REST endpoints: /v1/completions, /v1/chat/completions, /v1/models" "HTTP 8000/TCP"
            tgisGRPC = container "TGIS gRPC Service" "Text Generation Inference Server protocol for KServe" "gRPC 8033/TCP"
        }

        kserve = softwareSystem "KServe" "Serverless ML model serving on Kubernetes" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication and TLS termination sidecar" "Internal RHOAI"
        gatewayAPI = softwareSystem "Gateway API / Istio" "Platform ingress and traffic management" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"

        hfHub = softwareSystem "Hugging Face Hub" "Model weights and tokenizer repository" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts" "External"
        nvidiaGPU = softwareSystem "NVIDIA GPU" "CUDA-compatible GPU for inference acceleration" "External Hardware"
        pvcStorage = softwareSystem "PVC Volume" "Persistent volume for model weights" "Kubernetes"

        # User interactions
        user -> kserve "Creates InferenceService CR via kubectl/dashboard"
        application -> gatewayAPI "Sends inference requests" "HTTPS/443"

        # Platform flows
        gatewayAPI -> kubeRbacProxy "Routes traffic" "HTTPS/8443"
        kubeRbacProxy -> vllm "Forwards after auth" "HTTP/8000, gRPC/8033"
        kserve -> vllm "Deploys as ServingRuntime container"

        # vLLM internal
        tgisAdapter -> vllmEngine "Wraps engine"
        vllmEngine -> openaiAPI "Serves HTTP"
        tgisAdapter -> tgisGRPC "Serves gRPC"

        # External dependencies
        vllm -> hfHub "Downloads model weights" "HTTPS/443 Bearer Token"
        vllm -> s3Storage "Downloads model artifacts" "HTTPS/443 IAM"
        vllm -> nvidiaGPU "GPU inference compute" "CUDA API"
        vllm -> pvcStorage "Reads model weights" "Filesystem"

        # Monitoring
        prometheus -> vllm "Scrapes /metrics" "HTTP/8000"
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
            element "External Hardware" {
                background #e74c3c
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Kubernetes" {
                background #326ce5
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
                background #5bb5f0
                color #ffffff
            }
        }
    }
}

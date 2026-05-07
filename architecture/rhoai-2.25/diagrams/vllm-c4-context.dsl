workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for inference"
        application = person "Application" "External application consuming inference APIs"

        vllm = softwareSystem "vLLM Inference Runtime" "GPU-accelerated LLM inference runtime with TGIS gRPC adapter and OpenAI-compatible HTTP API" {
            tgisAdapter = container "vLLM TGIS Adapter" "gRPC adapter bridging TGIS protocol to vLLM engine" "Python (vllm_tgis_adapter)" "8033/TCP gRPC"
            httpServer = container "vLLM HTTP Server" "OpenAI-compatible REST API for completions and chat" "Python (vLLM)" "8000/TCP HTTP"
            vllmEngine = container "vLLM Engine" "High-performance LLM inference with PagedAttention, continuous batching, speculative decoding" "Python/CUDA"
        }

        kserve = softwareSystem "KServe" "Serverless ML model serving platform managing InferenceService lifecycle" "Internal RHOAI"
        platformIngress = softwareSystem "Platform Ingress" "OpenShift Route / HTTPRoute for external traffic routing with TLS termination" "Internal RHOAI"
        authProxy = softwareSystem "Auth Proxy" "kube-rbac-proxy (3.x) or oauth-proxy (2.x) sidecar for AuthN/AuthZ enforcement" "Internal RHOAI"
        modelStorage = softwareSystem "Model Storage" "S3-compatible object storage or PVC for model weight artifacts" "External"
        gpu = softwareSystem "NVIDIA GPU" "GPU compute device for CUDA tensor operations" "Infrastructure"
        rhaiis = softwareSystem "RHAIIS Base Image" "Red Hat AI Inference Server base container with vLLM, CUDA, and all runtime dependencies" "External"

        # User interactions
        dataScientist -> kserve "Creates InferenceService via kubectl/dashboard"
        application -> platformIngress "Sends inference requests" "HTTPS/443"

        # Platform flow
        platformIngress -> authProxy "Forwards requests" "HTTPS/8443"
        authProxy -> vllm "Proxies authenticated requests" "HTTP/8000, gRPC/8033"

        # Internal container interactions
        tgisAdapter -> vllmEngine "Forwards gRPC requests" "Python IPC (in-process)"
        httpServer -> vllmEngine "Forwards HTTP requests" "Python IPC (in-process)"

        # External dependencies
        kserve -> vllm "Manages as ServingRuntime container"
        vllmEngine -> modelStorage "Downloads model weights at startup" "HTTPS/443 (S3) or volume mount"
        vllmEngine -> gpu "Executes tensor operations" "CUDA IPC"
        rhaiis -> vllm "Provides base image with all runtime dependencies" "Container layer"
    }

    views {
        systemContext vllm "SystemContext" {
            include *
            autoLayout
            description "System context showing vLLM inference runtime in the RHOAI ecosystem"
        }

        container vllm "Containers" {
            include *
            autoLayout
            description "Container view showing vLLM internal components and their interactions"
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
                background #f5a623
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

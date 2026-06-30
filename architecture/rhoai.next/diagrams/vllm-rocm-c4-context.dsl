workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for inference"
        mlEngineer = person "ML Engineer" "Configures serving runtimes and model deployments"

        vllmRocm = softwareSystem "vLLM ROCm" "GPU-accelerated inference serving runtime for AMD ROCm hardware, providing OpenAI-compatible HTTP and TGIS gRPC APIs" {
            adapter = container "vllm-tgis-adapter" "Wraps vLLM engine with TGIS-compatible gRPC interface and OpenAI-compatible HTTP API" "Python"
            vllmEngine = container "vLLM Inference Engine" "High-throughput LLM inference engine with PagedAttention" "Python/C++/ROCm"
            httpAPI = container "OpenAI-compatible HTTP API" "REST API for text/chat completions" "HTTP/8000"
            grpcAPI = container "TGIS gRPC API" "TGIS-compatible generation service" "gRPC/8033"
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform managing InferenceService pods" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving platform" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization sidecar (TLS termination + Bearer Token validation)" "Internal RHOAI"

        aipccBaseImage = softwareSystem "AIPCC Base Image" "rhaiis/vllm-rocm-rhel9:3.2.1 providing vLLM, ROCm libraries, Python runtime" "External"
        huggingface = softwareSystem "HuggingFace Hub" "ML model weight repository" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for model artifacts" "External"
        rocmGPU = softwareSystem "AMD ROCm GPU" "GPU hardware with ROCm 7.1.1 driver" "External"

        # User interactions
        dataScientist -> kserve "Creates InferenceService CR via kubectl/dashboard"
        dataScientist -> kubeRbacProxy "Sends inference requests" "HTTPS/8443"
        mlEngineer -> kserve "Configures ServingRuntime CRs"

        # Platform interactions
        kserve -> vllmRocm "Deploys as inference serving container in pod"
        modelMesh -> vllmRocm "Deploys as ModelMesh serving runtime" "gRPC/8033"
        kubeRbacProxy -> vllmRocm "Proxies authenticated requests" "HTTP/8000"

        # Internal container interactions
        adapter -> vllmEngine "Delegates inference computation"
        adapter -> httpAPI "Serves OpenAI-compatible REST"
        adapter -> grpcAPI "Serves TGIS-compatible gRPC"
        vllmEngine -> rocmGPU "GPU kernel dispatch" "HIP/ROCm"

        # External service interactions
        vllmRocm -> huggingface "Downloads model weights at startup" "HTTPS/443"
        vllmRocm -> s3Storage "Downloads model weights (alternative)" "HTTPS/443"

        # Build dependency
        aipccBaseImage -> vllmRocm "Provides runtime (vLLM, ROCm libs, Python)" "Base image layer"
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

workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and queries LLM inference endpoints"
        application = softwareSystem "Client Application" "Sends inference requests to deployed models"

        vllm = softwareSystem "vLLM Inference Server" "GPU-accelerated LLM inference serving with OpenAI-compatible API and TGIS gRPC interface" {
            uvicorn = container "Uvicorn HTTP Server" "OpenAI-compatible REST API for inference requests" "Python/uvicorn" "Port 8000"
            tgisAdapter = container "vllm-tgis-adapter" "TGIS-compatible gRPC interface for inference requests" "Python/gRPC" "Port 8033"
            vllmEngine = container "vLLM Engine" "Core inference engine with PagedAttention for GPU memory management" "Python/CUDA"
        }

        kserve = softwareSystem "KServe / Model Serving Stack" "Manages deployment lifecycle of inference services" "RHOAI Platform"
        serviceMesh = softwareSystem "Service Mesh (Istio/OSSM)" "Provides mTLS, authentication, authorization, and TLS termination" "RHOAI Platform"
        modelStorage = softwareSystem "Model Storage" "Stores model weights and artifacts (S3, PVC, or other)" "External"
        konflux = softwareSystem "Konflux CI/CD" "Builds container images via Tekton pipelines" "Build System"
        baseImageRegistry = softwareSystem "Red Hat Container Registry" "Hosts base images (registry.redhat.io)" "External"
        gpu = softwareSystem "NVIDIA GPU" "Hardware accelerator for model inference" "Infrastructure"

        # User interactions
        user -> kserve "Deploys InferenceService"
        application -> serviceMesh "Sends inference requests" "HTTPS/443"

        # Platform interactions
        serviceMesh -> uvicorn "Forwards HTTP requests" "HTTP/8000 mTLS"
        serviceMesh -> tgisAdapter "Forwards gRPC requests" "gRPC/8033 mTLS"
        kserve -> vllm "Deploys and manages lifecycle"

        # Internal flows
        uvicorn -> vllmEngine "Delegates inference"
        tgisAdapter -> vllmEngine "Delegates inference"
        vllmEngine -> gpu "Executes model inference" "CUDA Runtime"
        vllmEngine -> modelStorage "Loads model weights at startup" "HTTPS/443 or filesystem"

        # Build flows
        konflux -> baseImageRegistry "Pulls base image" "HTTPS"
        konflux -> vllm "Builds container image" "Tekton Pipeline"
    }

    views {
        systemContext vllm "SystemContext" {
            include *
            autoLayout
            description "vLLM inference server in the context of the RHOAI platform"
        }

        container vllm "Containers" {
            include *
            autoLayout
            description "Internal structure of the vLLM inference container"
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "RHOAI Platform" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Build System" {
                background #f5a623
                color #ffffff
            }
            element "Infrastructure" {
                background #e8e8e8
                color #333333
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

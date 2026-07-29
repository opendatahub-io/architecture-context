workspace {
    model {
        datascientist = person "Data Scientist" "Deploys LLM models for inference"
        application = person "Application / Client" "Sends inference requests to deployed models"

        vllmSpyre = softwareSystem "vllm-spyre" "IBM Spyre accelerated vLLM inference server with OpenAI-compatible HTTP and TGIS gRPC endpoints for LLM serving on x86_64 RHEL 9" {
            uvicorn = container "uvicorn HTTP Server" "Serves OpenAI-compatible REST API" "Python / uvicorn" "Port 8000/TCP"
            tgisAdapter = container "vllm_tgis_adapter" "Serves TGIS-compatible gRPC inference API" "Python / gRPC" "Port 8033/TCP"
            vllmEngine = container "vLLM Inference Engine" "Executes model inference using IBM Spyre accelerator hardware" "Python / C++"
        }

        kserve = softwareSystem "KServe" "Deploys and manages model serving containers as ServingRuntimes" "Internal RHOAI"
        serviceMesh = softwareSystem "Service Mesh / Istio" "Provides mTLS, traffic management, and authorization policies" "Internal RHOAI"
        hfHub = softwareSystem "Hugging Face Hub" "Hosts pre-trained LLM model weights" "External"
        konflux = softwareSystem "Konflux" "CI/CD pipeline that builds the vllm-spyre container image" "External"
        registry = softwareSystem "Container Registry" "registry.redhat.io - stores built container images (rhaiis/vllm-spyre-rhel9)" "External"

        # Relationships
        application -> vllmSpyre "Sends inference requests" "HTTP/8000, gRPC/8033"
        datascientist -> kserve "Creates InferenceService / ServingRuntime"
        kserve -> vllmSpyre "Deploys and manages pod lifecycle"
        serviceMesh -> vllmSpyre "Injects sidecar, enforces mTLS"
        vllmSpyre -> hfHub "Downloads model weights at startup" "HTTPS/443"
        konflux -> registry "Pushes built image" "HTTPS/443"
        registry -> vllmSpyre "Provides base image (rhaiis/vllm-spyre-rhel9:3.2.2)" "Container Pull"

        # Internal container relationships
        uvicorn -> vllmEngine "Routes HTTP inference requests"
        tgisAdapter -> vllmEngine "Routes gRPC inference requests"
    }

    views {
        systemContext vllmSpyre "SystemContext" {
            include *
            autoLayout
        }

        container vllmSpyre "Containers" {
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
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

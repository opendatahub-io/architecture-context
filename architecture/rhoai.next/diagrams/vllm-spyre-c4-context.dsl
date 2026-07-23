workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and queries LLM inference endpoints"

        vllmSpyre = softwareSystem "vllm-spyre" "IBM Spyre-accelerated vLLM inference server with TGIS adapter for high-performance LLM serving" {
            tgisAdapter = container "vllm_tgis_adapter" "Entrypoint wrapping vLLM engine to provide dual API surfaces" "Python"
            vllmEngine = container "vLLM Engine" "High-performance LLM inference engine with IBM Spyre acceleration" "Python/C++"
            httpApi = container "OpenAI-compatible API" "REST API for text/chat completions" "HTTP/8000"
            grpcApi = container "TGIS gRPC API" "Text Generation Inference Server gRPC endpoint" "gRPC/8033"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication and authorization sidecar injected by RHOAI platform" "Sidecar"
        kserve = softwareSystem "KServe" "Serverless ML inference platform managing ServingRuntime deployments" "Internal RHOAI"
        modelStorage = softwareSystem "Model Storage (PVC)" "Persistent volume providing model weights" "Internal"
        hfHub = softwareSystem "HuggingFace Hub" "Model artifact repository (optional fallback)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection for inference performance monitoring" "Internal RHOAI"
        spyreHW = softwareSystem "IBM Spyre Accelerator" "Hardware acceleration for LLM inference workloads" "Hardware"
        rhaiisBase = softwareSystem "RHAIIS Base Image" "Red Hat AI Inference Server product image providing vLLM, PyTorch, Spyre runtime" "Build Dependency"

        user -> kubeRbacProxy "Sends inference requests" "HTTPS/8443, Bearer Token"
        kubeRbacProxy -> vllmSpyre "Proxies authorized requests" "HTTP/8000, gRPC/8033 (localhost)"
        kserve -> vllmSpyre "Deploys and manages via ServingRuntime CR"
        vllmSpyre -> modelStorage "Loads model weights at startup" "filesystem mount"
        vllmSpyre -> hfHub "Downloads model artifacts (if not pre-staged)" "HTTPS/443, HF_TOKEN"
        vllmSpyre -> spyreHW "Uses hardware acceleration for inference"
        prometheus -> vllmSpyre "Scrapes inference metrics" "HTTP/8000 /metrics"
        rhaiisBase -> vllmSpyre "Provides base image with all ML dependencies" "Build time"
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
            element "Internal" {
                background #4a90e2
                color #ffffff
            }
            element "Sidecar" {
                background #e8a838
                color #ffffff
            }
            element "Hardware" {
                background #9b59b6
                color #ffffff
            }
            element "Build Dependency" {
                background #95a5a6
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        platformadmin = person "Platform Admin" "Manages RHOAI platform and serving runtimes"

        vllmSpyre = softwareSystem "vLLM Spyre" "IBM Spyre-accelerated vLLM inference runtime with TGIS gRPC adapter for high-performance LLM inference on RHEL 9" {
            httpApi = container "HTTP API Server" "OpenAI-compatible REST API for text/chat completions" "uvicorn/FastAPI" "Port 8000/TCP"
            grpcApi = container "gRPC API Server" "TGIS GenerationService for KServe model serving" "gRPC" "Port 8033/TCP"
            vllmEngine = container "vLLM Engine" "Core inference engine with Spyre hardware acceleration" "Python"
            tgisAdapter = container "vllm_tgis_adapter" "Bridges vLLM engine with gRPC TGIS protocol" "Python"
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform managing InferenceService lifecycle" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator managing ServingRuntime CRs" "Internal RHOAI"
        servingRuntime = softwareSystem "ServingRuntime CR" "Custom resource referencing vllm-spyre container image" "Internal RHOAI"
        spyreHardware = softwareSystem "IBM Spyre Accelerator" "Hardware AI accelerator card for inference workloads" "Hardware"
        s3Storage = softwareSystem "S3 Storage" "Object storage for model weights and artifacts" "External"
        hfHub = softwareSystem "Hugging Face Hub" "Model repository for downloading weights and tokenizers" "External"
        pvcStorage = softwareSystem "PVC Storage" "Kubernetes persistent volume for local model storage" "Infrastructure"

        # Relationships
        datascientist -> kserve "Creates InferenceService CR" "kubectl / Dashboard"
        datascientist -> vllmSpyre "Sends inference requests" "HTTPS via platform ingress"
        platformadmin -> rhodsOperator "Configures serving runtimes"

        kserve -> vllmSpyre "Routes inference traffic" "HTTP/8000, gRPC/8033"
        rhodsOperator -> servingRuntime "Manages lifecycle"
        servingRuntime -> vllmSpyre "References container image"

        vllmSpyre -> spyreHardware "Offloads inference computation" "Hardware interface"
        vllmSpyre -> s3Storage "Downloads model weights at startup" "HTTPS/443, AWS IAM"
        vllmSpyre -> hfHub "Downloads models/tokenizers" "HTTPS/443, Bearer Token"
        vllmSpyre -> pvcStorage "Loads model from persistent volume" "Filesystem"

        tgisAdapter -> httpApi "Starts HTTP server"
        tgisAdapter -> grpcApi "Starts gRPC server"
        tgisAdapter -> vllmEngine "Wraps inference engine"
        vllmEngine -> spyreHardware "Hardware acceleration"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Hardware" {
                background #f5a623
                color #ffffff
            }
            element "Infrastructure" {
                background #b8b8b8
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

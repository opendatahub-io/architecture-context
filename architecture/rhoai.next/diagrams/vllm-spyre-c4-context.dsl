workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys LLM inference workloads"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and runtimes"

        vllmSpyre = softwareSystem "vLLM Spyre" "IBM Spyre-accelerated vLLM inference runtime with TGIS gRPC adapter for high-performance LLM serving on RHEL 9" {
            httpApi = container "HTTP API Server" "OpenAI-compatible REST API for text/chat completions" "Python (uvicorn)" "8000/TCP"
            grpcApi = container "gRPC TGIS Server" "IBM Text Generation Inference Server protocol for KServe model serving" "Python (gRPC)" "8033/TCP"
            vllmEngine = container "vLLM Inference Engine" "Core inference engine with IBM Spyre hardware acceleration" "Python"
            tgisAdapter = container "vllm_tgis_adapter" "Entrypoint module bridging vLLM with TGIS gRPC protocol" "Python"
        }

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform — deploys vllm-spyre as InferenceService runtime" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator — manages ServingRuntime CRs and image lifecycle" "Internal RHOAI"
        servingRuntime = softwareSystem "ServingRuntime CR" "Custom resource referencing vllm-spyre container image for KServe deployments" "Internal RHOAI"

        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for model weights and artifacts" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Public model repository for weights and tokenizers" "External"
        spyreHardware = softwareSystem "IBM Spyre Accelerator" "Hardware AI accelerator card for inference workloads" "External Hardware"

        # Relationships
        dataScientist -> kserve "Creates InferenceService via kubectl/dashboard"
        mlEngineer -> rhodsOperator "Configures ServingRuntime CRs"

        kserve -> vllmSpyre "Deploys as model serving runtime container" "HTTP/8000, gRPC/8033"
        rhodsOperator -> servingRuntime "Manages lifecycle"
        servingRuntime -> vllmSpyre "References container image"

        vllmSpyre -> spyreHardware "Executes inference" "Hardware interface"
        vllmSpyre -> s3Storage "Downloads model weights at startup" "HTTPS/443, TLS 1.2+, AWS IAM"
        vllmSpyre -> huggingFace "Downloads model weights/tokenizers" "HTTPS/443, TLS 1.2+, Bearer Token"

        # Internal relationships
        tgisAdapter -> httpApi "Manages"
        tgisAdapter -> grpcApi "Manages"
        httpApi -> vllmEngine "Delegates inference"
        grpcApi -> vllmEngine "Delegates inference"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Hardware" {
                background #e8563a
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
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

workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries ML models for inference"
        application = person "Application Client" "Sends inference requests via OpenAI-compatible API"

        vllmSpyre = softwareSystem "vllm-spyre" "IBM Spyre accelerator-optimized vLLM inference runtime providing OpenAI HTTP and TGIS gRPC APIs" {
            vllmTgisAdapter = container "vllm_tgis_adapter" "Unified inference server exposing dual-protocol APIs (OpenAI HTTP + TGIS gRPC) via uvicorn ASGI" "Python (uvicorn)"
            openaiAPI = container "OpenAI HTTP API" "OpenAI-compatible REST API for completions, chat, and model listing" "HTTP/8000"
            tgisAPI = container "TGIS gRPC API" "IBM Text Generation Inference Server protocol for KServe integration" "gRPC/8033"
            spyreDriver = container "Spyre Accelerator Interface" "Hardware driver interface for IBM Spyre accelerator cards" "PCIe Device Driver"
        }

        kserve = softwareSystem "KServe" "ML model serving orchestration platform" "Internal RHOAI"
        rhoaiGateway = softwareSystem "RHOAI Gateway" "Platform ingress gateway providing TLS termination and authentication" "Internal RHOAI"
        servingRuntime = softwareSystem "ServingRuntime CR" "Custom Resource referencing this container image for Spyre workloads" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"

        s3 = softwareSystem "Model Storage (S3)" "Object storage for ML model weights and artifacts" "External"
        pvc = softwareSystem "Model Storage (PVC)" "Persistent volume for model weights" "External"
        huggingface = softwareSystem "Hugging Face Hub" "Model and tokenizer repository" "External"
        spyreHardware = softwareSystem "IBM Spyre Accelerator" "Hardware accelerator card for LLM inference" "Hardware"

        # User interactions
        application -> rhoaiGateway "Sends inference requests" "HTTPS/443, TLS 1.3, Bearer Token"
        datascientist -> kserve "Creates InferenceService via kubectl"

        # Platform interactions
        rhoaiGateway -> vllmSpyre "Forwards inference requests" "HTTP/8000"
        kserve -> vllmSpyre "Manages pod lifecycle, routes gRPC" "HTTP/8000, gRPC/8033"
        servingRuntime -> vllmSpyre "References container image" "Image reference"
        prometheus -> vllmSpyre "Scrapes metrics" "HTTP/8000 /metrics"

        # Internal container interactions
        vllmTgisAdapter -> openaiAPI "Serves HTTP requests"
        vllmTgisAdapter -> tgisAPI "Serves gRPC requests"
        vllmTgisAdapter -> spyreDriver "Dispatches inference to hardware"

        # External service interactions
        vllmSpyre -> s3 "Downloads model weights" "HTTPS/443, TLS 1.2+, AWS IAM"
        vllmSpyre -> pvc "Reads model weights" "Filesystem volume mount"
        vllmSpyre -> huggingface "Downloads models/tokenizers" "HTTPS/443, TLS 1.2+, Bearer Token"
        vllmSpyre -> spyreHardware "Inference computation" "PCIe device driver"
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
            element "Hardware" {
                background #e8563a
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

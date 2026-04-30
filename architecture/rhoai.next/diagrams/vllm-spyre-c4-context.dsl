workspace {
    model {
        user = person "Data Scientist / API Client" "Sends inference requests to deployed ML models"

        vllmSpyre = softwareSystem "vllm-spyre" "IBM Spyre accelerator-optimized vLLM inference runtime with OpenAI HTTP and TGIS gRPC APIs" {
            tgisAdapter = container "vllm_tgis_adapter" "Entrypoint that launches both HTTP and gRPC servers in a single process" "Python / uvicorn"
            httpServer = container "OpenAI HTTP Server" "Serves OpenAI-compatible completions, chat, and model listing APIs" "vLLM / HTTP 8000"
            grpcServer = container "TGIS gRPC Server" "Serves IBM TGIS protocol for KServe predictor-transformer communication" "gRPC 8033"
            vllmEngine = container "vLLM Inference Engine" "Handles tokenization, model loading, and inference execution" "Python / vLLM"
        }

        kserve = softwareSystem "KServe" "Orchestrates model serving, creates pods using this image as inference runtime" "Internal RHOAI"
        rhoaiGateway = softwareSystem "RHOAI Gateway" "Platform ingress gateway providing TLS termination and auth" "Internal RHOAI"
        servingRuntime = softwareSystem "ServingRuntime CR" "Custom resource referencing this container image for Spyre workloads" "Internal RHOAI"
        modelStorage = softwareSystem "Model Storage (S3/PVC)" "Stores ML model weights and artifacts" "External"
        hfHub = softwareSystem "Hugging Face Hub" "Public model and tokenizer repository" "External"
        spyreHW = softwareSystem "IBM Spyre Accelerator" "Hardware accelerator card for LLM inference" "Hardware"
        prometheus = softwareSystem "Prometheus" "Metrics collection system" "Internal RHOAI"

        user -> rhoaiGateway "Sends inference requests" "HTTPS/443 TLS 1.3"
        rhoaiGateway -> vllmSpyre "Forwards requests" "HTTP/8000"
        kserve -> vllmSpyre "Creates and manages pods" "Kubernetes API"
        servingRuntime -> vllmSpyre "References container image" "Image pull"
        kserve -> vllmSpyre "Routes gRPC traffic" "gRPC/8033"
        vllmSpyre -> modelStorage "Downloads model weights" "HTTPS/443 or filesystem"
        vllmSpyre -> hfHub "Downloads tokenizer configs" "HTTPS/443"
        vllmSpyre -> spyreHW "Accelerated compute" "PCIe/device driver"
        prometheus -> vllmSpyre "Scrapes metrics" "HTTP/8000 /metrics"

        tgisAdapter -> httpServer "Starts"
        tgisAdapter -> grpcServer "Starts"
        httpServer -> vllmEngine "Inference requests"
        grpcServer -> vllmEngine "Inference requests"
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
                background #d4380d
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
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

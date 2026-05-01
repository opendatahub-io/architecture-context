workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        application = person "Application" "Client application consuming LLM inference API"

        vllmCpu = softwareSystem "vLLM-CPU" "CPU-optimized LLM inference server providing OpenAI-compatible API" {
            apiServer = container "OpenAI API Server" "FastAPI/Uvicorn HTTP server with modular API routers" "Python (FastAPI)" "Web Server"
            grpcServer = container "gRPC Server" "Alternative gRPC entrypoint for inference" "Python (grpc.aio)" "Service"
            authMiddleware = container "Authentication Middleware" "API key validation for /v1/* endpoints" "Python" "Middleware"
            asyncEngine = container "AsyncLLM Engine (V1)" "Asynchronous inference engine with PagedAttention, continuous batching, KV cache" "Python" "Engine"
            modelExecutor = container "Model Executor" "CPU-optimized model execution with native C/C++ kernels" "Python + C/C++" "Compute"
            prometheusInstr = container "Prometheus Instrumentator" "Metrics collection and /metrics endpoint" "Python" "Monitoring"
        }

        kserve = softwareSystem "KServe" "Kubernetes model serving platform managing ServingRuntime CRDs" "Internal RHOAI"
        huggingFaceHub = softwareSystem "Hugging Face Hub" "Model weights and tokenizer artifact repository" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts via tensorizer" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring platform" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend" "External"

        # External relationships
        application -> vllmCpu "Sends inference requests" "HTTPS/443 (via KServe)"
        dataScientist -> kserve "Deploys InferenceService with vLLM-CPU ServingRuntime" "kubectl"
        kserve -> vllmCpu "Deploys and routes traffic" "HTTP/8000"
        vllmCpu -> huggingFaceHub "Downloads model weights and tokenizers" "HTTPS/443"
        vllmCpu -> s3Storage "Loads models via tensorizer" "HTTPS/443"
        prometheus -> vllmCpu "Scrapes metrics" "HTTP/8000"
        vllmCpu -> otelCollector "Exports tracing spans" "gRPC/HTTP (optional)"

        # Internal container relationships
        application -> apiServer "POST /v1/chat/completions, /v1/completions, /v1/responses, /v1/messages" "HTTP/8000"
        application -> grpcServer "gRPC inference calls" "gRPC/50051"
        apiServer -> authMiddleware "Validates API key" "in-process"
        authMiddleware -> asyncEngine "Submits inference request" "in-process async"
        grpcServer -> asyncEngine "Submits inference request" "in-process async"
        asyncEngine -> modelExecutor "Executes model forward pass" "in-process"
        asyncEngine -> huggingFaceHub "Downloads model artifacts" "HTTPS/443 (HF_TOKEN)"
        asyncEngine -> s3Storage "Downloads model via tensorizer" "HTTPS/443 (AWS IAM)"
        prometheus -> prometheusInstr "Scrapes /metrics" "HTTP/8000"
    }

    views {
        systemContext vllmCpu "SystemContext" {
            include *
            autoLayout
        }

        container vllmCpu "Containers" {
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
                background #08427b
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
            element "Web Server" {
                shape WebBrowser
            }
            element "Middleware" {
                shape Component
            }
        }
    }
}

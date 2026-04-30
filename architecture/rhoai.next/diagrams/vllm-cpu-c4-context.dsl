workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        application = person "Application Developer" "Integrates LLM inference into applications via API"

        vllmCpu = softwareSystem "vLLM-CPU" "CPU-optimized LLM inference server providing OpenAI-compatible REST API" {
            apiServer = container "OpenAI API Server" "FastAPI/Uvicorn HTTP server providing OpenAI, Anthropic, and custom API endpoints" "Python (FastAPI)" "Web Server"
            grpcServer = container "gRPC Server" "Alternative gRPC entrypoint for inference via smg-grpc-servicer" "Python (grpc.aio)" "gRPC Service"
            asyncEngine = container "AsyncLLM Engine (V1)" "Asynchronous inference engine with PagedAttention, continuous batching, and KV cache management" "Python" "Engine"
            modelExecutor = container "Model Executor" "CPU-optimized model execution with native C/C++ kernels compiled via CMake" "Python + C/C++" "Compute"
            prometheusInstr = container "Prometheus Instrumentator" "Metrics collection and exposure via /metrics endpoint" "Python" "Middleware"
        }

        kserve = softwareSystem "KServe" "Deploys and routes traffic to vLLM-CPU as a ServingRuntime" "Internal RHOAI"
        hfHub = softwareSystem "Hugging Face Hub" "Model weights and tokenizer artifact repository" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Alternative model artifact storage via tensorizer" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring system" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection (optional)" "External"
        mcpServers = softwareSystem "MCP Tool Servers" "External tool calling via Model Context Protocol (optional)" "External"

        # Person relationships
        datascientist -> kserve "Deploys InferenceService with vLLM-CPU ServingRuntime"
        application -> vllmCpu "Sends inference requests" "HTTPS/443 via KServe"

        # System context relationships
        kserve -> vllmCpu "Routes inference traffic" "HTTP/8000"
        vllmCpu -> hfHub "Downloads model weights and tokenizers" "HTTPS/443, Bearer Token"
        vllmCpu -> s3Storage "Loads model artifacts via tensorizer" "HTTPS/443, AWS IAM"
        prometheus -> vllmCpu "Scrapes metrics from /metrics" "HTTP/8000"
        vllmCpu -> otelCollector "Exports distributed traces (optional)" "gRPC/HTTP"
        vllmCpu -> mcpServers "Calls external tools (optional)" "HTTP"

        # Container relationships
        application -> apiServer "POST /v1/chat/completions, /v1/completions, etc." "HTTP/8000, API Key"
        application -> grpcServer "gRPC inference calls" "gRPC/50051, plaintext"
        apiServer -> asyncEngine "Submits inference requests" "in-process async"
        grpcServer -> asyncEngine "Submits inference requests" "in-process async"
        asyncEngine -> modelExecutor "Executes model forward pass" "in-process"
        prometheusInstr -> apiServer "Instruments HTTP requests" "middleware"
        modelExecutor -> hfHub "Downloads model artifacts at startup" "HTTPS/443"
        modelExecutor -> s3Storage "Downloads model artifacts (alternative)" "HTTPS/443"
        asyncEngine -> otelCollector "Exports tracing spans" "gRPC/HTTP (optional)"
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
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Web Server" {
                shape RoundedBox
                background #4a90e2
                color #ffffff
            }
            element "gRPC Service" {
                shape RoundedBox
                background #4a90e2
                color #ffffff
            }
            element "Engine" {
                shape RoundedBox
                background #7ed321
                color #ffffff
            }
            element "Compute" {
                shape RoundedBox
                background #f5a623
                color #ffffff
            }
            element "Middleware" {
                shape RoundedBox
                background #9b59b6
                color #ffffff
            }
        }
    }
}

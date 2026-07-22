workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLMs for inference"
        application = person "Application" "Sends inference requests via OpenAI-compatible API"

        vllmCpu = softwareSystem "vllm-cpu" "CPU-optimized LLM inference server providing OpenAI-compatible REST and gRPC APIs" {
            openaiServer = container "OpenAI API Server" "OpenAI-compatible REST API for chat/text completions, embeddings, and model management" "Python (FastAPI/Uvicorn)" "Port 8000/TCP"
            grpcServer = container "gRPC Server" "Alternative gRPC backend for engine-level inference access" "Python (gRPC/smg-grpc-servicer)" "Port 50051/TCP"
            mcpToolServer = container "MCP Tool Server" "Model Context Protocol integration for external tool calling" "Python"
            asyncEngine = container "AsyncLLM Engine" "Async inference engine with continuous batching, KV cache management, and scheduling" "Python"
            rustExtensions = container "Rust Extensions" "High-performance tokenization, tool parsing, chat rendering via 13 PyO3 crates" "Rust (PyO3)"
            cppExtensions = container "C++ Extensions" "CPU-optimized kernels with ISA-specific variants (AVX-512, AVX2, BF16)" "C++ (CMake)"
            dpSupervisor = container "DP Supervisor" "Data parallel supervisor with readiness probes" "Python" "Port 9256/TCP"
        }

        kserve = softwareSystem "KServe" "Serverless model serving platform that deploys vllm-cpu as an InferenceService" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Red Hat OpenShift AI operator managing platform lifecycle" "Internal RHOAI"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model weight and tokenizer repository" "External"
        modelStorage = softwareSystem "Model Storage (S3/GCS/PVC)" "Model artifact storage" "External"
        redhatTelemetry = softwareSystem "Red Hat Telemetry" "Usage statistics collection at console.redhat.com" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "Internal Platform"
        mcpToolServers = softwareSystem "MCP Tool Servers" "External tool servers for Model Context Protocol" "External"
        exaSearch = softwareSystem "Exa Web Search" "Web search API for tool calling (demo mode)" "External"

        # User interactions
        dataScientist -> kserve "Deploys InferenceService with vllm-cpu runtime" "kubectl/Dashboard"
        application -> vllmCpu "Sends inference requests" "HTTP/8000, gRPC/50051"

        # Container-level interactions
        application -> openaiServer "POST /v1/chat/completions" "HTTP/8000 Configurable TLS"
        application -> grpcServer "VllmEngine RPC" "gRPC/50051 No encryption"
        openaiServer -> asyncEngine "Inference requests" "In-process Python"
        grpcServer -> asyncEngine "Inference requests" "In-process Python"
        asyncEngine -> rustExtensions "Tokenization, parsing" "PyO3 bindings"
        asyncEngine -> cppExtensions "CPU kernel execution" "C bindings"
        openaiServer -> mcpToolServer "Tool calls" "In-process Python"

        # Platform dependencies
        kserve -> vllmCpu "Deploys as container in InferenceService"
        rhodsOperator -> kserve "Manages KServe lifecycle"

        # External egress
        vllmCpu -> huggingfaceHub "Downloads model weights and tokenizers" "HTTPS/443 Bearer Token"
        vllmCpu -> modelStorage "Downloads model artifacts" "HTTPS/443 Cloud IAM"
        vllmCpu -> redhatTelemetry "Reports usage statistics" "HTTPS/443"
        mcpToolServer -> mcpToolServers "External tool calling" "HTTP/SSE"
        mcpToolServer -> exaSearch "Web search queries" "HTTPS/443 API Key"

        # Observability
        prometheus -> vllmCpu "Scrapes /metrics endpoint" "HTTP/8000"
        vllmCpu -> otelCollector "Exports traces" "OTLP gRPC/HTTP"
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
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
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
        }
    }
}

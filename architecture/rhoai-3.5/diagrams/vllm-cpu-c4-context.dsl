workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models for inference on CPU hardware"
        mlEngineer = person "ML Engineer" "Configures model serving, LoRA adapters, and quantization"

        vllmCpu = softwareSystem "vLLM CPU" "CPU-only high-throughput inference engine for large language models, providing OpenAI-compatible API" {
            apiServer = container "vllm-openai" "OpenAI-compatible API server (FastAPI + Uvicorn)" "Python" {
                authMiddleware = component "AuthenticationMiddleware" "Bearer Token validation (SHA256 hashed, timing-safe)" "FastAPI Middleware"
                chatCompletions = component "Chat Completions" "/v1/chat/completions endpoint" "FastAPI Route"
                completions = component "Completions" "/v1/completions endpoint" "FastAPI Route"
                embeddings = component "Embeddings" "/v1/embeddings endpoint" "FastAPI Route"
                metricsEndpoint = component "Metrics" "/metrics Prometheus endpoint" "FastAPI Route"
            }
            rustFrontend = container "vllm-rs" "High-performance tokenizer, chat template renderer, tool/reasoning parser" "Rust (PyO3)"
            engineCore = container "vLLM Engine Core" "Continuous batching scheduler, KV cache manager, model executor" "Python + PyTorch"
            cppExtensions = container "C/C++ Extensions" "CPU-optimized attention kernels (AVX2, AVX512)" "C/C++ (CMake)"
            grpcServer = container "gRPC Server" "LLM inference via gRPC protocol" "Python (grpcio)"
        }

        kserve = softwareSystem "KServe" "Kubernetes serverless inference platform, manages vLLM pod lifecycle" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator managing HTTPRoute/Route for external traffic" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata storage" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "RHOAI web console for model serving management" "Internal RHOAI"

        huggingFaceHub = softwareSystem "HuggingFace Hub" "Model weight and tokenizer hosting" "External"
        s3Storage = softwareSystem "Object Storage (S3/PVC)" "Model artifact storage" "External"

        # Relationships
        dataScientist -> vllmCpu "Sends inference requests via" "HTTPS (platform-managed)"
        mlEngineer -> kserve "Creates InferenceService via" "kubectl / Dashboard"
        mlEngineer -> dashboard "Configures model serving via" "HTTPS"

        kserve -> vllmCpu "Deploys and manages pod lifecycle" "Kubernetes API"
        rhodsOperator -> vllmCpu "Routes external traffic via" "HTTPRoute/Route"

        vllmCpu -> huggingFaceHub "Downloads model weights" "HTTPS/443 TLS 1.2+ Bearer Token"
        vllmCpu -> s3Storage "Loads model artifacts" "HTTPS/443 or File I/O"
        vllmCpu -> otelCollector "Exports distributed traces" "gRPC/4317 OTLP"
        prometheus -> vllmCpu "Scrapes metrics" "HTTP/8000 GET /metrics"

        dashboard -> kserve "Manages InferenceServices" "Kubernetes API"

        # Container relationships
        apiServer -> rustFrontend "Tokenizes, renders templates, parses tool calls" "PyO3 FFI"
        apiServer -> engineCore "Schedules inference requests" "In-process"
        engineCore -> cppExtensions "Calls CPU attention kernels" "C FFI"
        grpcServer -> engineCore "Schedules inference requests" "In-process"
    }

    views {
        systemContext vllmCpu "SystemContext" {
            include *
            autoLayout
            description "vLLM CPU in the RHOAI platform ecosystem"
        }

        container vllmCpu "Containers" {
            include *
            autoLayout
            description "Internal structure of vLLM CPU inference service"
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

workspace {
    model {
        user = person "Application Developer" "Sends inference requests to deployed LLM models"
        mlEngineer = person "ML Engineer" "Configures and deploys model serving instances"

        vllmCpu = softwareSystem "vLLM CPU" "CPU-optimized LLM inference engine providing OpenAI-compatible API serving" {
            apiServer = container "OpenAI API Server" "FastAPI + Uvicorn HTTP server exposing OpenAI-compatible, Anthropic, and SageMaker endpoints" "Python (FastAPI)" "Web Server"
            grpcServer = container "gRPC Server" "Optional gRPC inference endpoint using smg-grpc-servicer" "Python (gRPC)" "Service"
            asyncEngine = container "AsyncLLM Engine" "Core inference engine managing scheduler, KV cache, and worker orchestration" "Python" "Engine"
            workerProcesses = container "Worker Processes" "Fork-based or ZMQ IPC worker processes executing model inference" "Python" "Worker"
            cpuKernels = container "CPU Kernels" "Optimized C/C++ attention, quantization, and GEMM kernels for CPU execution" "C/C++" "Library"
            rustLib = container "Rust Library" "Chat template rendering, tool-call parsing, and tokenization" "Rust" "Library"
            dpSupervisor = container "DP Supervisor" "Data-parallel supervisor aggregating health across worker processes" "Python" "Service"
            authMiddleware = container "Auth Middleware" "Bearer token authentication with SHA-256 constant-time comparison" "Python (ASGI)" "Middleware"
            sslRefresher = container "SSL Cert Refresher" "Watches TLS certificate files and hot-reloads via watchfiles" "Python" "Module"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Platform that deploys and manages vLLM inference pods" "External Platform"
        hfHub = softwareSystem "HuggingFace Hub" "Model weight and configuration hosting service" "External Service"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for model artifacts" "External Service"
        prometheus = softwareSystem "Prometheus" "Metrics collection via HTTP scrape" "External Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External Platform"
        statsVllm = softwareSystem "stats.vllm.ai" "vLLM usage analytics service" "External Service"

        # User interactions
        user -> vllmCpu "Sends inference requests (chat, completions, embeddings)" "HTTP/8000, gRPC/50051"
        mlEngineer -> vllmCpu "Manages LoRA adapters, profiles, configuration" "HTTP/8000"

        # Internal container interactions
        apiServer -> authMiddleware "Delegates authentication" "In-process"
        apiServer -> sslRefresher "Manages TLS certificates" "In-process"
        apiServer -> asyncEngine "Submits inference requests" "In-process"
        grpcServer -> asyncEngine "Submits inference requests" "In-process"
        dpSupervisor -> apiServer "Aggregates health checks" "HTTP/8000"
        asyncEngine -> workerProcesses "Schedules inference work" "Fork / ZMQ IPC"
        workerProcesses -> cpuKernels "Executes optimized CPU operations" "In-process (FFI)"
        workerProcesses -> rustLib "Renders chat templates, parses tool calls" "In-process (PyO3)"

        # External interactions
        vllmCpu -> hfHub "Downloads model weights and configs" "HTTPS/443 (HF_TOKEN)"
        vllmCpu -> s3Storage "Downloads/stores model artifacts" "HTTPS/443 (AWS IAM)"
        vllmCpu -> statsVllm "Reports usage statistics" "HTTPS/443"
        vllmCpu -> otelCollector "Exports distributed traces" "OTLP (configurable)"

        # Platform interactions
        kserve -> vllmCpu "Deploys as inference container, manages routing" "HTTP/8000"
        prometheus -> vllmCpu "Scrapes metrics" "HTTP/8000"
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
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "External Platform" {
                background #7ed321
                color #ffffff
            }
            element "Web Server" {
                background #4a90e2
                color #ffffff
            }
            element "Engine" {
                background #4a90e2
                color #ffffff
            }
            element "Worker" {
                background #4a90e2
                color #ffffff
            }
            element "Library" {
                background #e8744f
                color #ffffff
            }
            element "Middleware" {
                background #f5a623
                color #ffffff
            }
            element "Module" {
                background #9b59b6
                color #ffffff
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

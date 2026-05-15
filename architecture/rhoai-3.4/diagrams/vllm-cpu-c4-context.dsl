workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        application = person "Application / Client" "Sends inference requests via OpenAI-compatible API"

        vllmCpu = softwareSystem "vLLM CPU" "CPU-optimized LLM inference server exposing OpenAI-compatible API, Anthropic Messages API, and gRPC interface" {
            apiServer = container "OpenAI API Server" "FastAPI + Uvicorn HTTP server exposing /v1/chat/completions, /v1/completions, /v1/embeddings, and 20+ endpoints" "Python (FastAPI)" "Web Server"
            grpcServer = container "gRPC Server" "Optional gRPC interface for LLM inference via VllmEngine protobuf service" "Python (gRPC)" "Service"
            asyncEngine = container "AsyncLLM Engine (v1)" "Core inference engine with PagedAttention, continuous batching, and model execution" "Python" "Engine"
            modelExecutor = container "Model Executor" "Loads model weights, manages 150+ model architectures, executes inference" "Python" "Library"
            csrcKernels = container "CPU Kernels (csrc)" "Native CPU-optimized kernels for attention, quantization, tensor ops" "C/C++ (CMake)" "Native Library"
            authMiddleware = container "Auth Middleware" "ASGI middleware validating Bearer token via SHA-256 comparison" "Python" "Security"
        }

        kserve = softwareSystem "KServe" "Manages ServingRuntime lifecycle, scaling, and routing for inference services" "Internal RHOAI"
        rhoaiGateway = softwareSystem "RHOAI Gateway (Envoy)" "Platform ingress via HTTPRoute (Gateway API) for external access" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization sidecar injected by RHOAI platform" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection via /metrics endpoint scraping" "Internal RHOAI"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed trace collection via OTLP" "Internal RHOAI"

        hfHub = softwareSystem "Hugging Face Hub" "Model weights, tokenizer, and config hosting" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Alternative model artifact storage" "External"

        # Relationships - External
        application -> rhoaiGateway "Sends inference requests" "HTTPS/443, TLS 1.2+, Bearer Token (OAuth/OIDC)"
        datascientist -> kserve "Deploys InferenceService" "kubectl / RHOAI Dashboard"

        # Relationships - Ingress chain
        rhoaiGateway -> kubeRbacProxy "Forwards requests" "HTTPS/8443, TLS 1.2+"
        kubeRbacProxy -> vllmCpu "Forwards authenticated requests" "HTTP/8000, plaintext (localhost)"

        # Relationships - Internal
        apiServer -> authMiddleware "Validates API keys" "In-process"
        authMiddleware -> asyncEngine "Passes validated requests" "In-process / ZeroMQ IPC"
        grpcServer -> asyncEngine "Sends inference requests" "In-process / ZeroMQ IPC"
        asyncEngine -> modelExecutor "Executes inference" "In-process"
        modelExecutor -> csrcKernels "Calls optimized kernels" "In-process (C FFI)"

        # Relationships - Egress
        vllmCpu -> hfHub "Downloads model weights, tokenizer, config" "HTTPS/443, TLS 1.2+, Bearer Token (HF_TOKEN)"
        vllmCpu -> s3Storage "Downloads model artifacts" "HTTPS/443, TLS 1.2+, AWS IAM"

        # Relationships - Observability
        prometheus -> vllmCpu "Scrapes metrics" "HTTP/8000, GET /metrics"
        vllmCpu -> otel "Exports traces" "gRPC/4317 or HTTP/4318, OTLP, TLS 1.2+"

        # Relationships - Platform
        kserve -> vllmCpu "Manages container lifecycle, scaling" "Kubernetes API"
    }

    views {
        systemContext vllmCpu "SystemContext" {
            include *
            autoLayout
            description "vLLM CPU system context showing external users, platform components, and dependencies"
        }

        container vllmCpu "Containers" {
            include *
            autoLayout
            description "vLLM CPU internal container architecture showing API servers, engine, and execution layers"
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Web Server" {
                shape WebBrowser
            }
            element "Security" {
                background #e74c3c
                color #ffffff
            }
            element "Native Library" {
                background #2ecc71
                color #ffffff
            }
        }
    }
}

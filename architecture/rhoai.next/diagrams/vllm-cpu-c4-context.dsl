workspace {
    model {
        user = person "ML Engineer / Application" "Sends inference requests to deployed models"

        vllmCpu = softwareSystem "vllm-cpu" "CPU-optimized LLM inference server with OpenAI-compatible, Anthropic, and gRPC APIs" {
            apiServer = container "OpenAI API Server" "FastAPI/Uvicorn HTTP server with 47 endpoints across 6 API families" "Python (FastAPI)"
            grpcServer = container "gRPC Server" "Optional gRPC transport for inference (insecure port)" "Python (grpc.aio)"
            authMiddleware = container "AuthenticationMiddleware" "Bearer token validation with SHA-256 constant-time comparison" "ASGI Middleware"
            sslRefresher = container "SSLCertRefresher" "File-watching certificate hot-reload for TLS rotation" "Python Utility"
            asyncEngine = container "AsyncLLM Engine" "Core inference engine with PagedAttention, continuous batching, LoRA support" "Python/C++"
            dpSupervisor = container "Data-Parallel Supervisor" "Health aggregation for multi-port external LB mode" "Python"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Serving runtime orchestration and model deployment" "Internal RHOAI"
        hfHub = softwareSystem "Hugging Face Hub" "Model and tokenizer repository" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage via tensorizer" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing and observability" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "mTLS transport encryption and traffic management" "Internal RHOAI"

        user -> vllmCpu "Sends inference requests" "HTTP/8000 or gRPC/8000"
        vllmCpu -> hfHub "Downloads model weights and tokenizers" "HTTPS/443"
        vllmCpu -> s3Storage "Loads model artifacts via tensorizer" "HTTPS/443"
        prometheus -> vllmCpu "Scrapes metrics" "HTTP/8000"
        vllmCpu -> otel "Exports traces" "OTLP"
        kserve -> vllmCpu "Manages as serving runtime container" "Container lifecycle"
        istio -> vllmCpu "Provides mTLS sidecar encryption" "mTLS"

        apiServer -> authMiddleware "Routes guarded requests through"
        authMiddleware -> asyncEngine "Forwards authenticated requests"
        grpcServer -> asyncEngine "Forwards gRPC inference requests"
        apiServer -> sslRefresher "Uses for TLS cert rotation"
        dpSupervisor -> apiServer "Aggregates health status"
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

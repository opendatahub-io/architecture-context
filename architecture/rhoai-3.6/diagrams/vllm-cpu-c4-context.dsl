workspace {
    model {
        datascientist = person "Data Scientist" "Deploys models and sends inference requests"
        application = person "Application" "Client application consuming inference API"

        vllmcpu = softwareSystem "vLLM CPU" "CPU-optimized high-throughput inference server for LLMs, providing OpenAI-compatible and multi-protocol API" {
            apiServer = container "FastAPI API Server" "Primary HTTP entry point — OpenAI, Anthropic, SageMaker compatible APIs" "Python/FastAPI/Uvicorn" "Port 8000/TCP"
            authMiddleware = container "Authentication Middleware" "Optional ASGI middleware validating bearer tokens" "Python/Starlette"
            asyncEngine = container "AsyncLLM Engine" "Core inference engine with PagedAttention, continuous batching, LoRA support" "Python/PyTorch"
            sslRefresher = container "SSL Cert Refresher" "Watches TLS certificate files and hot-reloads SSL context" "Python/watchfiles"
            dpSupervisor = container "DP Supervisor" "Data-parallel supervisor for multi-port external load balancing" "Python" "Port 9256/TCP"
            grpcServer = container "gRPC Server" "Optional gRPC entry point via smg-grpc-servicer" "Python/gRPC" "Port 50051/TCP"
            cli = container "vllm serve CLI" "CLI entry point for launching the server" "Python"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Kubernetes model serving platform — deploys vLLM as a ServingRuntime" "Internal Platform"
        hfhub = softwareSystem "HuggingFace Hub" "Model weight hosting and download service" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for tensorizer model artifacts" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing via OTLP" "Internal Platform"

        # User interactions
        datascientist -> vllmcpu "Deploys model via KServe ServingRuntime"
        application -> vllmcpu "POST /v1/chat/completions, /v1/embeddings" "HTTP/HTTPS :8000"

        # Internal container relationships
        cli -> apiServer "Launches"
        apiServer -> authMiddleware "Delegates auth"
        authMiddleware -> asyncEngine "Forwards authenticated requests"
        apiServer -> sslRefresher "TLS cert reload"
        dpSupervisor -> apiServer "Manages data-parallel instances"
        grpcServer -> asyncEngine "Inference requests" "gRPC :50051"

        # External dependencies
        vllmcpu -> hfhub "Downloads model weights" "HTTPS/443, Bearer HF_TOKEN"
        vllmcpu -> s3 "Loads tensorizer models" "HTTPS/443, AWS IAM"

        # Platform integrations
        kserve -> vllmcpu "Routes inference traffic" "HTTP/HTTPS :8000"
        prometheus -> vllmcpu "Scrapes /metrics" "HTTP :8000"
        vllmcpu -> otel "Exports traces" "OTLP"
    }

    views {
        systemContext vllmcpu "SystemContext" {
            include *
            autoLayout
        }

        container vllmcpu "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
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

workspace {
    model {
        client = person "API Consumer" "Application or user sending inference requests via REST or gRPC"

        vllmCpu = softwareSystem "vllm-cpu" "High-throughput CPU-optimized LLM inference and serving engine with OpenAI-compatible API" {
            httpServer = container "FastAPI/ASGI Server" "OpenAI-compatible REST API with optional Bearer token authentication" "Python (FastAPI, Uvicorn)"
            authMiddleware = container "AuthenticationMiddleware" "Optional Bearer token validation on /v1, /v2, /inference paths using SHA-256 constant-time comparison" "Python (ASGI Middleware)"
            grpcServer = container "gRPC Server" "Alternative inference entrypoint via VllmEngine service on port 50051 (insecure)" "Python (grpc.aio)"
            asyncEngine = container "AsyncLLM Engine" "Core inference engine performing CPU-based model inference" "Python (vLLM)"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Platform orchestration for serving runtime lifecycle, scaling, and routing" "Internal RHOAI"
        huggingface = softwareSystem "HuggingFace Hub" "Model weight and tokenizer repository" "External"
        rhoaiStats = softwareSystem "RHOAI Usage Stats" "Usage telemetry endpoint at console.redhat.com/api/rhaiis-stats" "External"

        # Relationships
        client -> vllmCpu "Sends inference requests" "HTTP/HTTPS, gRPC"
        client -> httpServer "POST /v1/chat/completions, /v1/completions, /v1/embeddings, etc." "HTTP/HTTPS"
        client -> grpcServer "VllmEngine RPC" "gRPC/50051 (insecure)"

        httpServer -> authMiddleware "Delegates auth for guarded paths" "In-process"
        authMiddleware -> asyncEngine "Forwards authenticated requests" "In-process"
        grpcServer -> asyncEngine "Submits inference requests" "In-process"

        kserve -> vllmCpu "Deploys and manages container lifecycle, scaling, routing"
        asyncEngine -> huggingface "Downloads model weights and tokenizers" "HTTPS/443"
        asyncEngine -> rhoaiStats "Reports usage telemetry" "HTTPS/443"
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

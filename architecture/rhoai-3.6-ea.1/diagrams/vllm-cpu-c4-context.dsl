workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        application = person "Application" "Consumes LLM inference APIs programmatically"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and model deployments"

        vllmCpu = softwareSystem "vllm-cpu" "High-throughput LLM inference serving engine with OpenAI/Anthropic-compatible APIs" {
            fastapiServer = container "FastAPI/ASGI Server" "HTTP server exposing 47 API endpoints across OpenAI, Anthropic, pooling, scoring, and operational surfaces" "Python/FastAPI/Uvicorn"
            authMiddleware = container "Authentication Middleware" "Conditional Bearer token authentication via SHA-256 hash comparison; guards /v1/*, /v2/*, /inference/* paths" "Python ASGI Middleware"
            vllmEngine = container "vLLM Engine" "Core LLM inference engine for high-throughput token generation with PagedAttention" "Python/C++"
            openaiRouter = container "OpenAI API Router" "OpenAI-compatible endpoints: chat/completions, completions, embeddings, models" "FastAPI Router"
            anthropicRouter = container "Anthropic API Router" "Anthropic-compatible messages endpoint" "FastAPI Router"
            poolingRouter = container "Pooling/Scoring Router" "Embedding, reranking, and scoring endpoints" "FastAPI Router"
            loraManager = container "LoRA Manager" "Dynamic loading/unloading of LoRA adapters at runtime" "FastAPI Router"
        }

        s3Storage = softwareSystem "S3-Compatible Storage" "Model weight and artifact storage (AWS S3, MinIO, etc.)" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model repository for downloading model weights and LoRA adapters" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing health probe integration" "External"
        kserve = softwareSystem "KServe" "Model serving framework; vllm-cpu runs as a ServingRuntime" "Internal RHOAI"

        # System context relationships
        datascientist -> vllmCpu "Sends inference requests via OpenAI/Anthropic-compatible APIs" "HTTPS"
        application -> vllmCpu "Consumes inference APIs programmatically" "HTTP/HTTPS"
        platformAdmin -> vllmCpu "Manages model deployments, LoRA adapters, profiling" "HTTP/HTTPS"
        vllmCpu -> s3Storage "Downloads model weights and artifacts" "HTTPS/443"
        vllmCpu -> huggingfaceHub "Downloads models and LoRA adapters" "HTTPS/443"
        kubernetes -> vllmCpu "Sends liveness/readiness probes to /health, /ready" "HTTP"
        kserve -> vllmCpu "Manages as ServingRuntime within RHOAI" "Kubernetes API"

        # Container-level relationships
        datascientist -> fastapiServer "POST /v1/chat/completions" "HTTPS"
        application -> fastapiServer "POST /v1/completions, /v1/embeddings" "HTTPS"
        fastapiServer -> authMiddleware "Routes guarded requests through auth" ""
        authMiddleware -> openaiRouter "Authenticated requests" ""
        authMiddleware -> anthropicRouter "Authenticated requests" ""
        authMiddleware -> poolingRouter "Authenticated requests" ""
        authMiddleware -> loraManager "Authenticated requests" ""
        openaiRouter -> vllmEngine "Inference requests" ""
        anthropicRouter -> vllmEngine "Inference requests" ""
        poolingRouter -> vllmEngine "Scoring/embedding requests" ""
        loraManager -> vllmEngine "Adapter load/unload" ""
        vllmEngine -> s3Storage "Model artifact download" "HTTPS/443 boto3"
        vllmEngine -> huggingfaceHub "Model/adapter download" "HTTPS/443 huggingface_hub"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

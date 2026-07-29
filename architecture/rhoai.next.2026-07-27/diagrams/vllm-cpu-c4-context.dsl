workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        developer = person "Application Developer" "Integrates LLM inference into applications via API"
        sre = person "SRE / Platform Admin" "Monitors and manages the inference server"

        vllmcpu = softwareSystem "vllm-cpu" "CPU-optimized LLM inference server providing OpenAI, Anthropic, SageMaker, and native vLLM API compatibility" {
            authMiddleware = container "ASGI AuthenticationMiddleware" "Validates bearer tokens against VLLM_API_KEY" "Python ASGI Middleware"
            openaiRouter = container "OpenAI-Compatible Router" "Handles /v1/chat/completions, /v1/completions, /v1/embeddings, /v1/models, /v1/responses" "FastAPI Router"
            anthropicRouter = container "Anthropic-Compatible Router" "Handles /v1/messages, /v1/messages/count_tokens" "FastAPI Router"
            sagemakerRouter = container "SageMaker Router" "Handles /invocations, /ping" "FastAPI Router"
            nativeRouter = container "Native vLLM Router" "Handles /generate, /generative_scoring, /tokenize, /detokenize" "FastAPI Router"
            poolingRouter = container "Pooling Router" "Handles /pooling, /classify, /score, /rerank, /v1/embeddings" "FastAPI Router"
            opsRouter = container "Operational Router" "Handles /health, /ready, /readyz, /load, /version, /docs" "FastAPI Router"
            mgmtRouter = container "Management Router" "Handles LoRA adapter load/unload, profiling, elastic EP scaling" "FastAPI Router"
            asyncEngine = container "AsyncLLMEngine" "CPU-optimized inference engine with LoRA adapter support" "Python"
            loraPlugin = container "LoRA Plugin System" "Extensible adapter resolver framework" "Python Plugin"
            mcpTools = container "MCP Tool Integrations" "Optional web browsing (Exa) and code execution (Docker) tools" "Python MCP"
        }

        s3 = softwareSystem "S3 Storage" "Model artifact storage and retrieval" "External"
        modelscope = softwareSystem "ModelScope Hub" "Alternative model registry and download service" "External"
        exa = softwareSystem "Exa Search API" "Web search API for MCP browser tool" "External"
        docker = softwareSystem "Docker Daemon" "Container runtime for sandboxed code execution" "External"
        kserve = softwareSystem "KServe" "Serverless inference platform that may front vllm-cpu" "Internal RHOAI"

        datascientist -> vllmcpu "Sends inference requests via OpenAI or Anthropic-compatible API" "HTTPS/8000"
        developer -> vllmcpu "Integrates via REST API for chat completions, embeddings, scoring" "HTTPS/8000"
        sre -> vllmcpu "Monitors health, load, profiles performance" "HTTP(S)/8000"
        kserve -> vllmcpu "Routes inference traffic to vllm-cpu pods" "HTTP/8000"

        vllmcpu -> s3 "Downloads model artifacts" "HTTPS/443"
        vllmcpu -> modelscope "Downloads models from ModelScope" "HTTPS/443"
        vllmcpu -> exa "Web search for MCP browser tool (optional)" "HTTPS/443"
        vllmcpu -> docker "Executes sandboxed code via MCP tool (optional)" "Unix Socket"
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

workspace {
    model {
        // People
        developer = person "Developer / Data Scientist" "Builds and deploys LLM-powered applications using OGX APIs"
        securityEngineer = person "Security Engineer" "Reviews auth policies, ABAC rules, and network egress"
        platformAdmin = person "Platform Admin" "Deploys and configures OGX server with provider backends"

        // Main System
        ogx = softwareSystem "OGX (Llama Stack)" "Modular Python platform for serving LLM inference, agents, safety, evaluation, and tool execution via unified REST API" {
            server = container "Llama Stack Server" "Main API server exposing all LLM operations via REST on port 8321/TCP" "Python (FastAPI + Uvicorn)"
            authMiddleware = container "Authentication Middleware" "OAuth2 JWT validation, custom auth endpoint support, Bearer token extraction" "Python ASGI Middleware"
            quotaMiddleware = container "Quota Middleware" "Per-client rate limiting (100/day anon, 1000/day auth)" "Python ASGI Middleware"
            accessControl = container "Access Control Engine" "Cedar-inspired ABAC for resource-level authorization" "Python Policy Engine"
            routingEngine = container "Routing Engine" "Routes API requests to appropriate providers based on resource registration" "Python Middleware"
            providerFramework = container "Provider Framework" "Protocol-based abstraction for inline and remote providers" "Python Plugin System"
            cli = container "CLI (llama)" "Stack management, model download, server startup" "Python CLI (Fire)"
            streamlitUI = container "Streamlit UI" "Browser-based playground for Llama Stack APIs on port 8501/TCP" "Python (Streamlit)"
            telemetryAdapter = container "Telemetry Adapter" "OpenTelemetry integration with W3C context propagation" "Python Service"
        }

        // External Inference Providers
        openaiAPI = softwareSystem "OpenAI API" "Remote LLM inference provider" "External"
        anthropicAPI = softwareSystem "Anthropic API" "Remote LLM inference provider" "External"
        awsBedrock = softwareSystem "AWS Bedrock" "Remote inference and safety provider" "External"
        googleGemini = softwareSystem "Google Gemini" "Remote LLM inference provider" "External"
        nvidiaNIM = softwareSystem "NVIDIA NIM" "Remote inference, eval, and training provider" "External"
        ibmWatsonX = softwareSystem "IBM WatsonX" "Remote LLM inference provider" "External"
        otherLLMProviders = softwareSystem "Other LLM Providers" "Groq, Together, Fireworks, Cerebras, SambaNova, Databricks, RunPod" "External"

        // Local Inference Backends
        vllm = softwareSystem "vLLM" "High-throughput LLM serving engine" "Internal Platform"
        ollama = softwareSystem "Ollama" "Local LLM runtime (11434/TCP, no TLS)" "Internal Platform"
        tgi = softwareSystem "TGI" "Text Generation Inference server" "Internal Platform"

        // Data Storage
        postgresql = softwareSystem "PostgreSQL" "pgvector for vector storage, KV store backend (5432/TCP)" "External"
        redis = softwareSystem "Redis" "KV store backend for quota and metadata (6379/TCP)" "External"
        sqlite = softwareSystem "SQLite" "Default embedded KV store, vector store (sqlite-vec)" "External"

        // Vector Databases
        chroma = softwareSystem "Chroma" "Vector database provider" "External"
        milvus = softwareSystem "Milvus" "Vector database provider (19530/TCP gRPC)" "External"
        qdrant = softwareSystem "Qdrant" "Vector database provider (6333/TCP)" "External"
        weaviate = softwareSystem "Weaviate" "Vector database provider (8080/TCP)" "External"

        // Tool Services
        searchAPIs = softwareSystem "Search APIs" "Bing, Brave, Tavily search tool providers" "External"
        wolframAlpha = softwareSystem "Wolfram Alpha" "Computation tool runtime provider" "External"
        mcpServers = softwareSystem "MCP Servers" "Model Context Protocol tool execution endpoints" "External"

        // Infrastructure Services
        huggingFace = softwareSystem "Hugging Face Hub" "Model weight downloading and registry" "External"
        oauthProvider = softwareSystem "OAuth2/OIDC Provider" "JWKS key retrieval and token introspection" "External"
        otelCollector = softwareSystem "OTEL Collector" "Trace and metric export receiver" "External"

        // Relationships - People to System
        developer -> ogx "Creates inference requests, agents, evaluations via REST API" "HTTP/HTTPS 8321/TCP"
        developer -> streamlitUI "Interacts with playground" "HTTP 8501/TCP"
        platformAdmin -> cli "Manages stack, downloads models, starts server" "CLI"
        securityEngineer -> ogx "Configures auth policies, reviews ABAC rules"

        // Internal container relationships
        server -> authMiddleware "Processes requests through"
        authMiddleware -> quotaMiddleware "Forwards authenticated requests"
        quotaMiddleware -> accessControl "Forwards within-quota requests"
        accessControl -> routingEngine "Forwards authorized requests"
        routingEngine -> providerFramework "Delegates to appropriate provider"
        streamlitUI -> server "Calls API endpoints" "HTTP"
        server -> telemetryAdapter "Reports traces and metrics"

        // External inference egress
        providerFramework -> openaiAPI "Remote inference via remote::openai" "HTTPS/443"
        providerFramework -> anthropicAPI "Remote inference via remote::anthropic" "HTTPS/443"
        providerFramework -> awsBedrock "Remote inference via remote::bedrock" "HTTPS/443"
        providerFramework -> googleGemini "Remote inference via remote::gemini" "HTTPS/443"
        providerFramework -> nvidiaNIM "Remote inference via remote::nvidia" "HTTPS/443"
        providerFramework -> ibmWatsonX "Remote inference via remote::watsonx" "HTTPS/443"
        providerFramework -> otherLLMProviders "Remote inference" "HTTPS/443"

        // Local inference
        providerFramework -> vllm "Local/remote inference" "HTTP/HTTPS"
        providerFramework -> ollama "Local inference" "HTTP/11434"
        providerFramework -> tgi "Remote inference" "HTTP/HTTPS"

        // Storage
        providerFramework -> postgresql "Vector storage, KV store" "PostgreSQL/5432"
        quotaMiddleware -> redis "Quota tracking" "Redis/6379"
        providerFramework -> sqlite "Default storage" "Local file"

        // Vector DBs
        providerFramework -> chroma "Vector storage" "HTTP"
        providerFramework -> milvus "Vector storage" "gRPC/19530"
        providerFramework -> qdrant "Vector storage" "HTTP-gRPC/6333"
        providerFramework -> weaviate "Vector storage" "HTTP/8080"

        // Tools
        providerFramework -> searchAPIs "Search tool execution" "HTTPS/443"
        providerFramework -> wolframAlpha "Computation tool" "HTTPS/443"
        providerFramework -> mcpServers "MCP tool execution" "HTTP/HTTPS"

        // Infrastructure
        providerFramework -> huggingFace "Model weight download" "HTTPS/443"
        authMiddleware -> oauthProvider "JWKS key retrieval, token introspection" "HTTPS/443"
        telemetryAdapter -> otelCollector "Trace and metric export" "HTTP OTLP"
    }

    views {
        systemContext ogx "SystemContext" {
            include *
            autoLayout
        }

        container ogx "Containers" {
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
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

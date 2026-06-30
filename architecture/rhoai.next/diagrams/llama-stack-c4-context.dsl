workspace {
    model {
        # People
        datascientist = person "Data Scientist" "Creates and deploys AI applications using LLMs"
        appdev = person "Application Developer" "Builds AI-powered applications via APIs"
        securityengineer = person "Security Engineer" "Manages auth policies and security reviews"

        # Main System
        llamastack = softwareSystem "Llama Stack" "Modular AI application server providing standardized REST APIs for LLM inference, agents, RAG, safety, evaluation, and post-training" {
            server = container "Llama Stack Server" "Main API server exposing REST endpoints via dynamic route generation from Protocol classes" "Python FastAPI/uvicorn" "8321/TCP"
            middlewareChain = container "ASGI Middleware Chain" "ClientVersion → Authentication → Quota → Tracing pipeline" "Python ASGI"
            providerResolver = container "Provider Resolver" "Dynamically imports and wires provider plugins based on StackRunConfig" "Python"
            inlineProviders = container "Inline Providers" "In-process providers (FAISS, sentence-transformers, SQLite)" "Python"
            remoteProviders = container "Remote Providers" "HTTP adapter providers for external services (vLLM, OpenAI, pgvector)" "Python httpx/aiohttp"
            accessControl = container "Access Control (ABAC)" "Cedar-like policy engine with attribute-based rules" "Python"
            distributionTemplates = container "Distribution Templates" "Pre-configured provider combinations (remote-vllm, starter, ollama)" "YAML"
            cli = container "llama CLI" "Command-line tool for building, running, managing distributions" "Python"
        }

        # Internal Platform Dependencies
        vllm = softwareSystem "vLLM Model Serving" "Primary LLM inference backend for RHOAI deployments" "Internal RHOAI"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics collection" "Internal RHOAI"

        # External Dependencies - Inference
        openaiApi = softwareSystem "OpenAI API" "Remote LLM inference provider" "External"
        anthropicApi = softwareSystem "Anthropic API" "Remote LLM inference provider" "External"
        bedrockApi = softwareSystem "AWS Bedrock" "Remote LLM inference via AWS" "External"
        geminiApi = softwareSystem "Google Gemini" "Remote LLM inference provider" "External"
        ollama = softwareSystem "Ollama" "Alternative local LLM inference backend" "External"

        # External Dependencies - Storage
        postgresql = softwareSystem "PostgreSQL + pgvector" "Vector storage for RAG, KV store, SQL store" "External"
        redis = softwareSystem "Redis" "KV store for metadata, quota tracking, session state" "External"
        chromadb = softwareSystem "Chroma" "Vector database for RAG" "External"
        qdrant = softwareSystem "Qdrant" "Vector database for RAG" "External"

        # External Dependencies - Auth
        oauth2 = softwareSystem "OAuth2/OIDC Provider" "JWT token validation via JWKS or introspection" "External"

        # External Dependencies - Other
        huggingface = softwareSystem "HuggingFace Hub" "Model weight downloads and model registry" "External"
        searchApis = softwareSystem "Search APIs (Tavily/Brave)" "Web search tools for agent capabilities" "External"
        mcpServers = softwareSystem "MCP Servers" "External tool integration via Model Context Protocol" "External"

        # Relationships - Users
        datascientist -> llamastack "Creates inference requests, RAG queries, evaluations" "REST API / Bearer Token"
        appdev -> llamastack "Builds applications via OpenAI-compatible APIs" "REST API / Bearer Token"
        securityengineer -> llamastack "Configures ABAC policies and auth providers" "YAML config"

        # Relationships - Internal containers
        server -> middlewareChain "Processes requests through"
        middlewareChain -> accessControl "Enforces ABAC policies"
        server -> providerResolver "Resolves provider implementations"
        providerResolver -> inlineProviders "Routes to in-process providers"
        providerResolver -> remoteProviders "Routes to external providers"
        distributionTemplates -> providerResolver "Configures provider mappings" "YAML"
        cli -> server "Manages and controls" "CLI"

        # Relationships - Internal platform
        remoteProviders -> vllm "LLM inference (completions, chat, embeddings)" "HTTP/HTTPS 8000/TCP, OpenAI-compatible"
        server -> otel "Exports traces and metrics" "HTTP OTLP"

        # Relationships - External inference
        remoteProviders -> openaiApi "Remote inference" "HTTPS/443 TLS 1.2+, API Key"
        remoteProviders -> anthropicApi "Remote inference" "HTTPS/443 TLS 1.2+, API Key"
        remoteProviders -> bedrockApi "Remote inference" "HTTPS/443 TLS 1.2+ SigV4, AWS IAM"
        remoteProviders -> geminiApi "Remote inference" "HTTPS/443 TLS 1.2+, API Key"
        remoteProviders -> ollama "Local inference" "HTTP/11434"

        # Relationships - Storage
        remoteProviders -> postgresql "Vector storage, metadata, state" "PostgreSQL/5432, Password"
        remoteProviders -> redis "KV store, quota tracking" "Redis/6379, Optional password"
        remoteProviders -> chromadb "Vector storage" "HTTP/8000"
        remoteProviders -> qdrant "Vector storage" "HTTP-gRPC/6333"

        # Relationships - Auth
        middlewareChain -> oauth2 "JWT validation (JWKS/introspection)" "HTTPS/443 TLS 1.2+"

        # Relationships - Other
        server -> huggingface "Model downloads" "HTTPS/443 TLS 1.2+, Bearer Token"
        remoteProviders -> searchApis "Web search for agents" "HTTPS/443 TLS 1.2+, API Key"
        remoteProviders -> mcpServers "External tool integration" "HTTP/HTTPS"
    }

    views {
        systemContext llamastack "SystemContext" {
            include *
            autoLayout
        }

        container llamastack "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape person
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

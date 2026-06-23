workspace {
    model {
        datascientist = person "Data Scientist" "Builds and deploys AI applications using Llama Stack APIs"
        developer = person "Application Developer" "Integrates AI capabilities via OpenAI-compatible API"
        securityEngineer = person "Security Engineer" "Configures auth policies and monitors access"

        ogx = softwareSystem "ogx (Llama Stack)" "Pluggable AI/LLM application framework providing unified REST API for inference, agents, safety, evaluation, and tool orchestration" {
            server = container "Llama Stack Server" "Main HTTP server exposing 76 endpoints across 19 API modules with auth, routing, tracing, streaming" "Python FastAPI/Uvicorn" "Port 8321/TCP"
            authMiddleware = container "AuthenticationMiddleware" "Validates Bearer tokens via OAuth2 JWKS/introspection or custom endpoints; maps claims to ABAC attributes" "Python ASGI Middleware"
            abacEngine = container "ABAC Policy Engine" "Cedar-like attribute-based access control with permit/forbid rules, owner-based and wildcard resource matching" "Python Module"
            quotaMiddleware = container "QuotaMiddleware" "Per-client rate limiting with separate authenticated and anonymous quotas" "Python ASGI Middleware"
            routingLayer = container "Routing Layer" "Auto-routes requests to providers based on registered resources (model→inference, shield→safety)" "Python Framework"
            providerSystem = container "Provider System" "Pluggable provider architecture with inline (in-process) and remote (proxy) implementations" "Python Framework"
            distributionSystem = container "Distribution System" "Template-based configuration and build system; 24 built-in templates for provider composition" "Python Framework"
            cli = container "CLI (llama)" "Command-line tool for building, running, and managing Llama Stack distributions" "Python CLI"
            streamlitUI = container "Streamlit Playground UI" "Optional management and playground UI" "Python Streamlit" "Port 8501/TCP"
        }

        # Inference Providers
        vllm = softwareSystem "vLLM" "Primary inference backend for RHOAI deployments" "External - Inference"
        ollama = softwareSystem "Ollama" "Local model inference backend" "External - Inference"
        openaiAPI = softwareSystem "OpenAI API" "Cloud inference provider" "External - Cloud"
        anthropicAPI = softwareSystem "Anthropic API" "Cloud inference provider" "External - Cloud"
        bedrock = softwareSystem "AWS Bedrock" "Cloud inference and safety provider" "External - Cloud"
        tgi = softwareSystem "HuggingFace TGI" "Text generation inference server" "External - Inference"

        # Vector Databases
        chromadb = softwareSystem "ChromaDB" "Vector database backend" "External - Storage"
        pgvector = softwareSystem "PostgreSQL (pgvector)" "Vector database with PostgreSQL" "External - Storage"
        qdrant = softwareSystem "Qdrant" "Vector database backend" "External - Storage"
        milvus = softwareSystem "Milvus" "Vector database backend" "External - Storage"

        # Auth & Identity
        oauth2Provider = softwareSystem "OAuth2/OIDC Provider" "Token validation via JWKS and introspection (RFC 7662)" "External - Security"

        # Tool Runtimes
        braveSearch = softwareSystem "Brave Search API" "Web search tool runtime" "External - Tool"
        tavilySearch = softwareSystem "Tavily Search API" "Web search tool runtime" "External - Tool"
        mcpServers = softwareSystem "MCP Servers" "Model Context Protocol tool integration" "External - Tool"

        # Observability
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics export" "External - Observability"

        # Model Downloads
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and dataset downloads" "External - Cloud"

        # Relationships - Users
        datascientist -> ogx "Creates inference requests, agents, and evaluations via REST API" "HTTP/HTTPS :8321"
        developer -> ogx "Uses OpenAI-compatible endpoints for inference" "HTTP/HTTPS :8321"
        securityEngineer -> ogx "Configures ABAC policies and auth settings" "YAML config"

        # Relationships - Internal
        server -> authMiddleware "Validates every request"
        authMiddleware -> abacEngine "Checks access policies with user attributes"
        authMiddleware -> quotaMiddleware "Rate limits after auth"
        server -> routingLayer "Dispatches to routers"
        routingLayer -> providerSystem "Routes to inline or remote providers"
        cli -> distributionSystem "Builds and launches distributions"
        distributionSystem -> server "Configures and starts server"
        streamlitUI -> server "UI calls via HTTP"

        # Relationships - External (Inference)
        ogx -> vllm "Model inference" "HTTP/HTTPS, Bearer Token"
        ogx -> ollama "Model inference" "HTTP :11434"
        ogx -> openaiAPI "Cloud inference" "HTTPS :443, API Key"
        ogx -> anthropicAPI "Cloud inference" "HTTPS :443, API Key"
        ogx -> bedrock "Cloud inference & safety" "HTTPS :443, IAM"
        ogx -> tgi "Text generation" "HTTP/HTTPS"

        # Relationships - External (Storage)
        ogx -> chromadb "Vector storage" "HTTP/HTTPS"
        ogx -> pgvector "Vector storage" "PostgreSQL :5432"
        ogx -> qdrant "Vector storage" "HTTP/HTTPS, API Key"
        ogx -> milvus "Vector storage" "gRPC/HTTP"

        # Relationships - External (Auth)
        ogx -> oauth2Provider "JWT validation via JWKS and token introspection" "HTTPS, TLS 1.2+"

        # Relationships - External (Tools)
        ogx -> braveSearch "Web search tool" "HTTPS :443, API Key"
        ogx -> tavilySearch "Web search tool" "HTTPS :443, API Key"
        ogx -> mcpServers "Tool integration" "HTTP/stdio"

        # Relationships - External (Observability)
        ogx -> otelCollector "Export traces and metrics" "HTTP OTLP"

        # Relationships - External (Downloads)
        ogx -> huggingfaceHub "Download models and datasets" "HTTPS :443, Bearer Token"
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
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External - Inference" {
                background #999999
                color #ffffff
            }
            element "External - Cloud" {
                background #666666
                color #ffffff
            }
            element "External - Storage" {
                background #7B5EA7
                color #ffffff
            }
            element "External - Security" {
                background #CC0000
                color #ffffff
            }
            element "External - Tool" {
                background #D4762C
                color #ffffff
            }
            element "External - Observability" {
                background #2D882D
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

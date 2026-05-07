workspace {
    model {
        developer = person "AI Developer" "Builds AI applications using Llama Stack APIs"
        datascientist = person "Data Scientist" "Deploys and evaluates ML models"
        operator = person "Platform Operator" "Configures and manages Llama Stack distributions"

        llamaStack = softwareSystem "Llama Stack" "Standardized API server for building and deploying generative AI applications with pluggable provider backends" {
            server = container "Llama Stack Server" "HTTP API server exposing unified AI/ML APIs" "Python FastAPI/Uvicorn, Port 8321"
            authMiddleware = container "Authentication Middleware" "OAuth2 JWT and Custom auth with Cedar-inspired ABAC" "ASGI Middleware"
            distributionSystem = container "Distribution System" "Composes provider configurations into deployable stacks" "Python Framework"
            providerRegistry = container "Provider Registry" "Registry of inline and remote provider implementations" "Python Module"
            accessControl = container "Access Control Engine" "Cedar-inspired attribute-based access control for API resources" "Python Module"
            cli = container "Llama CLI" "Command-line interface for building, configuring, and running distributions" "Python CLI"
            ui = container "Llama Stack UI" "Web-based log viewer and playground for chat completions" "TypeScript Next.js"
        }

        vllm = softwareSystem "vLLM" "LLM inference backend (OpenAI-compatible API)" "Internal RHOAI"
        ollama = softwareSystem "Ollama" "Local LLM inference backend" "External"
        openai = softwareSystem "OpenAI API" "Remote inference provider" "External Cloud"
        anthropic = softwareSystem "Anthropic API" "Remote inference provider" "External Cloud"
        bedrock = softwareSystem "AWS Bedrock" "Remote inference and safety provider" "External Cloud"
        nvidia = softwareSystem "NVIDIA NIM" "Remote inference, eval, and post-training" "External Cloud"
        huggingface = softwareSystem "HuggingFace Hub" "Dataset loading and model download" "External Cloud"

        pgvector = softwareSystem "PostgreSQL/pgvector" "Vector storage for RAG" "Internal/External"
        chromadb = softwareSystem "ChromaDB" "Vector storage for RAG" "Internal/External"
        qdrant = softwareSystem "Qdrant" "Vector storage for RAG" "Internal/External"
        redis = softwareSystem "Redis" "KV store backend" "Internal/External"
        mongodb = softwareSystem "MongoDB" "KV store backend" "Internal/External"
        sqlite = softwareSystem "SQLite" "Default persistence (registry, agents, traces)" "Embedded"

        oidcProvider = softwareSystem "OIDC Provider" "JWT public key retrieval (Keycloak, etc.)" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing export" "Internal RHOAI"
        braveSearch = softwareSystem "Brave Search" "Web search tool for agents" "External Cloud"
        tavilySearch = softwareSystem "Tavily Search" "Web search tool for agents" "External Cloud"
        wolframAlpha = softwareSystem "Wolfram Alpha" "Computation tool for agents" "External Cloud"
        mcpServers = softwareSystem "MCP Servers" "External tool integration via Model Context Protocol" "External"

        # User relationships
        developer -> llamaStack "Builds AI apps via REST API" "HTTPS/8321"
        datascientist -> llamaStack "Deploys/evaluates models via API" "HTTPS/8321"
        operator -> llamaStack "Configures distributions via CLI" "CLI"

        # Internal container relationships
        server -> authMiddleware "Authenticates requests"
        authMiddleware -> accessControl "Evaluates ABAC policies"
        server -> distributionSystem "Routes to providers"
        distributionSystem -> providerRegistry "Resolves providers"
        ui -> server "REST API calls" "HTTPS/8321"
        cli -> distributionSystem "Manages distributions"

        # Inference provider relationships
        llamaStack -> vllm "LLM inference (primary RHOAI backend)" "HTTP/HTTPS 8000"
        llamaStack -> ollama "Local LLM inference" "HTTP/11434"
        llamaStack -> openai "Remote inference" "HTTPS/443"
        llamaStack -> anthropic "Remote inference" "HTTPS/443"
        llamaStack -> bedrock "Remote inference/safety" "HTTPS/443"
        llamaStack -> nvidia "Remote inference/eval" "HTTPS/443"

        # Data store relationships
        llamaStack -> pgvector "Vector storage for RAG" "PostgreSQL/5432"
        llamaStack -> chromadb "Vector storage for RAG" "HTTP/HTTPS"
        llamaStack -> qdrant "Vector storage for RAG" "HTTP/gRPC"
        llamaStack -> redis "KV store" "Redis/6379"
        llamaStack -> mongodb "KV store" "MongoDB/27017"
        llamaStack -> sqlite "Default persistence" "File I/O"

        # Auth and observability
        llamaStack -> oidcProvider "JWT validation (JWKS)" "HTTPS/443"
        llamaStack -> otelCollector "Telemetry export" "HTTP OTLP"
        llamaStack -> huggingface "Dataset/model downloads" "HTTPS/443"

        # Tool relationships
        llamaStack -> braveSearch "Web search tool" "HTTPS/443"
        llamaStack -> tavilySearch "Web search tool" "HTTPS/443"
        llamaStack -> wolframAlpha "Computation tool" "HTTPS/443"
        llamaStack -> mcpServers "External tool integration" "HTTP/HTTPS SSE"
    }

    views {
        systemContext llamaStack "SystemContext" {
            include *
            autoLayout
        }

        container llamaStack "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Cloud" {
                background #e67e22
                color #ffffff
            }
            element "Internal/External" {
                background #3498db
                color #ffffff
            }
            element "Embedded" {
                background #95a5a6
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

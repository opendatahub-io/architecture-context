workspace {
    model {
        datascientist = person "Data Scientist / Developer" "Builds AI applications using Llama Stack APIs"
        platformOp = person "Platform Operator" "Deploys and configures Llama Stack distributions"

        llamaStack = softwareSystem "Llama Stack" "Standardized API server for building and deploying generative AI applications with pluggable provider backends" {
            server = container "Llama Stack Server" "HTTP API server exposing unified AI/ML APIs (inference, agents, safety, RAG, eval, tools)" "Python FastAPI/Uvicorn" "Service"
            authMiddleware = container "Authentication Middleware" "Validates OAuth2 JWT tokens or delegates to custom auth endpoints" "ASGI Middleware"
            accessControl = container "Access Control Engine" "Cedar-inspired ABAC policy evaluation (permit/forbid rules)" "Python Module"
            quotaMiddleware = container "Quota Middleware" "Per-client rate limiting (1000/day auth, 100/day anon)" "ASGI Middleware"
            distributionSystem = container "Distribution System" "Composes provider configurations into deployable stacks via YAML templates" "Python Module"
            providerRegistry = container "Provider Registry" "Registry of inline (in-process) and remote (HTTP adapter) provider implementations" "Python Module"
            cli = container "CLI (llama)" "Command-line interface for building, configuring, and running distributions" "Python CLI"
            ui = container "Llama Stack UI" "Web-based log viewer and chat playground" "TypeScript Next.js"
        }

        vllm = softwareSystem "vLLM" "High-performance LLM inference server (primary RHOAI backend)" "Internal RHOAI"
        ollama = softwareSystem "Ollama" "Local LLM inference server" "External"

        openai = softwareSystem "OpenAI API" "Cloud LLM inference provider" "External Cloud"
        anthropic = softwareSystem "Anthropic API" "Cloud LLM inference provider" "External Cloud"
        bedrock = softwareSystem "AWS Bedrock" "Cloud LLM inference and safety provider" "External Cloud"
        nvidiaNim = softwareSystem "NVIDIA NIM" "Cloud inference, eval, and post-training" "External Cloud"

        pgvector = softwareSystem "PostgreSQL/pgvector" "Vector database for RAG" "Internal"
        chromadb = softwareSystem "ChromaDB" "Vector database for RAG" "External"
        qdrant = softwareSystem "Qdrant" "Vector database for RAG" "External"

        redis = softwareSystem "Redis" "KV store backend" "External"
        mongodb = softwareSystem "MongoDB" "KV store backend" "External"
        sqlite = softwareSystem "SQLite" "Default local persistence" "Internal"

        oidcProvider = softwareSystem "OIDC Provider" "Identity provider (Keycloak, etc.) for JWT validation" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend" "Internal"
        hfHub = softwareSystem "HuggingFace Hub" "Model and dataset registry" "External"
        braveSearch = softwareSystem "Brave Search" "Web search tool for agents" "External"

        # User interactions
        datascientist -> llamaStack "Sends inference, agent, and safety requests via REST API" "HTTPS/8321"
        platformOp -> llamaStack "Configures distributions and deploys stacks" "CLI / YAML"
        ui -> server "Provides chat playground and log viewing" "HTTP/8321"

        # Server internal flows
        server -> authMiddleware "Validates incoming requests"
        authMiddleware -> accessControl "Evaluates ABAC policies"
        accessControl -> quotaMiddleware "Checks rate limits"
        distributionSystem -> providerRegistry "Configures providers at startup"
        cli -> server "Builds, configures, and launches server"

        # External dependencies
        llamaStack -> vllm "LLM inference requests" "HTTP/HTTPS 8000/TCP"
        llamaStack -> ollama "Local LLM inference" "HTTP 11434/TCP"
        llamaStack -> openai "Remote inference" "HTTPS/443"
        llamaStack -> anthropic "Remote inference" "HTTPS/443"
        llamaStack -> bedrock "Remote inference/safety" "HTTPS/443"
        llamaStack -> nvidiaNim "Remote inference/eval" "HTTPS/443"

        llamaStack -> pgvector "Vector storage for RAG" "PostgreSQL/5432"
        llamaStack -> chromadb "Vector storage for RAG" "HTTP/HTTPS"
        llamaStack -> qdrant "Vector storage for RAG" "HTTP/gRPC"
        llamaStack -> redis "KV store backend" "Redis/6379"
        llamaStack -> mongodb "KV store backend" "MongoDB/27017"
        llamaStack -> sqlite "Default persistence" "File I/O"

        llamaStack -> oidcProvider "JWT public key retrieval" "HTTPS/443"
        llamaStack -> otelCollector "Trace span export" "OTLP HTTP"
        llamaStack -> hfHub "Model/dataset downloads" "HTTPS/443"
        llamaStack -> braveSearch "Web search for agents" "HTTPS/443"
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
            element "External Cloud" {
                background #775599
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Service" {
                shape hexagon
            }
        }
    }
}

workspace {
    model {
        datascientist = person "Data Scientist" "Builds AI applications using Llama Stack APIs"
        appdev = person "Application Developer" "Integrates Llama Stack into applications via OpenAI-compatible API"
        platformadmin = person "Platform Admin" "Configures and deploys Llama Stack distributions"

        llamastack = softwareSystem "Llama Stack" "Standardized API server for generative AI applications with pluggable providers" {
            server = container "Llama Stack Server" "FastAPI/Uvicorn HTTP API server exposing unified AI/ML APIs" "Python Service (FastAPI)" {
                authMiddleware = component "AuthenticationMiddleware" "OAuth2 JWT / Custom token validation" "ASGI Middleware"
                quotaMiddleware = component "QuotaMiddleware" "Per-client rate limiting (1000/100 req/day)" "ASGI Middleware"
                accessControl = component "AccessControlMiddleware" "Cedar-inspired ABAC policy evaluation" "ASGI Middleware"
                tracingMiddleware = component "TracingMiddleware" "W3C Trace Context / OpenTelemetry" "ASGI Middleware"
                inferenceRouter = component "InferenceRouter" "Routes inference requests to configured providers" "Python Module"
                safetyRouter = component "SafetyRouter" "Routes safety checks to shield providers" "Python Module"
                agentProvider = component "Agent Provider" "Orchestrates multi-turn agent conversations with tool use" "Python Module"
                vectorRouter = component "VectorIORouter" "Routes vector operations to DB providers" "Python Module"
            }
            distSystem = container "Distribution System" "Composes provider configurations into deployable stacks via YAML configs" "Python Framework"
            providerRegistry = container "Provider Registry" "Registry of inline and remote provider implementations" "Python Module"
            accessControlEngine = container "Access Control Engine" "Cedar-inspired attribute-based access control for API resources" "Python Module"
            cli = container "CLI (llama)" "Build, configure, and run Llama Stack distributions" "Python CLI"
            ui = container "Llama Stack UI" "Web-based log viewer and playground for chat completions" "TypeScript/Next.js"
            sqlite = container "SQLite" "Default persistence for registry, agents, traces, quotas" "Embedded Database"
        }

        # Inference Providers
        vllm = softwareSystem "vLLM" "Primary LLM inference backend for RHOAI" "Internal RHOAI"
        ollama = softwareSystem "Ollama" "Local LLM inference backend" "External"
        openai = softwareSystem "OpenAI API" "Remote inference provider" "External Cloud"
        anthropic = softwareSystem "Anthropic API" "Remote inference provider" "External Cloud"
        bedrock = softwareSystem "AWS Bedrock" "Remote inference and safety provider" "External Cloud"
        nim = softwareSystem "NVIDIA NIM" "Remote inference, eval, and post-training" "External Cloud"

        # Vector DBs
        pgvector = softwareSystem "PostgreSQL/pgvector" "Vector storage for RAG" "External"
        chromadb = softwareSystem "ChromaDB" "Vector storage for RAG" "External"
        qdrant = softwareSystem "Qdrant" "Vector storage for RAG" "External"

        # KV Stores
        redis = softwareSystem "Redis" "KV store backend option" "External"
        mongodb = softwareSystem "MongoDB" "KV store backend option" "External"

        # Tool Providers
        bravesearch = softwareSystem "Brave Search" "Web search tool for agents" "External Cloud"
        tavily = softwareSystem "Tavily Search" "Web search tool for agents" "External Cloud"
        wolfram = softwareSystem "Wolfram Alpha" "Computation tool for agents" "External Cloud"
        mcpservers = softwareSystem "MCP Servers" "External tool integration via Model Context Protocol" "External"

        # Auth
        oidcprovider = softwareSystem "OIDC Provider" "JWT public key retrieval (Keycloak, etc.)" "External"

        # Telemetry
        otelcollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing export" "External"
        hfhub = softwareSystem "HuggingFace Hub" "Dataset/model downloads" "External Cloud"

        # Relationships - Users
        datascientist -> llamastack "Creates agents, runs inference, evaluates models" "REST API / 8321/TCP"
        appdev -> llamastack "Integrates via OpenAI-compatible API" "REST API / 8321/TCP"
        platformadmin -> cli "Configures and deploys distributions" "CLI"
        datascientist -> ui "Monitors logs, tests chat completions" "HTTPS"

        # Relationships - Internal
        ui -> server "Sends API requests" "HTTP/HTTPS / 8321"
        cli -> distSystem "Manages distribution configs" "In-process"
        distSystem -> providerRegistry "Resolves provider implementations" "In-process"
        server -> accessControlEngine "Evaluates access policies" "In-process"
        server -> sqlite "Persists state" "File I/O"

        # Relationships - Inference
        llamastack -> vllm "LLM inference requests" "HTTP/HTTPS / 8000"
        llamastack -> ollama "Local LLM inference" "HTTP / 11434"
        llamastack -> openai "Remote inference" "HTTPS / 443"
        llamastack -> anthropic "Remote inference" "HTTPS / 443"
        llamastack -> bedrock "Remote inference & safety" "HTTPS / 443"
        llamastack -> nim "Remote inference, eval" "HTTPS / 443"

        # Relationships - Vector DBs
        llamastack -> pgvector "Vector storage for RAG" "PostgreSQL / 5432"
        llamastack -> chromadb "Vector storage for RAG" "HTTP/HTTPS"
        llamastack -> qdrant "Vector storage for RAG" "HTTP/gRPC"

        # Relationships - KV Stores
        llamastack -> redis "KV store backend" "Redis / 6379"
        llamastack -> mongodb "KV store backend" "MongoDB / 27017"

        # Relationships - Tools
        llamastack -> bravesearch "Web search for agents" "HTTPS / 443"
        llamastack -> tavily "Web search for agents" "HTTPS / 443"
        llamastack -> wolfram "Computation for agents" "HTTPS / 443"
        llamastack -> mcpservers "External tool integration" "REST/SSE"

        # Relationships - Auth
        llamastack -> oidcprovider "JWT public key retrieval" "HTTPS / 443"

        # Relationships - Telemetry
        llamastack -> otelcollector "Exports traces" "OTLP HTTP"
        llamastack -> hfhub "Downloads datasets/models" "HTTPS / 443"
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

        component server "Components" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Cloud" {
                background #777777
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Embedded Database" {
                shape Cylinder
                background #f5a623
                color #ffffff
            }
        }
    }
}

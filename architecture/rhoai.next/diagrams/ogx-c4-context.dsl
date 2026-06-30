workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models, runs inference, evaluates models"
        developer = person "Application Developer" "Integrates Llama Stack APIs into applications"

        llamastack = softwareSystem "Llama Stack (ogx)" "Extensible AI/ML platform server providing unified APIs for inference, agents, safety, vector I/O, evaluation, and related AI capabilities through a pluggable provider architecture" {
            server = container "FastAPI Server" "HTTP API server exposing 18 AI/ML APIs with dynamic route registration and middleware stack" "Python FastAPI/uvicorn, Port 8321/TCP"
            providerFramework = container "Provider Framework" "Pluggable provider architecture with dependency injection and topological sort resolution" "Python"
            inlineProviders = container "Inline Providers (19)" "In-process provider implementations for meta-reference, FAISS, SQLite, etc." "Python"
            remoteProviders = container "Remote Providers (41)" "External service adapters for vLLM, OpenAI, Anthropic, Bedrock, etc." "Python"
            distributionSystem = container "Distribution System" "Template-based distribution composition with 25 pre-configured stacks" "Python/YAML"
            accessControl = container "Access Control" "ABAC engine with Cedar-like policy language for resource authorization" "Python"
            authMiddleware = container "Auth Middleware" "OAuth2 JWT / Custom token validation with claim-to-attribute mapping" "Python"
            libraryClient = container "Library Client" "Direct in-process API access without HTTP server" "Python"
            cli = container "CLI (llama)" "Command-line tool for stack management, build, run, configure" "Python argparse"
            uiDashboard = container "UI Dashboard" "Optional web UI for stack management and interaction" "Next.js"
        }

        // Inference Providers
        vllm = softwareSystem "vLLM" "High-performance LLM inference server" "External - Primary RHOAI backend"
        ollama = softwareSystem "Ollama" "Local LLM inference server" "External"
        openai = softwareSystem "OpenAI API" "Cloud LLM inference" "External Cloud"
        anthropic = softwareSystem "Anthropic API" "Cloud LLM inference (via litellm)" "External Cloud"
        gemini = softwareSystem "Google Gemini" "Cloud LLM inference (via litellm)" "External Cloud"
        bedrock = softwareSystem "AWS Bedrock" "Cloud inference and safety" "External Cloud"
        nvidia = softwareSystem "NVIDIA NIM" "NVIDIA inference endpoints" "External Cloud"
        databricks = softwareSystem "Databricks" "Model serving platform" "External Cloud"

        // Vector Databases
        pgvector = softwareSystem "PostgreSQL (pgvector)" "Vector storage and metadata persistence" "External"
        chroma = softwareSystem "Chroma" "Vector database for RAG" "External"
        qdrant = softwareSystem "Qdrant" "Vector database for RAG" "External"
        milvus = softwareSystem "Milvus" "Vector database for RAG" "External"
        weaviate = softwareSystem "Weaviate" "Vector database for RAG" "External"

        // Data Stores
        redis = softwareSystem "Redis" "KV store for session persistence and caching" "External"
        mongodb = softwareSystem "MongoDB" "KV store backend" "External"

        // Services
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset downloads" "External Cloud"
        oidcProvider = softwareSystem "OIDC Provider" "JWT validation and token introspection" "External"
        searchApis = softwareSystem "Search APIs" "Brave, Tavily, Bing search for agent tools" "External Cloud"
        wolframAlpha = softwareSystem "Wolfram Alpha" "Computation tool for agents" "External Cloud"
        mcpServers = softwareSystem "MCP Servers" "Model Context Protocol tool execution" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Telemetry and trace export" "External"

        // Relationships - Users
        datascientist -> llamastack "Creates inference requests, deploys agents, evaluates models" "HTTP REST/SSE, Port 8321"
        developer -> llamastack "Integrates AI capabilities via API" "HTTP REST/SSE or Python Library Client"

        // Internal Container Relationships
        server -> authMiddleware "Validates requests"
        authMiddleware -> accessControl "Checks ABAC policies"
        server -> providerFramework "Routes API calls"
        providerFramework -> inlineProviders "Resolves inline providers"
        providerFramework -> remoteProviders "Resolves remote providers"
        distributionSystem -> server "Configures run.yaml"
        cli -> distributionSystem "Manages templates"
        libraryClient -> providerFramework "Direct Python API calls"

        // External Relationships - Inference
        remoteProviders -> vllm "Inference requests" "HTTP(S), Port 8000"
        remoteProviders -> ollama "Inference requests" "HTTP, Port 11434"
        remoteProviders -> openai "Inference requests" "HTTPS/443, API key"
        remoteProviders -> anthropic "Inference requests" "HTTPS/443, API key"
        remoteProviders -> gemini "Inference requests" "HTTPS/443, API key"
        remoteProviders -> bedrock "Inference and safety" "HTTPS/443, AWS IAM"
        remoteProviders -> nvidia "Inference requests" "HTTPS/443, API key"
        remoteProviders -> databricks "Model serving" "HTTPS/443, Bearer token"

        // External Relationships - Vector DBs
        remoteProviders -> pgvector "Vector operations" "PostgreSQL/5432, Password"
        remoteProviders -> chroma "Vector operations" "HTTP(S)"
        remoteProviders -> qdrant "Vector operations" "HTTP/gRPC, API key"
        remoteProviders -> milvus "Vector operations" "gRPC"
        remoteProviders -> weaviate "Vector operations" "HTTP(S), API key"

        // External Relationships - Data Stores
        remoteProviders -> redis "Session/cache storage" "Redis/6379, Password"
        remoteProviders -> mongodb "KV storage" "MongoDB/27017, Password"

        // External Relationships - Services
        remoteProviders -> huggingface "Model/dataset downloads" "HTTPS/443, HF Token"
        authMiddleware -> oidcProvider "JWT validation / Token introspection" "HTTPS/443"
        remoteProviders -> searchApis "Web search for agents" "HTTPS/443, API keys"
        remoteProviders -> wolframAlpha "Computation tool" "HTTPS/443, API key"
        remoteProviders -> mcpServers "Tool execution" "HTTP(S), Configurable"
        server -> otelCollector "Telemetry export" "HTTP OTLP"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Cloud" {
                background #6366f1
                color #ffffff
            }
            element "External - Primary RHOAI backend" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

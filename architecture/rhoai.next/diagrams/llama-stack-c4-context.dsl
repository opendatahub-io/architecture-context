workspace {
    model {
        # Personas
        datascientist = person "Data Scientist" "Builds and deploys AI applications using LLMs"
        developer = person "Application Developer" "Integrates LLM capabilities into applications via REST APIs"
        securityEngineer = person "Security Engineer" "Manages authentication policies, ABAC rules, and access control"

        # Core System
        llamaStack = softwareSystem "Llama Stack" "Modular AI application server providing standardized REST APIs for LLM inference, agents, RAG, safety, evaluation, and post-training" {
            server = container "Llama Stack Server" "Main API server exposing REST endpoints on port 8321/TCP" "Python (FastAPI/uvicorn)"
            middlewareChain = container "ASGI Middleware Chain" "Authentication (JWT/JWKS, introspection), quota/rate-limiting, tracing" "Python ASGI"
            providerResolver = container "Provider Resolver" "Dynamic import and dependency injection for inline/remote providers" "Python"
            abacEngine = container "ABAC Engine" "Attribute-based access control with Cedar-like policy rules" "Python"
            inlineProviders = container "Inline Providers" "In-process providers: vLLM local, FAISS, sentence-transformers, SQLite-vec" "Python"
            remoteProviders = container "Remote Providers" "HTTP adapter providers for external services" "Python (httpx/openai SDK)"
            distributionTemplates = container "Distribution Templates" "Pre-configured provider combinations (remote-vllm, starter, ollama)" "YAML Configuration"
            llamaCLI = container "llama CLI" "Command-line tool for building, running, and managing distributions" "Python CLI"
        }

        # Inference Backends
        vllm = softwareSystem "vLLM Model Serving" "Primary LLM inference backend for RHOAI (OpenAI-compatible API)" "External - Internal Platform"
        ollama = softwareSystem "Ollama" "Alternative local LLM inference backend" "External - Internal Platform"
        openai = softwareSystem "OpenAI API" "Remote LLM inference provider" "External - Cloud"
        anthropic = softwareSystem "Anthropic API" "Remote LLM inference provider" "External - Cloud"
        bedrock = softwareSystem "AWS Bedrock" "Remote LLM inference provider (SigV4)" "External - Cloud"
        gemini = softwareSystem "Google Gemini" "Remote LLM inference provider" "External - Cloud"
        nvidia = softwareSystem "NVIDIA NIM" "Remote LLM inference provider" "External - Cloud"

        # Data Stores
        postgresql = softwareSystem "PostgreSQL + pgvector" "Vector storage for RAG, KV store, SQL store for inference state" "External - Internal Platform"
        redis = softwareSystem "Redis" "KV store for metadata, quota tracking, session state" "External - Internal Platform"
        mongodb = softwareSystem "MongoDB" "Alternative KV store backend" "External - Internal Platform"
        chromadb = softwareSystem "ChromaDB" "Vector database for RAG retrieval" "External - Internal Platform"
        qdrant = softwareSystem "Qdrant" "Vector database (HTTP/gRPC)" "External - Internal Platform"
        milvus = softwareSystem "Milvus" "Vector database (gRPC)" "External - Internal Platform"
        weaviate = softwareSystem "Weaviate" "Vector database (GraphQL)" "External - Internal Platform"

        # Auth & Identity
        oauth2 = softwareSystem "OAuth2/OIDC Provider" "JWT validation via JWKS and token introspection (RFC 7662)" "External"

        # Tools & Services
        tavilySearch = softwareSystem "Tavily Search" "Web search tool for agents" "External - Cloud"
        braveSearch = softwareSystem "Brave Search" "Web search tool for agents" "External - Cloud"
        huggingface = softwareSystem "HuggingFace Hub" "Model weight downloads" "External - Cloud"
        mcpServers = softwareSystem "MCP Servers" "External tool integration via Model Context Protocol" "External"

        # Observability
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics export (OTLP)" "External - Internal Platform"

        # Relationships - Users
        datascientist -> llamaStack "Creates inference requests, configures agents, runs evaluations" "REST API / 8321/TCP"
        developer -> llamaStack "Integrates via OpenAI-compatible API" "REST API / 8321/TCP"
        securityEngineer -> llamaStack "Manages ABAC policies and authentication config" "YAML Configuration"

        # Relationships - Internal
        server -> middlewareChain "Processes requests through"
        middlewareChain -> abacEngine "Evaluates access policies"
        server -> providerResolver "Routes API calls to providers"
        providerResolver -> inlineProviders "Dispatches to in-process"
        providerResolver -> remoteProviders "Dispatches to remote"
        distributionTemplates -> providerResolver "Configures provider mapping"
        llamaCLI -> server "Manages and controls"

        # Relationships - Inference Backends
        llamaStack -> vllm "LLM inference (completions, chat, embeddings)" "HTTP/HTTPS 8000/TCP"
        llamaStack -> ollama "LLM inference (alternative)" "HTTP 11434/TCP"
        llamaStack -> openai "Remote inference" "HTTPS/443"
        llamaStack -> anthropic "Remote inference" "HTTPS/443"
        llamaStack -> bedrock "Remote inference" "HTTPS/443 SigV4"
        llamaStack -> gemini "Remote inference" "HTTPS/443"
        llamaStack -> nvidia "Remote inference" "HTTPS/443"

        # Relationships - Data Stores
        llamaStack -> postgresql "Vector storage, KV store, SQL store" "PostgreSQL/5432"
        llamaStack -> redis "KV store, quota tracking" "Redis/6379"
        llamaStack -> mongodb "Alternative KV store" "MongoDB/27017"
        llamaStack -> chromadb "Vector database" "HTTP/8000"
        llamaStack -> qdrant "Vector database" "HTTP-gRPC/6333"
        llamaStack -> milvus "Vector database" "gRPC/19530"
        llamaStack -> weaviate "Vector database" "HTTP/8080"

        # Relationships - Auth
        llamaStack -> oauth2 "JWT validation, token introspection" "HTTPS/443"

        # Relationships - Tools
        llamaStack -> tavilySearch "Web search for agents" "HTTPS/443"
        llamaStack -> braveSearch "Web search for agents" "HTTPS/443"
        llamaStack -> huggingface "Model downloads" "HTTPS/443"
        llamaStack -> mcpServers "Tool integration" "HTTP/HTTPS"

        # Relationships - Observability
        llamaStack -> otelCollector "Traces and metrics export" "HTTP OTLP"
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
                background #438dd5
                color #ffffff
            }
            element "External - Cloud" {
                background #999999
                color #ffffff
            }
            element "External - Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #d4a017
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

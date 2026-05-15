workspace {
    model {
        user = person "Data Scientist / Developer" "Creates AI applications, sends inference requests, manages agents and RAG pipelines"

        llamaStack = softwareSystem "Llama Stack" "Modular AI application server providing standardized REST APIs for LLM inference, agents, RAG, safety, evaluation, and post-training with a pluggable provider architecture" {
            server = container "Llama Stack Server" "Main API server exposing REST endpoints on port 8321 with ASGI middleware chain" "Python (FastAPI/uvicorn)"
            providerSystem = container "Provider Plugin System" "Pluggable architecture for inline and remote providers across all API surfaces" "Python Framework"
            accessControl = container "Access Control System" "Attribute-based access control (ABAC) with Cedar-like policy rules" "Python Module"
            middlewareChain = container "Middleware Chain" "ClientVersion → Authentication → Quota → Tracing middleware layers" "ASGI Middleware"
            distributionTemplates = container "Distribution Templates" "Pre-configured provider combinations (remote-vllm, starter, ollama)" "YAML Configuration"
            cli = container "CLI (llama)" "Command-line interface for building, running, and managing distributions" "Python CLI"
        }

        # Internal Platform Dependencies
        vllm = softwareSystem "vLLM Model Serving" "Primary LLM inference backend for RHOAI deployments (OpenAI-compatible API)" "Internal RHOAI"
        postgres = softwareSystem "PostgreSQL + pgvector" "Vector storage for RAG retrieval, KV store, and inference state persistence" "Internal RHOAI"
        redis = softwareSystem "Redis" "KV store for metadata, quota tracking, and session state" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics export" "Internal RHOAI"
        oauth2Provider = softwareSystem "OAuth2/OIDC Provider" "JWT validation via JWKS and token introspection" "Internal RHOAI"

        # External Dependencies
        openaiAPI = softwareSystem "OpenAI API" "Remote LLM inference provider" "External Cloud"
        anthropicAPI = softwareSystem "Anthropic API" "Remote LLM inference provider" "External Cloud"
        awsBedrock = softwareSystem "AWS Bedrock" "Remote LLM inference provider (SigV4 auth)" "External Cloud"
        googleGemini = softwareSystem "Google Gemini API" "Remote LLM inference provider" "External Cloud"
        nvidiaNIM = softwareSystem "NVIDIA NIM" "Remote LLM inference provider" "External Cloud"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model weight downloads and HuggingFace integration" "External Cloud"
        searchAPIs = softwareSystem "Search APIs (Tavily/Brave)" "Web search tool providers for agents" "External Cloud"
        vectorDBs = softwareSystem "Vector Databases (Chroma/Qdrant/Milvus/Weaviate)" "Alternative vector storage backends" "External"
        mcpServers = softwareSystem "MCP Servers" "External tool integration via Model Context Protocol" "External"

        # Relationships
        user -> llamaStack "Sends inference requests, manages agents and models via REST API" "HTTPS/8321"
        user -> cli "Builds and manages distributions" "CLI"

        # Internal flows
        server -> middlewareChain "Processes requests through" "ASGI"
        middlewareChain -> accessControl "Evaluates access policies" "In-process"
        server -> providerSystem "Routes API calls to providers" "In-process"
        distributionTemplates -> providerSystem "Configures active providers" "YAML"

        # Internal platform integrations
        llamaStack -> vllm "LLM inference: completions, chat, embeddings" "HTTP/HTTPS :8000"
        llamaStack -> postgres "Vector queries, metadata persistence, inference state" "PostgreSQL :5432"
        llamaStack -> redis "KV store, quota tracking, session state" "Redis :6379"
        llamaStack -> otelCollector "Exports traces and metrics" "HTTP (OTLP)"
        llamaStack -> oauth2Provider "Validates JWT tokens, key refresh" "HTTPS :443"

        # External cloud integrations
        llamaStack -> openaiAPI "Remote inference" "HTTPS :443"
        llamaStack -> anthropicAPI "Remote inference" "HTTPS :443"
        llamaStack -> awsBedrock "Remote inference" "HTTPS :443 (SigV4)"
        llamaStack -> googleGemini "Remote inference" "HTTPS :443"
        llamaStack -> nvidiaNIM "Remote inference" "HTTPS :443"
        llamaStack -> huggingfaceHub "Downloads model weights" "HTTPS :443"
        llamaStack -> searchAPIs "Agent tool execution (web search)" "HTTPS :443"
        llamaStack -> vectorDBs "Vector storage (Chroma :8000, Qdrant :6333, Milvus :19530, Weaviate :8080)" "HTTP/gRPC"
        llamaStack -> mcpServers "External tool integration" "HTTP/HTTPS"
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
            element "External Cloud" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #bbbbbb
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

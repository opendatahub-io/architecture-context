workspace {
    model {
        dataScientist = person "Data Scientist" "Creates agents, runs inference, manages models and datasets"
        mlEngineer = person "ML Engineer" "Deploys and configures LLM inference backends and fine-tuning jobs"
        appDeveloper = person "Application Developer" "Integrates AI capabilities via OpenAI-compatible APIs"

        ogx = softwareSystem "OGX (Llama Stack)" "Modular AI/ML API server providing unified interface for inference, agents, safety, RAG, evaluation, and post-training" {
            apiServer = container "API Server" "FastAPI/Uvicorn HTTP server exposing 11 API types on port 8321" "Python FastAPI"
            authMiddleware = container "Auth Middleware" "JWT/OAuth2/Custom token validation with Cedar-like access control" "Python Middleware"
            providerSystem = container "Provider Plugin System" "Routes requests to 70+ inline/remote provider implementations" "Python Plugin Framework"
            routingLayer = container "Routing Layer" "Model dispatch, token counting, telemetry metrics, streaming transformation" "Python Routers"
            agentOrchestrator = container "Agent Orchestrator" "Multi-turn agent workflows with tool use, safety checks, and session state" "Python Service"
            kvStore = container "KV Store" "Key-value persistence for sessions, registry, and resource metadata" "SQLite/Redis/PostgreSQL/MongoDB"
            sqlStore = container "SQL Store" "Relational storage for OpenAI Responses API and structured data" "SQLite/PostgreSQL"
            playgroundUI = container "Playground UI" "Interactive web UI for testing inference, RAG, and tool use on port 8501" "Streamlit"
            cli = container "CLI (llama)" "Command-line interface for building, configuring, and running distributions" "Python Fire"
        }

        # Inference Providers
        ollama = softwareSystem "Ollama" "Local LLM inference server" "Inference Provider"
        vllm = softwareSystem "vLLM" "High-throughput LLM serving with OpenAI-compatible API" "Inference Provider"
        tgi = softwareSystem "TGI" "HuggingFace Text Generation Inference" "Inference Provider"
        openaiAPI = softwareSystem "OpenAI API" "Cloud LLM inference service" "Cloud Provider"
        anthropicAPI = softwareSystem "Anthropic API" "Cloud LLM inference service" "Cloud Provider"
        awsBedrock = softwareSystem "AWS Bedrock" "Cloud inference, safety, and training" "Cloud Provider"
        nvidiaNIM = softwareSystem "NVIDIA NIM" "NVIDIA inference, eval, safety, and post-training" "Cloud Provider"

        # Vector Databases
        chromaDB = softwareSystem "ChromaDB" "Vector database for RAG" "Vector DB"
        qdrant = softwareSystem "Qdrant" "Vector database with REST/gRPC interface" "Vector DB"
        milvus = softwareSystem "Milvus" "Distributed vector database with gRPC" "Vector DB"

        # Data Stores
        postgresql = softwareSystem "PostgreSQL" "Relational DB for KV store, SQL store, and pgvector" "Data Store"
        redis = softwareSystem "Redis" "In-memory KV cache" "Data Store"

        # External Services
        oidcProvider = softwareSystem "OIDC/OAuth2 Provider" "JWT public key endpoint for auth validation" "Auth Service"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External Service"
        searchAPIs = softwareSystem "Search APIs" "Brave, Bing, Tavily, Wolfram Alpha web search" "External Service"
        mcpServers = softwareSystem "MCP Servers" "Model Context Protocol tool integration" "External Service"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics collection" "Observability"

        # User relationships
        dataScientist -> ogx "Creates agents, runs inference, manages datasets" "HTTP/HTTPS 8321"
        mlEngineer -> ogx "Configures providers, runs fine-tuning" "HTTP/HTTPS 8321"
        appDeveloper -> ogx "Calls OpenAI-compatible APIs" "HTTP/HTTPS 8321"

        # Internal container relationships
        apiServer -> authMiddleware "Validates requests"
        authMiddleware -> routingLayer "Authorized requests"
        routingLayer -> providerSystem "Routes to providers"
        routingLayer -> agentOrchestrator "Agent workflows"
        agentOrchestrator -> providerSystem "Inference + safety + tools"
        providerSystem -> kvStore "Persist state"
        providerSystem -> sqlStore "Structured data"
        playgroundUI -> apiServer "Test API calls" "HTTP 8321"
        cli -> apiServer "Manage distributions"

        # External relationships - Inference
        ogx -> ollama "Local inference requests" "HTTP/11434"
        ogx -> vllm "Remote inference requests" "HTTP(S)/8000"
        ogx -> tgi "HF inference requests" "HTTP(S)/8080"
        ogx -> openaiAPI "Cloud inference" "HTTPS/443"
        ogx -> anthropicAPI "Cloud inference" "HTTPS/443"
        ogx -> awsBedrock "Cloud inference + safety" "HTTPS/443"
        ogx -> nvidiaNIM "NVIDIA inference + eval" "HTTPS/443"

        # External relationships - Vector DBs
        ogx -> chromaDB "Vector storage and retrieval" "HTTP/8000"
        ogx -> qdrant "Vector storage and retrieval" "HTTP+gRPC/6333"
        ogx -> milvus "Vector storage and retrieval" "gRPC/19530"

        # External relationships - Data Stores
        ogx -> postgresql "KV store, SQL store, pgvector" "PostgreSQL/5432"
        ogx -> redis "KV cache" "Redis/6379"

        # External relationships - Services
        ogx -> oidcProvider "JWT public key retrieval" "HTTPS/443"
        ogx -> huggingfaceHub "Model download, dataset access" "HTTPS/443"
        ogx -> searchAPIs "Web search tool integration" "HTTPS/443"
        ogx -> mcpServers "Tool integration via MCP" "HTTP/stdio"
        ogx -> otelCollector "Trace and metric export" "HTTP/4318 OTLP"
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
            element "Inference Provider" {
                background #fff3e0
                color #333333
            }
            element "Cloud Provider" {
                background #f5a623
                color #333333
            }
            element "Vector DB" {
                background #f3e5f5
                color #333333
            }
            element "Data Store" {
                background #e8f5e9
                color #333333
            }
            element "Auth Service" {
                background #ffcc80
                color #333333
            }
            element "External Service" {
                background #e0e0e0
                color #333333
            }
            element "Observability" {
                background #e0f2f1
                color #333333
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

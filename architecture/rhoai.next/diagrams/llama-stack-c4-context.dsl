workspace {
    model {
        user = person "Data Scientist / Developer" "Creates inference requests, manages agents, and deploys models via Llama Stack API"
        platformOps = person "Platform Operator" "Deploys and configures Llama Stack distributions via CLI and YAML templates"

        llamaStack = softwareSystem "Llama Stack" "Extensible AI inference and agent orchestration server with unified API layer" {
            server = container "Llama Stack Server" "FastAPI/Uvicorn HTTP server exposing inference, agents, safety, RAG, eval, and telemetry endpoints" "Python (FastAPI)"
            authMiddleware = container "Authentication Middleware" "Validates Bearer tokens via OAuth2 JWT (JWKS), token introspection, or custom auth provider" "Python Module"
            quotaMiddleware = container "Quota Middleware" "Enforces per-client request rate limits for authenticated and anonymous users" "Python Module"
            accessControl = container "Access Control Engine" "Cedar-inspired ABAC policy engine enforcing permit/forbid rules on resource operations" "Python Module"
            providerRouter = container "Provider Router" "Routes API requests to correct provider implementation based on model/resource ID routing tables" "Python Module"
            cli = container "llama CLI" "Command-line interface for stack build, run, model download, and template management" "Python CLI (fire)"
        }

        # Inference Backends
        vllm = softwareSystem "vLLM" "High-performance LLM inference server (primary RHOAI backend)" "External"
        ollama = softwareSystem "Ollama" "Local LLM inference server for development" "External"
        tgi = softwareSystem "TGI" "HuggingFace Text Generation Inference" "External"
        openai = softwareSystem "OpenAI API" "OpenAI cloud inference service" "External"
        anthropic = softwareSystem "Anthropic API" "Anthropic cloud inference service" "External"
        bedrock = softwareSystem "AWS Bedrock" "AWS-managed inference service" "External"
        gemini = softwareSystem "Google Gemini API" "Google cloud inference service" "External"
        nvidia = softwareSystem "NVIDIA NIM" "NVIDIA cloud inference service" "External"

        # Vector Stores
        pgvector = softwareSystem "PostgreSQL (pgvector)" "Vector storage for RAG workflows" "External"
        chromadb = softwareSystem "ChromaDB" "Vector database for RAG" "External"
        qdrant = softwareSystem "Qdrant" "Vector database for RAG" "External"
        milvus = softwareSystem "Milvus" "Vector database for RAG" "External"

        # Supporting Services
        oauth2Idp = softwareSystem "OAuth2 Identity Provider" "JWT token validation via JWKS and token introspection" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace and metrics aggregation" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model artifact downloads and metadata" "External"
        sqlite = softwareSystem "SQLite" "Local metadata store, quota tracking, inference history" "Internal"

        # Tool APIs
        braveSearch = softwareSystem "Brave Search API" "Web search tool for agents" "External"
        tavilySearch = softwareSystem "Tavily Search API" "Web search tool for agents" "External"

        # Relationships
        user -> llamaStack "Creates inference requests, manages agents and resources" "REST API / HTTPS 8321"
        platformOps -> cli "Configures and deploys Llama Stack distributions" "CLI"
        cli -> server "Starts server with distribution config" "--config run.yaml"

        server -> authMiddleware "Validates incoming requests"
        authMiddleware -> quotaMiddleware "Passes authenticated requests"
        quotaMiddleware -> accessControl "Passes rate-limited requests"
        accessControl -> providerRouter "Passes authorized requests"

        authMiddleware -> oauth2Idp "Fetches JWKS / introspects tokens" "HTTPS/443"
        quotaMiddleware -> sqlite "Tracks request counts" "File I/O"

        providerRouter -> vllm "Inference requests (primary)" "HTTP/8000"
        providerRouter -> ollama "Inference requests (dev)" "HTTP/11434"
        providerRouter -> tgi "Inference requests" "HTTPS/443"
        providerRouter -> openai "Inference requests" "HTTPS/443"
        providerRouter -> anthropic "Inference requests" "HTTPS/443"
        providerRouter -> bedrock "Inference requests" "HTTPS/443 (AWS SigV4)"
        providerRouter -> gemini "Inference requests" "HTTPS/443"
        providerRouter -> nvidia "Inference requests" "HTTPS/443"

        providerRouter -> pgvector "Vector storage queries" "TCP/5432"
        providerRouter -> chromadb "Vector storage queries" "HTTP/8000"
        providerRouter -> qdrant "Vector storage queries" "HTTP/6333"
        providerRouter -> milvus "Vector storage queries" "gRPC/19530"

        providerRouter -> braveSearch "Web search for agent tools" "HTTPS/443"
        providerRouter -> tavilySearch "Web search for agent tools" "HTTPS/443"

        server -> otlpCollector "Exports traces and metrics" "HTTP/4318"
        server -> huggingfaceHub "Downloads model artifacts" "HTTPS/443"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
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

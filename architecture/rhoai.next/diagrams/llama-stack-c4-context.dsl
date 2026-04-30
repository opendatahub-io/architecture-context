workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models, runs inference, manages agents"
        appDeveloper = person "Application Developer" "Integrates AI capabilities via OpenAI-compatible APIs"

        llamaStack = softwareSystem "Llama Stack" "Extensible AI inference and agent orchestration server providing unified API for model inference, safety, RAG, evaluation, and agentic workflows" {
            server = container "Llama Stack Server" "FastAPI/Uvicorn HTTP API server on port 8321" "Python / FastAPI"
            authMiddleware = container "Authentication Middleware" "Validates Bearer JWT tokens via JWKS or token introspection" "Python Module"
            quotaMiddleware = container "Quota Middleware" "Enforces per-client request rate limits" "Python Module"
            accessControl = container "Access Control Engine" "Cedar-inspired ABAC policy engine for resource-level authorization" "Python Module"
            providerRouter = container "Provider Router" "Routes API requests to correct provider based on model/resource registration" "Python Module"
            cli = container "CLI (llama)" "Command-line interface for stack build, run, model download, template management" "Python CLI (fire)"
        }

        # Inference Providers
        vllm = softwareSystem "vLLM" "High-performance LLM inference engine — primary backend for RHOAI" "External"
        ollama = softwareSystem "Ollama" "Local LLM inference for development" "External"
        tgi = softwareSystem "TGI / HuggingFace" "HuggingFace Text Generation Inference" "External"
        openai = softwareSystem "OpenAI API" "OpenAI cloud inference service" "External"
        anthropic = softwareSystem "Anthropic API" "Anthropic cloud inference service" "External"
        bedrock = softwareSystem "AWS Bedrock" "AWS-hosted inference service" "External"
        gemini = softwareSystem "Google Gemini API" "Google cloud inference service" "External"
        nvidia = softwareSystem "NVIDIA NIM" "NVIDIA cloud inference service" "External"

        # Vector Databases
        pgvector = softwareSystem "PostgreSQL (pgvector)" "Relational database with vector similarity search" "External"
        chromadb = softwareSystem "ChromaDB" "Vector database for RAG" "External"
        qdrant = softwareSystem "Qdrant" "Vector search engine" "External"
        milvus = softwareSystem "Milvus" "Distributed vector database" "External"

        # Tools & Services
        braveSearch = softwareSystem "Brave Search" "Web search API for agent tools" "External"
        tavilySearch = softwareSystem "Tavily Search" "Web search API for agent tools" "External"
        wolframAlpha = softwareSystem "Wolfram Alpha" "Computation engine for agent tools" "External"

        # Infrastructure
        oauth2IdP = softwareSystem "OAuth2 Identity Provider" "JWT token issuance and JWKS key publication" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace and metrics aggregation" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model repository for downloading model artifacts" "External"
        sqlite = softwareSystem "SQLite" "File-based metadata store, quota tracking, inference history" "Internal"

        # Relationships
        dataScientist -> llamaStack "Creates agents, runs inference, manages models" "HTTPS/8321 Bearer JWT"
        appDeveloper -> llamaStack "Calls OpenAI-compatible inference API" "HTTPS/8321 Bearer JWT"

        llamaStack -> vllm "Sends inference requests" "HTTP/8000 API Key"
        llamaStack -> ollama "Sends inference requests (dev)" "HTTP/11434"
        llamaStack -> tgi "Sends inference requests" "HTTPS/443 API Key"
        llamaStack -> openai "Sends inference requests" "HTTPS/443 API Key"
        llamaStack -> anthropic "Sends inference requests" "HTTPS/443 API Key"
        llamaStack -> bedrock "Sends inference requests" "HTTPS/443 AWS IAM"
        llamaStack -> gemini "Sends inference requests" "HTTPS/443 API Key"
        llamaStack -> nvidia "Sends inference requests" "HTTPS/443 API Key"

        llamaStack -> pgvector "Stores/queries vector embeddings" "TCP/5432 Username/Password"
        llamaStack -> chromadb "Stores/queries vector embeddings" "HTTP/8000"
        llamaStack -> qdrant "Stores/queries vector embeddings" "HTTP/6333"
        llamaStack -> milvus "Stores/queries vector embeddings" "gRPC/19530"

        llamaStack -> braveSearch "Web search for agent tools" "HTTPS/443 API Key"
        llamaStack -> tavilySearch "Web search for agent tools" "HTTPS/443 API Key"
        llamaStack -> wolframAlpha "Computation for agent tools" "HTTPS/443 API Key"

        llamaStack -> oauth2IdP "Fetches JWKS keys for JWT validation" "HTTPS/443"
        llamaStack -> otlpCollector "Exports traces and metrics" "HTTP/4318"
        llamaStack -> huggingfaceHub "Downloads model artifacts" "HTTPS/443 API Key"
        llamaStack -> sqlite "Reads/writes metadata, quotas, history" "File I/O"
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

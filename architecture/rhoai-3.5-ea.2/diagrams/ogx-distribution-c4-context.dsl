workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models, runs inference, manages agentic workflows"
        appDeveloper = person "Application Developer" "Integrates AI/ML APIs into applications via OpenAI/Anthropic-compatible endpoints"

        ogxDistribution = softwareSystem "OGX Distribution" "Multi-provider AI gateway providing inference, vector storage, file processing, and agentic APIs" {
            ogxServer = container "OGX Server" "Unified API gateway with env-var-activated providers for inference, vector I/O, file processing, responses, batches" "Python 3.12 / FastAPI"
            authMiddleware = container "Auth Middleware" "OAuth2/OIDC JWT validation via JWKS with configurable access policies" "Python Built-in"
            providerSystem = container "Provider System" "Dynamic provider activation based on environment variables; supports 8 inference, 4 vector, 3 file, 3 tool providers" "Python Plugin Architecture"
        }

        # Required Dependencies
        vllm = softwareSystem "vLLM" "Primary LLM inference backend (OpenAI-compatible API)" "Required"
        vllmEmbedding = softwareSystem "vLLM Embedding" "Text embedding generation (OpenAI-compatible API)" "Required"
        postgresql = softwareSystem "PostgreSQL" "State persistence: KV store, inference logs, batches, responses, file metadata, vector store metadata" "Required"

        # Platform Dependencies
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator managing OGX deployment lifecycle" "Internal RHOAI"
        gatewayAPI = softwareSystem "Gateway API" "Platform-managed TLS termination and ingress routing" "Internal RHOAI"

        # Optional Cloud Inference Providers
        awsBedrock = softwareSystem "AWS Bedrock" "Cloud LLM inference via AWS" "External Optional"
        ibmWatsonX = softwareSystem "IBM WatsonX" "Cloud LLM inference via IBM" "External Optional"
        azureOpenAI = softwareSystem "Azure OpenAI" "Cloud LLM inference via Azure" "External Optional"
        googleVertexAI = softwareSystem "Google Vertex AI" "Cloud LLM inference via GCP" "External Optional"
        openai = softwareSystem "OpenAI" "Cloud LLM inference via OpenAI" "External Optional"
        googleGemini = softwareSystem "Google Gemini" "Cloud LLM inference via Gemini" "External Optional"
        anthropic = softwareSystem "Anthropic" "Cloud LLM inference via Anthropic" "External Optional"

        # Optional Vector DBs
        milvus = softwareSystem "Milvus" "Remote vector database for RAG" "External Optional"
        qdrant = softwareSystem "Qdrant" "Vector database for RAG" "External Optional"

        # Optional Tools & Storage
        awsS3 = softwareSystem "AWS S3" "Remote file/model artifact storage" "External Optional"
        braveSearch = softwareSystem "Brave Search" "Web search tool for agentic workflows" "External Optional"
        tavilySearch = softwareSystem "Tavily Search" "Web search tool for agentic workflows" "External Optional"

        # Auth
        oidcProvider = softwareSystem "OIDC/OAuth2 Provider" "JWT token issuance and JWKS endpoint" "External Optional"

        # Observability
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed traces and metrics collection" "External Optional"

        # Relationships - Users
        dataScientist -> ogxDistribution "Submits inference, RAG, agentic requests" "HTTPS/443 via Gateway"
        appDeveloper -> ogxDistribution "Integrates OpenAI/Anthropic-compatible APIs" "HTTPS/443 via Gateway"

        # Relationships - Required
        ogxDistribution -> vllm "Sends inference requests" "HTTP(S)/configurable, Bearer Token"
        ogxDistribution -> vllmEmbedding "Generates text embeddings" "HTTP(S)/configurable, Bearer Token"
        ogxDistribution -> postgresql "Persists state and metadata" "TCP/5432, username/password"

        # Relationships - Platform
        rhodsOperator -> ogxDistribution "Manages deployment lifecycle" "Kubernetes API"
        gatewayAPI -> ogxDistribution "Routes external traffic with TLS termination" "HTTP/8321"

        # Relationships - Optional Cloud Providers
        ogxDistribution -> awsBedrock "LLM inference (conditional)" "HTTPS/443, AWS IAM"
        ogxDistribution -> ibmWatsonX "LLM inference (conditional)" "HTTPS/443, API key"
        ogxDistribution -> azureOpenAI "LLM inference (conditional)" "HTTPS/443, API key"
        ogxDistribution -> googleVertexAI "LLM inference (conditional)" "HTTPS/443, GCP credentials"
        ogxDistribution -> openai "LLM inference (conditional)" "HTTPS/443, API key"
        ogxDistribution -> googleGemini "LLM inference (conditional)" "HTTPS/443, API key"
        ogxDistribution -> anthropic "LLM inference (conditional)" "HTTPS/443, API key"

        # Relationships - Optional Vector DBs
        ogxDistribution -> milvus "Vector storage and retrieval (conditional)" "TCP, TLS/mTLS"
        ogxDistribution -> qdrant "Vector storage and retrieval (conditional)" "HTTP/6333, gRPC/6334"

        # Relationships - Optional Tools & Storage
        ogxDistribution -> awsS3 "File storage (conditional)" "HTTPS/443, AWS IAM"
        ogxDistribution -> braveSearch "Web search tool (conditional)" "HTTPS/443, API key"
        ogxDistribution -> tavilySearch "Web search tool (conditional)" "HTTPS/443, API key"

        # Relationships - Auth & Observability
        ogxDistribution -> oidcProvider "Validates JWT tokens via JWKS" "HTTPS/443"
        ogxDistribution -> otelCollector "Exports traces and metrics" "HTTP/gRPC OTLP"
    }

    views {
        systemContext ogxDistribution "SystemContext" {
            include *
            autoLayout
        }

        container ogxDistribution "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Required" {
                background #4a90e2
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "External Optional" {
                background #999999
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

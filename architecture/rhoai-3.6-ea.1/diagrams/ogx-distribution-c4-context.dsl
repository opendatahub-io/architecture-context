workspace {
    model {
        user = person "Application Developer" "Sends inference, RAG, and agentic API requests"

        ogxDistribution = softwareSystem "OGX Distribution" "Red Hat-customized AI agent gateway exposing multi-provider inference, RAG, and agentic APIs over HTTP" {
            entrypoint = container "Entrypoint" "Resolves _FILE secrets, configures OTel, launches OGX" "Shell Script"
            ogxServer = container "OGX Server" "Unified API gateway routing to configurable providers" "Python / OGX Framework"
            authModule = container "Auth Module" "OAuth2 bearer token validation via JWKS" "Python"
            providerRouter = container "Provider Router" "Environment-gated provider activation and request routing" "Python"
        }

        postgresql = softwareSystem "PostgreSQL" "KV and SQL storage for agent state, conversations, batches, metadata" "Required"

        vllm = softwareSystem "vLLM" "Primary LLM and embedding model serving" "Internal RHOAI"
        bedrock = softwareSystem "AWS Bedrock" "Cloud inference provider" "External"
        watsonx = softwareSystem "IBM WatsonX" "Cloud inference provider" "External"
        azureAI = softwareSystem "Azure AI" "Cloud inference provider" "External"
        vertexAI = softwareSystem "Google Vertex AI" "Cloud inference provider" "External"
        openai = softwareSystem "OpenAI" "Cloud inference provider" "External"
        gemini = softwareSystem "Google Gemini" "Cloud inference provider" "External"
        anthropic = softwareSystem "Anthropic" "Cloud inference provider" "External"

        milvus = softwareSystem "Milvus" "Remote vector database for RAG" "External"
        pgvector = softwareSystem "PGVector" "Vector database via PostgreSQL extension" "External"
        qdrant = softwareSystem "Qdrant" "Vector database for RAG" "External"

        braveSearch = softwareSystem "Brave Search" "Web search tool runtime" "External"
        tavilySearch = softwareSystem "Tavily Search" "Web search tool runtime" "External"
        s3 = softwareSystem "S3 Storage" "Remote file storage" "External"
        otelCollector = softwareSystem "OTEL Collector" "Traces and metrics collection" "External"

        user -> ogxDistribution "Sends API requests" "HTTP/8321"
        ogxDistribution -> postgresql "Persists state & metadata" "PostgreSQL/5432"
        ogxDistribution -> vllm "Inference requests" "HTTP(S)/configurable"
        ogxDistribution -> bedrock "Inference requests" "HTTPS/443"
        ogxDistribution -> watsonx "Inference requests" "HTTPS/443"
        ogxDistribution -> azureAI "Inference requests" "HTTPS/443"
        ogxDistribution -> vertexAI "Inference requests" "HTTPS/443"
        ogxDistribution -> openai "Inference requests" "HTTPS/443"
        ogxDistribution -> gemini "Inference requests" "HTTPS/443"
        ogxDistribution -> anthropic "Inference requests" "HTTPS/443"
        ogxDistribution -> milvus "Vector operations" "HTTP(S)/configurable"
        ogxDistribution -> pgvector "Vector operations" "PostgreSQL/5432"
        ogxDistribution -> qdrant "Vector operations" "HTTP/6333, gRPC/6334"
        ogxDistribution -> braveSearch "Web search" "HTTPS/443"
        ogxDistribution -> tavilySearch "Web search" "HTTPS/443"
        ogxDistribution -> s3 "File storage" "HTTPS/443"
        ogxDistribution -> otelCollector "Traces and metrics" "OTLP/configurable"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Required" {
                background #f5a623
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
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

workspace {
    model {
        user = person "Data Scientist / Developer" "Creates and deploys AI/ML workloads via OGX APIs"
        admin = person "Platform Administrator" "Manages OGX deployment and configuration"

        ogxDistribution = softwareSystem "OGX Distribution" "AI/ML API server providing OpenAI-compatible, Anthropic-compatible, and agentic Responses APIs with pluggable inference, vector storage, and tool runtime providers" {
            ogxServer = container "OGX Server" "Main API server handling inference routing, file management, vector stores, batches, and agentic workflows" "Python 3.12 / OGX v1.4.0+rhaiv.1"
            entrypoint = container "entrypoint.sh" "Secret resolution (18 _FILE variants), OpenTelemetry configuration, server startup" "Shell Script"
            authMiddleware = container "Auth Middleware" "OAuth2 JWT validation via JWKS, owner-based access policy enforcement" "Python"
            accessPolicy = container "Access Policy Engine" "Per-user ownership filtering: read unowned, create any, manage own" "Python"
        }

        ogxOperator = softwareSystem "ogx-operator" "Manages OGX server lifecycle and configuration on OpenShift" "Internal RHOAI"

        vllm = softwareSystem "vLLM" "Primary LLM inference backend for chat completions and embeddings" "Internal / External"
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for conversations, metadata, inference logs, agent state, file metadata" "External"

        openai = softwareSystem "OpenAI API" "Remote LLM inference provider" "External Cloud"
        anthropicAPI = softwareSystem "Anthropic API" "Remote LLM inference provider" "External Cloud"
        azureOpenAI = softwareSystem "Azure OpenAI" "Remote LLM inference provider" "External Cloud"
        awsBedrock = softwareSystem "AWS Bedrock" "Remote LLM inference provider" "External Cloud"
        ibmWatsonX = softwareSystem "IBM WatsonX" "Remote LLM inference provider" "External Cloud"
        googleVertexAI = softwareSystem "Google Vertex AI" "Remote LLM inference provider" "External Cloud"
        googleGemini = softwareSystem "Google Gemini" "Remote LLM inference provider" "External Cloud"

        milvus = softwareSystem "Milvus" "Vector database for RAG workloads" "External"
        pgvector = softwareSystem "pgvector" "PostgreSQL vector extension for RAG" "External"
        qdrant = softwareSystem "Qdrant" "Vector database for RAG workloads" "External"
        s3 = softwareSystem "S3 Storage" "File storage backend" "External Cloud"

        braveSearch = softwareSystem "Brave Search API" "Web search tool runtime" "External Cloud"
        tavilySearch = softwareSystem "Tavily Search API" "Web search tool runtime" "External Cloud"

        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and monitoring" "Internal RHOAI"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics" "Internal RHOAI"
        praxis = softwareSystem "Praxis Proxy" "Multi-tenant identity propagation" "Internal RHOAI"

        oidcProvider = softwareSystem "OAuth2/OIDC Provider" "JWT token issuance and JWKS key management" "External"

        # Relationships
        user -> ogxDistribution "Creates chat completions, manages files/vector stores, runs agentic workflows" "HTTPS/443 (via platform)"
        admin -> ogxOperator "Configures OGX deployment"

        ogxOperator -> ogxDistribution "Manages lifecycle, injects env vars" "Kubernetes API"

        ogxDistribution -> vllm "LLM inference and embeddings" "HTTP/HTTPS, Bearer token"
        ogxDistribution -> postgresql "Persistent storage" "TCP/5432, username/password"

        ogxDistribution -> openai "Remote inference" "HTTPS/443, API key"
        ogxDistribution -> anthropicAPI "Remote inference" "HTTPS/443, API key"
        ogxDistribution -> azureOpenAI "Remote inference" "HTTPS/443, API key"
        ogxDistribution -> awsBedrock "Remote inference" "HTTPS/443, IAM/Bearer"
        ogxDistribution -> ibmWatsonX "Remote inference" "HTTPS/443, API key"
        ogxDistribution -> googleVertexAI "Remote inference" "HTTPS/443, GCP credentials"
        ogxDistribution -> googleGemini "Remote inference" "HTTPS/443, API key"

        ogxDistribution -> milvus "Vector storage" "HTTP/gRPC, Token"
        ogxDistribution -> pgvector "Vector storage" "TCP/5432, username/password"
        ogxDistribution -> qdrant "Vector storage" "HTTP/gRPC 6333-6334, API key"
        ogxDistribution -> s3 "File storage" "HTTPS/443, AWS IAM"

        ogxDistribution -> braveSearch "Web search" "HTTPS/443, API key"
        ogxDistribution -> tavilySearch "Web search" "HTTPS/443, API key"

        ogxDistribution -> oidcProvider "JWT key retrieval" "HTTPS/443, JWKS"

        prometheus -> ogxDistribution "Scrapes /metrics" "HTTP/8321, ServiceMonitor"
        otel -> ogxDistribution "Receives OTLP telemetry" "HTTP/gRPC"
        praxis -> ogxDistribution "Multi-tenant routing" "HTTP/8321, x-user-id/x-tenant-id headers"
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
            element "External Cloud" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #bbbbbb
                color #333333
            }
            element "Internal RHOAI" {
                background #7ed321
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

workspace {
    model {
        client = person "API Client" "Application or user consuming AI/ML APIs"
        securityAdmin = person "Security Admin" "Configures OAuth2 and tenant isolation"

        ogxDistribution = softwareSystem "OGX Distribution" "Containerized AI/ML API server with multi-provider inference, vector storage, file processing, and agentic workflows" {
            ogxServer = container "OGX Server" "Serves Responses, Messages, Inference, Vector I/O, Files, Batches APIs on port 8321" "Python 3.12"
            entrypoint = container "entrypoint.sh" "Resolves _FILE secrets, selects config, wraps with OpenTelemetry" "Shell Script"
            config = container "config.yaml" "Auto-generated runtime configuration with conditional provider activation" "YAML"
        }

        ogxOperator = softwareSystem "ogx-operator" "Manages OGX deployment lifecycle" "Internal RHOAI"
        praxis = softwareSystem "Praxis" "Identity proxy injecting x-user-id and x-tenant-id headers" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend" "Internal RHOAI"

        postgresql = softwareSystem "PostgreSQL" "State storage for sessions, files, vectors, batches" "External"

        vllm = softwareSystem "vLLM" "Primary LLM inference backend" "External"
        openai = softwareSystem "OpenAI API" "LLM inference provider" "External"
        anthropicApi = softwareSystem "Anthropic API" "LLM inference provider" "External"
        azureOpenai = softwareSystem "Azure OpenAI" "LLM inference provider" "External"
        bedrock = softwareSystem "AWS Bedrock" "LLM inference provider" "External"
        vertexAi = softwareSystem "Google Vertex AI" "LLM inference provider" "External"
        watsonx = softwareSystem "IBM watsonx" "LLM inference provider" "External"
        gemini = softwareSystem "Google Gemini" "LLM inference provider" "External"

        milvus = softwareSystem "Milvus" "Vector database" "External"
        pgvector = softwareSystem "PgVector" "Vector store via PostgreSQL extension" "External"
        qdrant = softwareSystem "Qdrant" "Vector database" "External"

        braveSearch = softwareSystem "Brave Search" "Web search tool provider" "External"
        tavilySearch = softwareSystem "Tavily Search" "Web search tool provider" "External"
        s3 = softwareSystem "AWS S3" "Remote file storage" "External"

        oidcProvider = softwareSystem "OIDC Provider" "OAuth2 token validation via JWKS" "External"

        client -> ogxDistribution "Sends API requests" "HTTP/8321, OAuth2 token"
        praxis -> ogxDistribution "Injects tenant identity headers" "HTTP/8321"
        ogxOperator -> ogxDistribution "Deploys and manages" "Kubernetes API"
        prometheus -> ogxDistribution "Scrapes metrics" "HTTP /metrics, 60s"

        ogxDistribution -> postgresql "Stores state" "TCP/5432, Password"
        ogxDistribution -> vllm "LLM inference and embeddings" "HTTP/HTTPS, Bearer token"
        ogxDistribution -> openai "LLM inference" "HTTPS/443, API key"
        ogxDistribution -> anthropicApi "LLM inference" "HTTPS/443, API key"
        ogxDistribution -> azureOpenai "LLM inference" "HTTPS/443, API key"
        ogxDistribution -> bedrock "LLM inference" "HTTPS/443, IAM"
        ogxDistribution -> vertexAi "LLM inference" "HTTPS/443, OAuth2"
        ogxDistribution -> watsonx "LLM inference" "HTTPS/443, API key"
        ogxDistribution -> gemini "LLM inference" "HTTPS/443, API key"
        ogxDistribution -> milvus "Vector operations" "HTTP/gRPC, Token"
        ogxDistribution -> pgvector "Vector operations" "TCP/5432, Password"
        ogxDistribution -> qdrant "Vector operations" "HTTP+gRPC/6333-6334, API key"
        ogxDistribution -> braveSearch "Web search" "HTTPS/443, API key"
        ogxDistribution -> tavilySearch "Web search" "HTTPS/443, API key"
        ogxDistribution -> s3 "File storage" "HTTPS/443, IAM"
        ogxDistribution -> oidcProvider "Token verification" "HTTPS/443, JWKS"
        ogxDistribution -> otelCollector "Exports traces" "OTLP"
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

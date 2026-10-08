workspace {
    model {
        client = person "API Client" "Application or user consuming OGX APIs for inference, RAG, and agentic workflows"

        ogxDistribution = softwareSystem "OGX Distribution" "Containerized OGX server providing inference, responses, messages, vector_io, files, file_processors, tool_runtime, and batches APIs" {
            ogxServer = container "OGX Server" "Python HTTP server exposing 8 API surfaces with conditional provider activation via environment variables" "Python 3.12, Port 8321"
            entrypoint = container "Entrypoint" "Resolves file-mounted secrets, selects config, launches OGX with optional OTel" "Shell Script"
            buildPipeline = container "Build Pipeline" "Code generation from build.yaml: config, Containerfile, lock files, docs" "Python Scripts"
        }

        vllm = softwareSystem "vLLM" "LLM inference backend for chat completions and embeddings" "Internal Platform"
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for kv_postgres and sql_postgres backends" "Internal Platform"
        ogxOperator = softwareSystem "ogx-operator" "Kubernetes operator managing OGX deployment lifecycle" "Internal Platform"

        openai = softwareSystem "OpenAI API" "Remote LLM inference provider" "External"
        anthropic = softwareSystem "Anthropic API" "Remote LLM inference provider" "External"
        azureOpenai = softwareSystem "Azure OpenAI" "Remote LLM inference provider" "External"
        bedrock = softwareSystem "AWS Bedrock" "Remote LLM inference provider" "External"
        watsonx = softwareSystem "WatsonX" "Remote LLM inference provider" "External"
        vertexAi = softwareSystem "Vertex AI" "Remote LLM inference provider" "External"
        gemini = softwareSystem "Gemini" "Remote LLM inference provider" "External"

        milvus = softwareSystem "Milvus" "Vector database for RAG workflows" "External"
        pgvector = softwareSystem "pgvector" "PostgreSQL-based vector database" "External"
        qdrant = softwareSystem "Qdrant" "Vector database for RAG workflows" "External"

        s3 = softwareSystem "S3-compatible Storage" "File and model artifact storage" "External"
        oauth2Issuer = softwareSystem "OAuth2 Issuer" "JWKS key discovery for JWT validation" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "Internal Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics export" "Internal Platform"

        braveSearch = softwareSystem "Brave Search API" "Web search tool provider" "External"
        tavilySearch = softwareSystem "Tavily Search API" "Web search tool provider" "External"

        client -> ogxDistribution "Sends inference, RAG, and agentic requests" "HTTP/8321, OAuth2 JWT"
        ogxDistribution -> vllm "Forwards inference and embedding requests" "HTTP/HTTPS, Bearer token"
        ogxDistribution -> postgresql "Stores metadata, agent state, conversations" "TCP/5432, Username/password"
        ogxOperator -> ogxDistribution "Manages deployment lifecycle" "Kubernetes API"

        ogxDistribution -> openai "Remote inference (optional)" "HTTPS/443, API key"
        ogxDistribution -> anthropic "Remote inference (optional)" "HTTPS/443, API key"
        ogxDistribution -> azureOpenai "Remote inference (optional)" "HTTPS/443, API key"
        ogxDistribution -> bedrock "Remote inference (optional)" "HTTPS/443, Bearer/IAM"
        ogxDistribution -> watsonx "Remote inference (optional)" "HTTPS/443, API key"
        ogxDistribution -> vertexAi "Remote inference (optional)" "HTTPS/443, OAuth2"
        ogxDistribution -> gemini "Remote inference (optional)" "HTTPS/443, API key"

        ogxDistribution -> milvus "Vector storage for RAG (optional)" "HTTP/gRPC, Token + mTLS"
        ogxDistribution -> pgvector "Vector storage for RAG (optional)" "TCP/5432, Password"
        ogxDistribution -> qdrant "Vector storage for RAG (optional)" "HTTP/gRPC/6333-6334, API key"

        ogxDistribution -> s3 "File storage (optional)" "HTTPS/443, AWS credentials"
        ogxDistribution -> oauth2Issuer "JWT key discovery" "HTTPS/443"
        prometheus -> ogxDistribution "Scrapes metrics" "HTTP /metrics"
        ogxDistribution -> otelCollector "Exports traces and metrics (optional)" "gRPC/HTTP"

        ogxDistribution -> braveSearch "Web search tool (optional)" "HTTPS/443, API key"
        ogxDistribution -> tavilySearch "Web search tool (optional)" "HTTPS/443, API key"
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
            element "Internal Platform" {
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

workspace {
    model {
        user = person "Data Scientist / Developer" "Creates AI/ML applications using OGX APIs for inference, RAG, and agent workflows"

        ogxDistribution = softwareSystem "OGX Distribution" "Multi-provider AI/ML API server providing inference, vector storage, file processing, and agent capabilities" {
            ogxServer = container "OGX Server" "Multi-provider AI/ML API server exposing OpenAI-compatible, Anthropic-compatible, and agent/responses APIs on port 8321/TCP" "Python (OGX Framework)"
            buildPipeline = container "Build Pipeline" "Code generation pipeline producing config.yaml, Containerfile, lock files, and docs from build/build.yaml" "Python Build Scripts"
        }

        # Platform
        rhoaiOperator = softwareSystem "RHOAI Platform (rhods-operator)" "Manages OGX server deployment lifecycle in OpenShift AI" "Internal Platform"

        # Inference Providers
        vllm = softwareSystem "vLLM ServingRuntime" "Primary LLM inference and embedding backend" "Internal Platform"
        openai = softwareSystem "OpenAI" "Cloud inference provider" "External Cloud"
        bedrock = softwareSystem "AWS Bedrock" "Cloud inference provider with IAM auth" "External Cloud"
        azure = softwareSystem "Azure OpenAI" "Cloud inference provider" "External Cloud"
        vertexai = softwareSystem "Google Vertex AI" "Cloud inference provider" "External Cloud"
        watsonx = softwareSystem "IBM WatsonX" "Cloud inference provider" "External Cloud"
        gemini = softwareSystem "Google Gemini" "Cloud inference provider" "External Cloud"
        anthropic = softwareSystem "Anthropic" "Cloud inference provider" "External Cloud"

        # Storage
        postgresql = softwareSystem "PostgreSQL" "Persistent KV store, SQL store, inference logs, batches, agent state" "External Storage"
        milvus = softwareSystem "Milvus" "Remote vector database for RAG workflows" "External Storage"
        pgvector = softwareSystem "pgvector" "PostgreSQL vector extension for vector I/O" "External Storage"
        qdrant = softwareSystem "Qdrant" "Remote vector database" "External Storage"
        s3 = softwareSystem "S3-compatible Storage" "File storage backend for RAG documents" "External Storage"

        # Tools
        braveSearch = softwareSystem "Brave Search" "Web search tool for agents" "External Tool"
        tavilySearch = softwareSystem "Tavily Search" "Web search tool for agents" "External Tool"
        doclingServe = softwareSystem "Docling Serve" "Remote document processing service" "External Tool"
        mcpServer = softwareSystem "MCP Server" "Model Context Protocol tool integration" "External Tool"

        # Auth
        oidcIssuer = softwareSystem "OAuth2/OIDC Issuer" "JWT token validation via JWKS endpoint (e.g., Keycloak)" "External Auth"

        # Observability
        otelCollector = softwareSystem "OpenTelemetry Collector" "Traces and metrics collection" "External Observability"

        # Relationships
        user -> ogxDistribution "Creates inference requests, uploads files, runs agents via REST API" "HTTPS/443"
        rhoaiOperator -> ogxDistribution "Deploys and manages OGX server" "Kubernetes API"

        ogxDistribution -> vllm "Sends inference and embedding requests" "HTTP/HTTPS, Bearer Token"
        ogxDistribution -> openai "Sends inference requests" "HTTPS/443, API Key"
        ogxDistribution -> bedrock "Sends inference requests" "HTTPS/443, IAM STS"
        ogxDistribution -> azure "Sends inference requests" "HTTPS/443, API Key"
        ogxDistribution -> vertexai "Sends inference requests" "HTTPS/443, GCP Creds"
        ogxDistribution -> watsonx "Sends inference requests" "HTTPS/443, API Key"
        ogxDistribution -> gemini "Sends inference requests" "HTTPS/443, API Key"
        ogxDistribution -> anthropic "Sends inference requests" "HTTPS/443, API Key"

        ogxDistribution -> postgresql "Stores KV data, SQL data, inference logs, batches, agent state" "TCP/5432, Password"
        ogxDistribution -> milvus "Stores and retrieves vectors for RAG" "TCP, Token"
        ogxDistribution -> pgvector "Stores and retrieves vectors" "TCP/5432, Password"
        ogxDistribution -> qdrant "Stores and retrieves vectors" "HTTP/6333 gRPC/6334, API Key"
        ogxDistribution -> s3 "Stores and retrieves files" "HTTPS/443, IAM"

        ogxDistribution -> braveSearch "Executes web searches for agents" "HTTPS/443, API Key"
        ogxDistribution -> tavilySearch "Executes web searches for agents" "HTTPS/443, API Key"
        ogxDistribution -> doclingServe "Processes documents remotely" "HTTP/HTTPS, API Key"
        ogxDistribution -> mcpServer "Invokes MCP tools" "varies"

        ogxDistribution -> oidcIssuer "Fetches JWKS for JWT validation" "HTTPS/443"
        ogxDistribution -> otelCollector "Exports traces and metrics" "OTLP, configurable"
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
            element "External Storage" {
                background #d6b656
                color #333333
            }
            element "External Tool" {
                background #9673a6
                color #ffffff
            }
            element "External Auth" {
                background #b85450
                color #ffffff
            }
            element "External Observability" {
                background #6c8ebf
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #333333
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

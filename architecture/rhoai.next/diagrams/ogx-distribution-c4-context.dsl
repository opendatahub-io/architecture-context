workspace {
    model {
        user = person "Data Scientist / Developer" "Creates inference requests, agentic workflows, and RAG pipelines"
        operator = person "Platform Operator" "Deploys and configures OGX via rhods-operator"

        ogxDistribution = softwareSystem "OGX Distribution" "Pre-configured, multi-provider AI/ML API server for inference, agentic workflows, RAG, and file processing" {
            ogxServer = container "OGX Server (ogx-core)" "Multi-provider AI/ML API server with env-var-activated providers" "Python 3.12 Container"
            entrypoint = container "Entrypoint Script" "Secret _FILE resolution, provider activation, process exec" "Shell Script"
            buildPipeline = container "Build Pipeline" "Code generation from build.yaml (config, Containerfile, lockfile, docs)" "Python Scripts"
            artifactFetcher = container "Artifact Fetcher" "Downloads ML model artifacts with SHA-256 verification" "Python Script"
        }

        # Internal Platform Dependencies
        vllm = softwareSystem "vLLM" "LLM inference and embedding model serving" "Internal Platform"
        postgresql = softwareSystem "PostgreSQL" "State storage for conversations, batches, agent state, file metadata" "Internal Platform"

        # Vector Storage Backends
        milvus = softwareSystem "Milvus" "Vector storage and similarity search" "Internal Platform"
        pgvector = softwareSystem "pgvector" "PostgreSQL-based vector storage" "Internal Platform"
        qdrant = softwareSystem "Qdrant" "Vector storage and similarity search" "Internal Platform"

        # Cloud Inference Providers
        awsBedrock = softwareSystem "AWS Bedrock" "Cloud inference (Claude, Titan)" "External Cloud"
        ibmWatsonx = softwareSystem "IBM WatsonX" "Cloud inference (Granite)" "External Cloud"
        azureOpenai = softwareSystem "Azure OpenAI" "Cloud inference (GPT models)" "External Cloud"
        googleVertexAI = softwareSystem "Google Vertex AI" "Cloud inference (Gemini models)" "External Cloud"
        openai = softwareSystem "OpenAI API" "Cloud inference (GPT models)" "External Cloud"
        googleGemini = softwareSystem "Google Gemini API" "Cloud inference (Gemini models)" "External Cloud"
        anthropic = softwareSystem "Anthropic API" "Cloud inference (Claude models)" "External Cloud"

        # Tool Services
        braveSearch = softwareSystem "Brave Search API" "Web search for agentic workflows" "External Service"
        tavilySearch = softwareSystem "Tavily Search API" "Web search for agentic workflows" "External Service"
        s3 = softwareSystem "S3 / Object Storage" "File storage backend" "External Service"
        doclingServe = softwareSystem "Docling Serve" "Remote document processing" "External Service"
        mcpServers = softwareSystem "MCP Servers" "External tool execution via Model Context Protocol" "External Service"

        # Observability
        otelCollector = softwareSystem "OTEL Collector" "OpenTelemetry traces and metrics" "Observability"
        jwksEndpoint = softwareSystem "JWKS Endpoint" "OAuth2 token validation key retrieval" "Auth Infrastructure"

        # Platform
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Deploys and manages OGX container" "Internal Platform"
        aipccBaseImage = softwareSystem "AIPCC Base Image" "RHEL 9.6 UBI with Python 3.12, FIPS-validated OpenSSL" "Build Infrastructure"

        # Relationships
        user -> ogxDistribution "Sends inference/RAG/agent requests via HTTP" "HTTP/8321, OAuth2 JWT"
        operator -> rhodsOperator "Configures OGX deployment"
        rhodsOperator -> ogxDistribution "Deploys and manages"

        ogxDistribution -> vllm "Sends inference and embedding requests" "HTTP/HTTPS, Bearer Token"
        ogxDistribution -> postgresql "Persists state (conversations, batches, metadata)" "PostgreSQL/5432, Password"
        ogxDistribution -> milvus "Vector storage and search" "HTTP/gRPC, mTLS, Token"
        ogxDistribution -> pgvector "Vector similarity search" "PostgreSQL/5432, Password"
        ogxDistribution -> qdrant "Vector storage and search" "HTTP-gRPC/6333-6334, API Key"

        ogxDistribution -> awsBedrock "Cloud inference" "HTTPS/443, AWS IAM"
        ogxDistribution -> ibmWatsonx "Cloud inference" "HTTPS/443, API Key"
        ogxDistribution -> azureOpenai "Cloud inference" "HTTPS/443, API Key"
        ogxDistribution -> googleVertexAI "Cloud inference" "HTTPS/443, Google ADC"
        ogxDistribution -> openai "Cloud inference" "HTTPS/443, API Key"
        ogxDistribution -> googleGemini "Cloud inference" "HTTPS/443, API Key"
        ogxDistribution -> anthropic "Cloud inference" "HTTPS/443, API Key"

        ogxDistribution -> braveSearch "Web search tool" "HTTPS/443, API Key"
        ogxDistribution -> tavilySearch "Web search tool" "HTTPS/443, API Key"
        ogxDistribution -> s3 "File storage" "HTTPS/443, AWS IAM"
        ogxDistribution -> doclingServe "Document processing" "HTTP/HTTPS, API Key"
        ogxDistribution -> mcpServers "External tool execution" "HTTP/HTTPS, Configurable"

        ogxDistribution -> otelCollector "Exports traces and metrics" "OTLP HTTP/gRPC"
        ogxDistribution -> jwksEndpoint "Retrieves OAuth2 validation keys" "HTTPS/443"

        aipccBaseImage -> ogxDistribution "Provides base container layer" "Build-time"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External Cloud" {
                background #f5a623
                color #ffffff
            }
            element "External Service" {
                background #e74c3c
                color #ffffff
            }
            element "Observability" {
                background #999999
                color #ffffff
            }
            element "Auth Infrastructure" {
                background #9b59b6
                color #ffffff
            }
            element "Build Infrastructure" {
                background #e8e8e8
                color #333333
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape roundedbox
            }
        }
    }
}

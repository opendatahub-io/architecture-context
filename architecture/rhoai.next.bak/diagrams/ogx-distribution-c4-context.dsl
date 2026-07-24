workspace {
    model {
        user = person "Data Scientist / Developer" "Creates inference requests, uploads documents, builds agentic workflows"
        admin = person "Platform Admin" "Configures OGX providers and deployment"

        ogxDistribution = softwareSystem "OGX Distribution" "Multi-API AI gateway for inference, agentic responses, vector storage, file processing, and tool runtime" {
            ogxServer = container "OGX Server" "AI gateway providing OpenAI-compatible, Anthropic-compatible, and agentic APIs" "Python (Llama Stack fork)" {
                authMiddleware = component "OAuth2 Auth Middleware" "Validates JWT tokens against JWKS endpoint when AUTH_ISSUER is set" "Python"
                inferenceRouter = component "Inference Router" "Routes requests to configured inference providers based on env-activated config" "Python"
                agentEngine = component "Agent Engine" "Orchestrates multi-turn tool-use agentic responses" "Python"
                vectorIO = component "Vector I/O" "Manages vector store operations (insert, query, search)" "Python"
                fileProcessor = component "File Processor" "Processes documents via Docling, PyPDF, MarkItDown" "Python"
                toolRuntime = component "Tool Runtime" "Executes web search, file search, MCP tool calls" "Python"
            }
            entrypoint = container "Entrypoint" "Container entrypoint running ogx server with optional OpenTelemetry instrumentation" "Shell Script"
            configYAML = container "Distribution Config" "Runtime configuration with conditional provider activation via env vars" "YAML"
        }

        buildPipeline = softwareSystem "Build Pipeline" "Generates distribution artifacts from canonical provider manifest" {
            buildScript = container "build.py" "Processes build.yaml to generate config.yaml, requirements.txt, Containerfile" "Python"
            buildManifest = container "build.yaml" "Canonical provider manifest defining all supported providers and dependencies" "YAML"
        }

        // External Inference Providers
        vllm = softwareSystem "vLLM" "Primary inference provider for LLM completions and embeddings" "External"
        awsBedrock = softwareSystem "AWS Bedrock" "Remote inference provider (cloud)" "External"
        ibmWatsonX = softwareSystem "IBM WatsonX" "Remote inference provider (cloud)" "External"
        azureOpenAI = softwareSystem "Azure OpenAI" "Remote inference provider (cloud)" "External"
        googleVertexAI = softwareSystem "Google Vertex AI" "Remote inference provider (cloud)" "External"
        openai = softwareSystem "OpenAI" "Remote inference provider (cloud)" "External"
        googleGemini = softwareSystem "Google Gemini" "Remote inference provider (cloud)" "External"
        anthropic = softwareSystem "Anthropic" "Remote inference provider (cloud)" "External"

        // State Store
        postgresql = softwareSystem "PostgreSQL" "Primary state store for inference logs, agent state, batch jobs, conversations, file metadata" "External"

        // Vector Databases
        milvus = softwareSystem "Milvus" "Remote vector database for similarity search" "External"
        pgvector = softwareSystem "pgvector" "Vector database using PostgreSQL extension" "External"
        qdrant = softwareSystem "Qdrant" "Remote vector database" "External"

        // Tool Runtimes
        braveSearch = softwareSystem "Brave Search" "Web search tool runtime" "External"
        tavilySearch = softwareSystem "Tavily Search" "Web search tool runtime" "External"
        mcpServers = softwareSystem "MCP Servers" "Model Context Protocol tool servers" "External"
        doclingServe = softwareSystem "Docling Serve" "Remote document processing service" "External"

        // Storage
        s3 = softwareSystem "AWS S3" "Remote file storage for model artifacts and documents" "External"

        // Auth
        oidcIssuer = softwareSystem "OAuth2/OIDC Issuer" "JWKS key retrieval for JWT token validation" "External"

        // Observability
        otelCollector = softwareSystem "OpenTelemetry Collector" "Traces and metrics collection" "External"

        // Platform
        aipccBaseImage = softwareSystem "AIPCC Base Image" "RHEL 9 + Python 3.12 + RHEL AI PyPI container base" "Internal RHOAI"
        ogxUpstream = softwareSystem "opendatahub-io/ogx" "Upstream OGX server codebase (Llama Stack fork)" "Internal ODH"

        // Relationships
        user -> ogxDistribution "Sends inference, agentic, and RAG requests" "HTTP/8321"
        admin -> ogxDistribution "Configures via environment variables"

        ogxDistribution -> vllm "Inference and embedding requests" "HTTP(S)/8000-8001, Bearer Token"
        ogxDistribution -> awsBedrock "Remote inference" "HTTPS/443, IAM"
        ogxDistribution -> ibmWatsonX "Remote inference" "HTTPS/443, API Key"
        ogxDistribution -> azureOpenAI "Remote inference" "HTTPS/443, API Key"
        ogxDistribution -> googleVertexAI "Remote inference" "HTTPS/443, GCP ADC"
        ogxDistribution -> openai "Remote inference" "HTTPS/443, API Key"
        ogxDistribution -> googleGemini "Remote inference" "HTTPS/443, API Key"
        ogxDistribution -> anthropic "Remote inference" "HTTPS/443, API Key"

        ogxDistribution -> postgresql "State persistence" "PostgreSQL/5432, User/Pass"

        ogxDistribution -> milvus "Vector operations" "gRPC/HTTPS, TLS+mTLS, Token"
        ogxDistribution -> pgvector "Vector operations" "PostgreSQL/5432, User/Pass"
        ogxDistribution -> qdrant "Vector operations" "HTTP(S)/6333-6334, API Key"

        ogxDistribution -> braveSearch "Web search" "HTTPS/443, API Key"
        ogxDistribution -> tavilySearch "Web search" "HTTPS/443, API Key"
        ogxDistribution -> mcpServers "Tool execution" "HTTP(S), Configurable"
        ogxDistribution -> doclingServe "Document processing" "HTTP(S), API Key"

        ogxDistribution -> s3 "File storage" "HTTPS/443, IAM"
        ogxDistribution -> oidcIssuer "JWT validation (JWKS)" "HTTPS/443"
        ogxDistribution -> otelCollector "Traces and metrics" "OTLP gRPC/HTTP"

        ogxUpstream -> ogxDistribution "Provides OGX server packages" "Python pip install"
        aipccBaseImage -> ogxDistribution "Provides base container layer" "Container FROM"
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

        component ogxServer "Components" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Internal RHOAI" {
                background #cc0000
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Component" {
                background #85BBF0
                color #000000
            }
        }
    }
}

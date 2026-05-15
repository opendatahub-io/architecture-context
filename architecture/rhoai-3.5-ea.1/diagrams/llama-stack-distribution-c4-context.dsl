workspace {
    model {
        datascientist = person "Data Scientist / Developer" "Creates AI-powered applications using inference, agentic, and RAG capabilities"
        platformadmin = person "Platform Admin" "Deploys and configures OGX distribution on OpenShift AI"

        ogxDistribution = softwareSystem "OGX Distribution (odh-ogx-core)" "Unified AI inference gateway, agent orchestration, vector I/O, tool runtime, and file management server" {
            ogxServer = container "OGX Server" "AI orchestration server exposing OpenAI-compatible and OGX-native REST APIs" "Python / FastAPI / uvicorn" "Port 8321/TCP"
            authMiddleware = container "OAuth2 JWT Auth Middleware" "Validates JWT tokens via JWKS endpoint; enforces resource ownership policies" "Python middleware"
            inferenceProviders = container "Inference Provider Framework" "Multi-backend inference routing: vLLM, Bedrock, watsonx, Azure, Vertex AI, OpenAI" "Python providers"
            embeddingProviders = container "Embedding Provider Framework" "Text embedding via vLLM or inline sentence-transformers (granite-embedding-125m-english)" "Python providers"
            vectorProviders = container "Vector I/O Provider Framework" "Vector database operations: Milvus, FAISS, pgvector, Qdrant" "Python providers"
            toolRuntime = container "Tool Runtime" "External tool invocation: Brave Search, Tavily Search, MCP servers" "Python providers"
            agentOrchestrator = container "Agent Orchestrator" "Multi-turn agentic responses with tool use and conversation management" "Python (inline::builtin)"
        }

        rhoaiGateway = softwareSystem "RHOAI Gateway" "Platform ingress with TLS termination and auth enforcement (Envoy + kube-rbac-proxy)" "Platform"
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for KV store, inference logs, agent state, conversations, batches, files metadata, connectors" "Required"
        vllmInference = softwareSystem "vLLM Inference Server" "Primary LLM inference backend (OpenAI-compatible API)" "Internal"
        vllmEmbedding = softwareSystem "vLLM Embedding Server" "Text embedding generation server (OpenAI-compatible API)" "Internal"

        awsBedrock = softwareSystem "AWS Bedrock" "Remote LLM inference service" "Cloud Provider"
        ibmWatsonx = softwareSystem "IBM watsonx" "Remote LLM inference service" "Cloud Provider"
        azureOpenAI = softwareSystem "Azure OpenAI" "Remote LLM inference service" "Cloud Provider"
        googleVertexAI = softwareSystem "Google Vertex AI" "Remote LLM inference service" "Cloud Provider"
        openaiAPI = softwareSystem "OpenAI API" "Remote LLM inference service" "Cloud Provider"

        milvus = softwareSystem "Milvus" "Remote vector database" "Optional"
        pgvector = softwareSystem "pgvector" "Vector search via PostgreSQL extension" "Optional"
        qdrant = softwareSystem "Qdrant" "Remote vector database" "Optional"

        s3 = softwareSystem "S3 / S3-compatible Storage" "File and model artifact storage" "External"
        braveSearch = softwareSystem "Brave Search API" "Web search tool" "External"
        tavilySearch = softwareSystem "Tavily Search API" "Web search tool" "External"
        oidcProvider = softwareSystem "OAuth2 / OIDC Provider" "JWT token validation via JWKS endpoint" "External"
        otelCollector = softwareSystem "OTEL Collector" "OpenTelemetry traces and metrics receiver" "Optional"

        rhoaiOperator = softwareSystem "RHOAI Operator (rhods-operator)" "Deploys and manages OGX distribution on the platform" "Platform"

        # User interactions
        datascientist -> ogxDistribution "Sends inference, agentic, RAG, and vector requests" "HTTPS/443 via Gateway"
        platformadmin -> rhoaiOperator "Configures OGX deployment" "kubectl / RHOAI Dashboard"

        # Platform interactions
        rhoaiGateway -> ogxDistribution "Forwards authenticated requests" "HTTPS/8443 → HTTP/8321"
        rhoaiOperator -> ogxDistribution "Deploys container image" "Kubernetes API"

        # Required dependencies
        ogxDistribution -> postgresql "Stores KV data, inference logs, agent state, conversations" "TCP/5432, Username/Password"
        ogxDistribution -> vllmInference "Sends LLM inference requests" "HTTP(S), Bearer Token"
        ogxDistribution -> vllmEmbedding "Sends embedding requests" "HTTP(S), Bearer Token"

        # Optional cloud inference
        ogxDistribution -> awsBedrock "Remote LLM inference (conditional)" "HTTPS/443, Bearer Token"
        ogxDistribution -> ibmWatsonx "Remote LLM inference (conditional)" "HTTPS/443, API Key"
        ogxDistribution -> azureOpenAI "Remote LLM inference (conditional)" "HTTPS/443, API Key"
        ogxDistribution -> googleVertexAI "Remote LLM inference (conditional)" "HTTPS/443, ADC"
        ogxDistribution -> openaiAPI "Remote LLM inference (conditional)" "HTTPS/443, API Key"

        # Optional vector databases
        ogxDistribution -> milvus "Vector search operations" "TCP, Token/mTLS"
        ogxDistribution -> pgvector "Vector search operations" "TCP/5432, Username/Password"
        ogxDistribution -> qdrant "Vector search operations" "HTTP/6333 or gRPC/6334, API Key"

        # Optional external services
        ogxDistribution -> s3 "File storage and retrieval" "HTTPS/443, AWS IAM"
        ogxDistribution -> braveSearch "Web search tool invocation" "HTTPS/443, API Key"
        ogxDistribution -> tavilySearch "Web search tool invocation" "HTTPS/443, API Key"
        ogxDistribution -> oidcProvider "JWT token validation (JWKS)" "HTTPS/443"
        ogxDistribution -> otelCollector "Export traces and metrics" "OTLP/HTTP"
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
            element "Platform" {
                background #ffe6cc
                color #333333
            }
            element "Required" {
                background #82b366
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #333333
            }
            element "Cloud Provider" {
                background #9673a6
                color #ffffff
            }
            element "Optional" {
                background #d6b656
                color #333333
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

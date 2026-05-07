workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and deploys ML models, runs inference and evaluation"
        mlEngineer = person "ML Engineer" "Configures and manages AI service deployments"
        securityEngineer = person "Security Engineer" "Reviews and monitors AI safety guardrails"

        # Main System
        llamaStack = softwareSystem "ogx-distribution (Llama Stack)" "Llama Stack AI inference server providing OpenAI-compatible APIs, RAG, safety, evaluation, and multi-provider inference" {
            apiLayer = container "API Layer" "HTTP REST endpoints: /v1/inference, /v1/safety, /v1/vector_io, /v1/eval, /v1/files, /v1/responses, /v1/batches, /v1/scoring, /v1/tool_runtime, /v1/datasetio" "FastAPI/Uvicorn on UBI 9 Python 3.12" "WebApp"
            authMiddleware = container "OAuth2 Auth Middleware" "Validates JWT tokens against OIDC JWKS endpoint, enforces owner-based access control" "Built-in Llama Stack auth" "Component"
            providerFramework = container "Provider Framework" "Conditional provider activation via env vars; routes requests to appropriate backends" "Llama Stack Providers" "Component"
            kvStore = container "KV Store Client" "Key-value storage for metadata registry and provider state" "kv_postgres" "Component"
            sqlStore = container "SQL Store Client" "Structured storage for inference logs, agent responses, conversations, file metadata" "sql_postgres" "Component"
            embeddedModels = container "Embedded Models" "Pre-cached granite-embedding-125m-english and tiktoken cl100k_base" "HuggingFace/tiktoken" "Component"
            configYaml = container "Configuration" "distribution/config.yaml defining APIs, providers, storage, auth, telemetry" "YAML" "Component"
        }

        # Internal Platform Dependencies
        vllm = softwareSystem "vLLM Serving Runtime" "LLM and embedding model serving via OpenAI-compatible API" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Persistent storage backend for KV store and SQL store" "Internal RHOAI"
        trustyaiFMS = softwareSystem "TrustyAI FMS Orchestrator" "AI safety guardrails and content filtering" "Internal RHOAI"
        trustyaiLMEval = softwareSystem "TrustyAI LMEval" "LLM evaluation via lm-evaluation-harness" "Internal RHOAI"
        kubeflow = softwareSystem "Kubeflow Pipelines" "Remote RAGAS and Garak evaluation pipeline execution" "Internal RHOAI"
        platformIngress = softwareSystem "Platform Ingress" "Gateway API / HTTPRoute for TLS termination and external access" "Internal RHOAI"

        # External Vector Databases
        milvus = softwareSystem "Milvus" "Remote vector database for RAG operations" "External"
        qdrant = softwareSystem "Qdrant" "Remote vector database for RAG operations" "External"
        pgvector = softwareSystem "pgvector" "Vector database via PostgreSQL extension" "External"

        # External Cloud LLM Providers
        awsBedrock = softwareSystem "AWS Bedrock" "Remote LLM inference via AWS" "External Cloud"
        azureOpenAI = softwareSystem "Azure OpenAI" "Remote LLM inference via Azure" "External Cloud"
        vertexAI = softwareSystem "Google Vertex AI" "Remote LLM inference via Google Cloud" "External Cloud"
        openai = softwareSystem "OpenAI API" "Remote LLM inference via OpenAI" "External Cloud"
        watsonx = softwareSystem "IBM WatsonX" "Remote LLM inference via IBM" "External Cloud"

        # External Services
        s3 = softwareSystem "S3-compatible Storage" "Model artifacts and file storage" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Dataset loading and model downloads" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Traces and metrics export" "External"
        oidcProvider = softwareSystem "OAuth2/OIDC Provider" "JWT validation via JWKS endpoint" "External"

        # Tool Services
        braveSearch = softwareSystem "Brave Search API" "Web search tool runtime" "External"
        tavilySearch = softwareSystem "Tavily Search API" "Web search tool runtime" "External"
        mcpServers = softwareSystem "MCP Servers" "External tool integration via Model Context Protocol" "External"

        # Relationships - Users
        dataScientist -> llamaStack "Submits inference requests, runs evaluations" "HTTPS/443 (via ingress)"
        mlEngineer -> llamaStack "Configures providers, manages models" "HTTPS/443 (via ingress)"
        securityEngineer -> llamaStack "Reviews safety guardrail results" "HTTPS/443 (via ingress)"

        # Relationships - Ingress
        platformIngress -> llamaStack "Routes requests, terminates TLS" "HTTP/8321"

        # Relationships - Internal Components
        apiLayer -> authMiddleware "Validates requests"
        authMiddleware -> providerFramework "Routes authenticated requests"
        providerFramework -> kvStore "Stores/retrieves metadata"
        providerFramework -> sqlStore "Stores/retrieves structured data"
        providerFramework -> embeddedModels "Uses cached embedding model"

        # Relationships - Internal Platform
        llamaStack -> vllm "LLM inference and embedding requests" "HTTP/HTTPS, API Token"
        llamaStack -> postgresql "KV store and SQL store operations" "PostgreSQL/5432, Username/Password"
        llamaStack -> trustyaiFMS "Safety guardrails and content filtering" "HTTP/HTTPS, in-cluster"
        llamaStack -> trustyaiLMEval "LLM evaluation" "HTTP/HTTPS, in-cluster"
        llamaStack -> kubeflow "Remote evaluation pipelines" "HTTP/HTTPS, API Token"

        # Relationships - Vector Databases
        llamaStack -> milvus "Vector similarity search (RAG)" "HTTP/HTTPS, mTLS + Token"
        llamaStack -> qdrant "Vector similarity search (RAG)" "HTTP/6333, gRPC/6334, API Key"
        llamaStack -> pgvector "Vector similarity search (RAG)" "PostgreSQL/5432, Username/Password"

        # Relationships - Cloud Providers
        llamaStack -> awsBedrock "Remote LLM inference" "HTTPS/443, Bearer Token"
        llamaStack -> azureOpenAI "Remote LLM inference" "HTTPS/443, API Key"
        llamaStack -> vertexAI "Remote LLM inference" "HTTPS/443, ADC"
        llamaStack -> openai "Remote LLM inference" "HTTPS/443, API Key"
        llamaStack -> watsonx "Remote LLM inference" "HTTPS/443, API Key"

        # Relationships - External Services
        llamaStack -> s3 "File and model artifact storage" "HTTPS/443, AWS IAM"
        llamaStack -> huggingface "Dataset loading" "HTTPS/443"
        llamaStack -> otelCollector "Traces and metrics" "HTTP OTLP"
        llamaStack -> oidcProvider "JWKS key retrieval for auth" "HTTPS/443"
        llamaStack -> braveSearch "Web search queries" "HTTPS/443, API Key"
        llamaStack -> tavilySearch "Web search queries" "HTTPS/443, API Key"
        llamaStack -> mcpServers "External tool calls" "HTTP/HTTPS"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
            }
            element "External Cloud" {
                background #ff8c00
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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
            element "WebApp" {
                shape WebBrowser
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

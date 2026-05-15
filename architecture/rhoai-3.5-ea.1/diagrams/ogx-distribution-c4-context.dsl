workspace {
    model {
        user = person "Data Scientist / Application Developer" "Creates AI-powered applications using chat completion, embedding, and agentic APIs"

        ogxDistribution = softwareSystem "OGX Distribution (odh-ogx-core)" "Multi-provider AI inference gateway with OpenAI-compatible API, routing requests to configurable inference backends" {
            ogxServer = container "OGX Server" "FastAPI/Uvicorn application exposing OpenAI-compatible REST API on port 8321/TCP. Routes inference requests to configured providers." "Python 3.12, FastAPI"
            configYaml = container "config.yaml" "Runtime configuration declaring APIs, providers, storage backends, auth, and telemetry" "YAML Configuration"
            buildPy = container "build.py" "Code generator that produces Containerfile, install-deps.sh, and config.yaml from build.yaml manifest" "Python Build Tool"
            entrypoint = container "entrypoint.sh" "Launches OGX server with optional OpenTelemetry instrumentation" "Shell Script"
        }

        # Inference Providers
        vllm = softwareSystem "vLLM" "Primary LLM inference backend for chat completion and embedding" "Internal"
        bedrock = softwareSystem "AWS Bedrock" "Remote LLM inference provider (Llama, GPT-OSS models)" "External Cloud"
        vertexAI = softwareSystem "Google Vertex AI" "Remote LLM inference provider (Gemini models)" "External Cloud"
        azureOpenAI = softwareSystem "Azure OpenAI" "Remote LLM inference provider" "External Cloud"
        watsonx = softwareSystem "IBM watsonx" "Remote LLM inference provider" "External Cloud"
        openai = softwareSystem "OpenAI API" "Remote LLM inference provider" "External Cloud"

        # Storage
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for KV store, SQL store, inference logs, conversations, metadata, agent state, batch processing" "Database"

        # Vector Databases
        milvus = softwareSystem "Milvus" "Remote vector database for RAG workloads" "External"
        pgvector = softwareSystem "pgvector" "PostgreSQL-based vector database for RAG" "External"
        qdrant = softwareSystem "Qdrant" "Remote vector database for RAG workloads" "External"

        # Tool Services
        s3 = softwareSystem "S3 Storage" "File storage for file search tool" "External Cloud"
        braveSearch = softwareSystem "Brave Search API" "Web search tool runtime for agentic responses" "External Cloud"
        tavilySearch = softwareSystem "Tavily Search API" "Web search tool runtime for agentic responses" "External Cloud"

        # Platform
        rhoaiOperator = softwareSystem "RHOAI Platform Operator" "Deploys and manages OGX pods, configures ingress, manages secrets" "Internal RHOAI"
        konflux = softwareSystem "Konflux" "CI/CD system providing Tekton pipelines for container image builds" "Internal"
        rhoaiPyPI = softwareSystem "RHOAI PyPI Index" "Internal package registry at packages.redhat.com for OGX Python packages" "Internal"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository for downloading embedding models at build time" "External Cloud"

        # Relationships - User
        user -> ogxDistribution "Sends chat completion, embedding, and agentic requests via OpenAI-compatible API" "HTTP/8321"

        # Relationships - Internal
        entrypoint -> ogxServer "Starts"
        ogxServer -> configYaml "Loads at startup"
        buildPy -> configYaml "Generates"

        # Relationships - Inference
        ogxDistribution -> vllm "Forwards inference and embedding requests" "HTTP/HTTPS, Bearer Token"
        ogxDistribution -> bedrock "Remote LLM inference" "HTTPS/443, Bearer Token"
        ogxDistribution -> vertexAI "Remote LLM inference" "HTTPS/443, ADC"
        ogxDistribution -> azureOpenAI "Remote LLM inference" "HTTPS/443, API key"
        ogxDistribution -> watsonx "Remote LLM inference" "HTTPS/443, API key"
        ogxDistribution -> openai "Remote LLM inference" "HTTPS/443, API key"

        # Relationships - Storage
        ogxDistribution -> postgresql "Persists state, logs, conversations" "PostgreSQL/5432, password"

        # Relationships - Vector DBs
        ogxDistribution -> milvus "Vector storage/search for RAG" "TCP, Token"
        ogxDistribution -> pgvector "Vector storage/search for RAG" "PostgreSQL/5432, password"
        ogxDistribution -> qdrant "Vector storage/search for RAG" "HTTP/6333 + gRPC/6334, API key"

        # Relationships - Tools
        ogxDistribution -> s3 "File storage for file search" "HTTPS/443, AWS IAM"
        ogxDistribution -> braveSearch "Web search tool execution" "HTTPS/443, API key"
        ogxDistribution -> tavilySearch "Web search tool execution" "HTTPS/443, API key"

        # Relationships - Platform (build-time)
        konflux -> ogxDistribution "Builds container image via Tekton pipelines"
        ogxDistribution -> rhoaiPyPI "Downloads OGX Python packages" "HTTPS/443"
        ogxDistribution -> huggingface "Downloads embedding models (build-time)" "HTTPS/443"
        rhoaiOperator -> ogxDistribution "Deploys and manages"
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
                background #438DD5
                color #ffffff
            }
            element "External Cloud" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Internal RHOAI" {
                background #4a90e2
                color #ffffff
            }
            element "Database" {
                background #f5a623
                color #ffffff
                shape Cylinder
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
        }
    }
}

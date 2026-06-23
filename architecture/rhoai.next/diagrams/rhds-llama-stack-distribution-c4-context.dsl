workspace {
    model {
        datascientist = person "Data Scientist" "Builds and deploys AI applications using Llama Stack APIs"
        developer = person "Application Developer" "Integrates Llama Stack into applications via OpenAI-compatible API"

        llamastack = softwareSystem "Llama Stack Distribution" "Pre-built container providing Llama Stack server with Red Hat-curated providers for inference, evaluation, safety, vector I/O, and agentic workflows" {
            server = container "Llama Stack Server" "HTTP API server implementing Llama Stack protocol with OpenAI-compatible endpoints" "Python / FastAPI / Uvicorn" "Service"
            distroConfig = container "Distribution Config" "Declarative provider configuration mapping each API to provider implementations" "YAML" "Configuration"
            entrypoint = container "Entrypoint Script" "Launches server with optional OpenTelemetry instrumentation" "Shell" "Script"
            embeddingModel = container "Embedded Model" "Pre-downloaded granite-embedding-125m-english for offline embeddings" "sentence-transformers" "Model"

            entrypoint -> server "Launches"
            distroConfig -> server "Configures providers"
            server -> embeddingModel "Uses for inline embeddings"
        }

        # Internal Platform Dependencies
        vllm = softwareSystem "vLLM" "Primary inference backend for LLM chat and embeddings" "Internal Platform"
        trustyaiFMS = softwareSystem "TrustyAI FMS Orchestrator" "Content safety shield evaluation" "Internal Platform"
        trustyaiLMEval = softwareSystem "TrustyAI LM-Eval" "Model evaluation with LM-Eval harness" "Internal Platform"
        kubeflow = softwareSystem "Kubeflow Pipelines" "Remote evaluation orchestration for RAGAS and Garak benchmarks" "Internal Platform"
        milvus = softwareSystem "Milvus" "Remote vector database for RAG" "Internal Platform"
        pgvector = softwareSystem "PgVector" "PostgreSQL-based vector database" "Internal Platform"
        qdrant = softwareSystem "Qdrant" "Remote vector database" "Internal Platform"

        # External Dependencies
        postgresql = softwareSystem "PostgreSQL" "Persistent KV and SQL storage for agent state, inference logs, metadata" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Remote file and model artifact storage" "External"
        awsBedrock = softwareSystem "AWS Bedrock" "Remote LLM inference via AWS" "External Cloud"
        googleVertex = softwareSystem "Google Vertex AI" "Remote LLM inference via Google Cloud" "External Cloud"
        azureOpenAI = softwareSystem "Azure OpenAI" "Remote LLM inference via Azure" "External Cloud"
        ibmWatsonx = softwareSystem "IBM watsonx" "Remote LLM inference via IBM" "External Cloud"
        openai = softwareSystem "OpenAI API" "Remote LLM inference via OpenAI" "External Cloud"
        braveSearch = softwareSystem "Brave Search API" "Web search tool for agents" "External"
        tavilySearch = softwareSystem "Tavily Search API" "Web search tool for agents" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Dataset and model downloads" "External"
        otelCollector = softwareSystem "OTEL Collector" "Telemetry export for traces and metrics" "External"

        # Platform Infrastructure
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Platform-injected sidecar for authentication and authorization" "Platform Infrastructure"

        # Relationships - Users
        datascientist -> llamastack "Submits inference, evaluation, and agent requests" "HTTP/8321"
        developer -> llamastack "Calls OpenAI-compatible chat/completions API" "HTTP/8321"

        # Relationships - Platform Auth
        datascientist -> kubeRbacProxy "Authenticates via OAuth/OIDC" "HTTPS"
        developer -> kubeRbacProxy "Authenticates via OAuth/OIDC" "HTTPS"
        kubeRbacProxy -> llamastack "Forwards authenticated requests" "HTTP/8321"

        # Relationships - Internal Platform
        llamastack -> vllm "Sends inference and embedding requests" "HTTPS, Bearer token"
        llamastack -> trustyaiFMS "Sends content for safety evaluation" "HTTPS, custom cert"
        llamastack -> trustyaiLMEval "Submits model evaluation jobs" "HTTP/HTTPS"
        llamastack -> kubeflow "Orchestrates RAGAS and Garak evaluation pipelines" "HTTPS/TLS 1.2+, Bearer token"
        llamastack -> milvus "Stores and queries vectors for RAG" "HTTPS, Token"
        llamastack -> pgvector "Stores and queries vectors" "PostgreSQL/5432"
        llamastack -> qdrant "Stores and queries vectors" "REST-gRPC/6333-6334"

        # Relationships - External
        llamastack -> postgresql "Persists agent state, inference logs, metadata" "PostgreSQL/5432"
        llamastack -> s3 "Stores and retrieves files and model artifacts" "HTTPS/443, AWS IAM"
        llamastack -> awsBedrock "Remote inference requests" "HTTPS/443, Bearer token"
        llamastack -> googleVertex "Remote inference requests" "HTTPS/443, OAuth2"
        llamastack -> azureOpenAI "Remote inference requests" "HTTPS/443, API key"
        llamastack -> ibmWatsonx "Remote inference requests" "HTTPS/443, API key"
        llamastack -> openai "Remote inference requests" "HTTPS/443, API key"
        llamastack -> braveSearch "Web search for agent tools" "HTTPS/443, API key"
        llamastack -> tavilySearch "Web search for agent tools" "HTTPS/443, API key"
        llamastack -> huggingface "Downloads datasets and models" "HTTPS/443"
        llamastack -> otelCollector "Exports traces and metrics" "OTLP/HTTPS"
    }

    views {
        systemContext llamastack "SystemContext" {
            include *
            autoLayout
        }

        container llamastack "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Cloud" {
                background #f5a623
                color #ffffff
            }
            element "Platform Infrastructure" {
                background #d79b00
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
            element "Configuration" {
                background #85bbf0
                color #000000
                shape Folder
            }
            element "Script" {
                background #85bbf0
                color #000000
            }
            element "Model" {
                background #6c8ebf
                color #ffffff
                shape Cylinder
            }
            element "Service" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models, runs evaluations, and builds AI agents"
        mlEngineer = person "ML Engineer" "Configures inference backends, vector databases, and safety shields"

        llamaStack = softwareSystem "Llama Stack Distribution" "Multi-provider AI inference, evaluation, agent orchestration, and safety platform" {
            server = container "Llama Stack Server" "FastAPI/Uvicorn service exposing OpenAI-compatible REST APIs for inference, agents, eval, safety, vector-io, tool-runtime, scoring, and batch operations" "Python 3.12 / FastAPI"
            config = container "Distribution Config" "Defines all 10 APIs, provider mappings, storage backends, registered resources, and server settings" "YAML (config.yaml)"
            entrypoint = container "Entrypoint Script" "Starts Llama Stack server with optional OpenTelemetry instrumentation wrapper" "Shell Script"
            inlineEmbedding = container "Sentence Transformers" "Inline embedding model provider (granite-embedding-125m-english)" "Python / PyTorch CPU"
            milvusLite = container "Milvus Lite" "Inline vector database for local development and testing" "Python / milvus-lite"
            faiss = container "FAISS" "CPU-based inline vector database" "Python / FAISS"
        }

        vllm = softwareSystem "vLLM Serving Runtime" "Primary inference backend for LLM and embedding model serving" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Persistent storage backend for KV store, SQL store, inference logs, agent state, and file metadata" "Internal"
        trustyaiFMS = softwareSystem "TrustyAI FMS Orchestrator" "Safety shield evaluation for content moderation" "Internal RHOAI"
        trustyaiLMEval = softwareSystem "TrustyAI LMEval" "LLM evaluation job orchestration via Kubernetes Jobs" "Internal RHOAI"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Remote RAGAS and Garak evaluation pipeline execution" "Internal RHOAI"
        platformOperator = softwareSystem "RHODS Operator" "Platform operator managing deployment, RBAC, ingress, and lifecycle" "Internal RHOAI"

        awsBedrock = softwareSystem "AWS Bedrock" "Remote LLM inference via AWS Bedrock" "External Cloud"
        ibmWatsonX = softwareSystem "IBM WatsonX" "Remote LLM inference via WatsonX" "External Cloud"
        azureOpenAI = softwareSystem "Azure OpenAI" "Remote LLM inference via Azure" "External Cloud"
        googleVertex = softwareSystem "Google Vertex AI" "Remote LLM inference via Vertex AI" "External Cloud"
        openai = softwareSystem "OpenAI API" "Remote LLM inference via OpenAI" "External Cloud"

        milvusRemote = softwareSystem "Milvus (Remote)" "Remote vector database (REST/gRPC)" "External/Internal"
        pgvector = softwareSystem "pgvector" "Vector database via PostgreSQL pgvector extension" "Internal"
        qdrant = softwareSystem "Qdrant" "Remote vector database (REST/gRPC)" "External/Internal"

        s3Storage = softwareSystem "S3-Compatible Storage" "Remote file storage and model artifacts" "External Cloud"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Dataset and model downloads" "External"
        braveSearch = softwareSystem "Brave Search API" "Web search tool runtime" "External"
        tavilySearch = softwareSystem "Tavily Search API" "Web search tool runtime" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics collection" "Internal"

        # Relationships - Users
        dataScientist -> llamaStack "Sends inference, agent, and eval requests via REST API" "HTTP/8321"
        mlEngineer -> platformOperator "Configures deployment and environment variables"
        platformOperator -> llamaStack "Deploys and manages lifecycle"

        # Relationships - Primary
        llamaStack -> vllm "Sends inference requests" "HTTP(S)/8000, Bearer Token"
        llamaStack -> postgresql "Persists KV/SQL data, logs, agent state" "PostgreSQL/5432, Password"

        # Relationships - Safety & Eval
        llamaStack -> trustyaiFMS "Evaluates safety shields" "HTTP(S), Configurable SSL"
        llamaStack -> trustyaiLMEval "Orchestrates LLM evaluation jobs" "K8s API, ServiceAccount"
        llamaStack -> kubeflowPipelines "Submits RAGAS/Garak evaluation pipelines" "HTTP, Bearer Token"

        # Relationships - Cloud Inference
        llamaStack -> awsBedrock "Remote inference" "HTTPS/443, Bearer Token"
        llamaStack -> ibmWatsonX "Remote inference" "HTTPS/443, API Key"
        llamaStack -> azureOpenAI "Remote inference" "HTTPS/443, API Key"
        llamaStack -> googleVertex "Remote inference" "HTTPS/443, Google ADC"
        llamaStack -> openai "Remote inference" "HTTPS/443, API Key"

        # Relationships - Vector DBs
        llamaStack -> milvusRemote "Vector search" "REST/gRPC, Token + mTLS"
        llamaStack -> pgvector "Vector search" "PostgreSQL/5432, Password"
        llamaStack -> qdrant "Vector search" "REST(6333)/gRPC(6334), API Key"

        # Relationships - External Services
        llamaStack -> s3Storage "File storage" "HTTPS/443, AWS IAM"
        llamaStack -> huggingFaceHub "Downloads datasets and models" "HTTPS/443"
        llamaStack -> braveSearch "Web search tool" "HTTPS/443, API Key"
        llamaStack -> tavilySearch "Web search tool" "HTTPS/443, API Key"
        llamaStack -> otelCollector "Exports traces and metrics" "HTTP OTLP/4318"
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
            element "External Cloud" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Internal" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #cccccc
                color #000000
            }
            element "External/Internal" {
                background #b8b8b8
                color #000000
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
        }
    }
}

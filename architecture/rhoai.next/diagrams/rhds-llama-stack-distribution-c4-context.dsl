workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys models and runs inference, evaluation, and agentic workflows"
        mlEngineer = person "ML Engineer" "Configures inference backends, safety shields, and evaluation pipelines"

        llamaStackDistro = softwareSystem "Llama Stack Distribution" "Unified API gateway for LLM inference, evaluation, safety, vector I/O, agents, and tool runtime" {
            server = container "Llama Stack Server" "Unified API gateway exposing OpenAI-compatible and Llama Stack native APIs on port 8321/TCP" "Python / FastAPI / uvicorn"
            configYaml = container "config.yaml" "Provider-plugin configuration with environment-variable-driven provider activation" "YAML Configuration"
            entrypoint = container "entrypoint.sh" "Container startup script with optional OpenTelemetry instrumentation" "Shell Script"
            embeddingModel = container "granite-embedding-125m-english" "Pre-downloaded IBM Granite embedding model for inline embeddings" "Model Artifact"
        }

        vllm = softwareSystem "vLLM" "Primary LLM inference and embedding backend" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for kvstore, SQL, inference logs, agent state, conversations, prompts, file metadata, batches" "Internal"
        trustyaiFMS = softwareSystem "TrustyAI FMS Orchestrator" "Safety shield evaluation for content moderation" "Internal RHOAI"
        trustyaiLMEval = softwareSystem "TrustyAI LMEval" "Model evaluation using LM Evaluation Harness (via K8s Jobs)" "Internal RHOAI"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Pipeline orchestration for RAGAS and Garak evaluations" "Internal RHOAI"
        milvus = softwareSystem "Milvus" "Vector database for similarity search (remote or embedded lite mode)" "Internal"
        pgvector = softwareSystem "pgvector" "PostgreSQL-backed vector database" "Internal"
        qdrant = softwareSystem "Qdrant" "Vector database for similarity search" "External"
        s3 = softwareSystem "S3 / S3-compatible Storage" "File storage backend for model artifacts and data" "External"
        awsBedrock = softwareSystem "AWS Bedrock" "Remote LLM inference via AWS" "External Cloud"
        googleVertexAI = softwareSystem "Google Vertex AI" "Remote LLM inference via Google Cloud" "External Cloud"
        azureOpenAI = softwareSystem "Azure OpenAI" "Remote LLM inference via Azure" "External Cloud"
        ibmWatsonX = softwareSystem "IBM WatsonX" "Remote LLM inference via IBM" "External Cloud"
        openAI = softwareSystem "OpenAI" "Remote LLM inference via OpenAI" "External Cloud"
        braveSearch = softwareSystem "Brave Search API" "Web search tool for agentic workflows" "External"
        tavilySearch = softwareSystem "Tavily Search API" "Web search tool for agentic workflows" "External"
        mcpServers = softwareSystem "MCP Servers" "Model Context Protocol tool servers" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Dataset and model download" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API for creating evaluation Jobs" "Internal"
        otelCollector = softwareSystem "OTEL Collector" "OpenTelemetry traces and metrics collection" "Internal"

        # User interactions
        dataScientist -> llamaStackDistro "Runs inference, evaluation, and agentic workflows" "HTTP/8321"
        mlEngineer -> llamaStackDistro "Configures providers and backends" "HTTP/8321"

        # Internal container interactions
        server -> configYaml "Reads provider configuration"
        entrypoint -> server "Starts with optional OTEL instrumentation"
        server -> embeddingModel "Loads for inline embedding"

        # Primary inference backends
        llamaStackDistro -> vllm "LLM inference and embedding" "HTTP/HTTPS (Bearer Token)"
        llamaStackDistro -> awsBedrock "Remote LLM inference" "HTTPS/443 (Bearer Token)"
        llamaStackDistro -> googleVertexAI "Remote LLM inference" "HTTPS/443 (ADC)"
        llamaStackDistro -> azureOpenAI "Remote LLM inference" "HTTPS/443 (API Key)"
        llamaStackDistro -> ibmWatsonX "Remote LLM inference" "HTTPS/443 (API Key)"
        llamaStackDistro -> openAI "Remote LLM inference" "HTTPS/443 (API Key)"

        # Storage
        llamaStackDistro -> postgresql "Persistent state storage" "PostgreSQL/5432 (Password)"
        llamaStackDistro -> s3 "File storage" "HTTPS/443 (AWS IAM)"

        # Vector databases
        llamaStackDistro -> milvus "Vector similarity search" "HTTP/gRPC (Token + mTLS)"
        llamaStackDistro -> pgvector "Vector similarity search" "PostgreSQL (Password)"
        llamaStackDistro -> qdrant "Vector similarity search" "HTTP/gRPC (API Key)"

        # Safety and evaluation
        llamaStackDistro -> trustyaiFMS "Safety shield evaluation" "HTTP/HTTPS (SSL Cert)"
        llamaStackDistro -> trustyaiLMEval "Model evaluation" "HTTP"
        llamaStackDistro -> kubeflowPipelines "RAGAS/Garak evaluation pipelines" "HTTPS (Bearer Token)"
        llamaStackDistro -> kubernetesAPI "Create LMEval Jobs" "HTTPS/443 (SA Token)"

        # Tool runtimes
        llamaStackDistro -> braveSearch "Web search for agents" "HTTPS/443 (API Key)"
        llamaStackDistro -> tavilySearch "Web search for agents" "HTTPS/443 (API Key)"
        llamaStackDistro -> mcpServers "MCP tool execution" "HTTP/HTTPS"
        llamaStackDistro -> huggingFaceHub "Dataset/model download" "HTTPS/443"

        # Observability
        llamaStackDistro -> otelCollector "Traces and metrics export" "HTTP OTLP"
    }

    views {
        systemContext llamaStackDistro "SystemContext" {
            include *
            autoLayout
        }

        container llamaStackDistro "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal" {
                background #85bb65
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

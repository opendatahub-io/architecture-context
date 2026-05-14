workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys LLM-based applications, runs evaluations, builds agentic workflows"
        mlEngineer = person "ML Engineer" "Deploys and configures inference backends, manages model lifecycle"

        llamaStack = softwareSystem "Llama Stack Distribution" "Unified API gateway for LLM inference, evaluation, safety, vector I/O, agents, and tool runtime" {
            server = container "Llama Stack Server" "Unified API gateway implementing Llama Stack native and OpenAI-compatible APIs on port 8321" "Python/FastAPI/uvicorn"
            inferenceProviders = container "Inference Providers" "Provider plugins for vLLM, Bedrock, Vertex AI, Azure, WatsonX, OpenAI, sentence-transformers" "Python Plugin Architecture"
            vectorProviders = container "Vector I/O Providers" "Provider plugins for Milvus, FAISS, pgvector, Qdrant" "Python Plugin Architecture"
            safetyProviders = container "Safety & Eval Providers" "Provider plugins for TrustyAI FMS, LMEval, RAGAS, Garak" "Python Plugin Architecture"
            toolProviders = container "Tool Runtime Providers" "Provider plugins for Brave/Tavily search, RAG, MCP" "Python Plugin Architecture"
            configYaml = container "config.yaml" "Provider wiring configuration with env-var-driven activation" "YAML Configuration"
        }

        # Internal Platform Dependencies
        vllm = softwareSystem "vLLM" "Primary LLM inference and embedding backend" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for kvstore, SQL, inference logs, agent state, conversations" "Internal RHOAI"
        trustyaiFMS = softwareSystem "TrustyAI FMS Orchestrator" "Safety shield orchestration for content moderation" "Internal RHOAI"
        trustyaiLMEval = softwareSystem "TrustyAI LMEval" "Model evaluation via LM Evaluation Harness" "Internal RHOAI"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Pipeline orchestration for RAGAS and Garak evaluations" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API for creating evaluation Jobs" "Platform"
        otelCollector = softwareSystem "OTEL Collector" "OpenTelemetry traces and metrics collection" "Platform"

        # Vector Databases
        milvus = softwareSystem "Milvus" "Remote vector database for production vector search workloads" "Internal RHOAI"
        pgvector = softwareSystem "pgvector" "PostgreSQL-backed vector database" "Internal RHOAI"
        qdrant = softwareSystem "Qdrant" "High-performance vector database" "External"

        # External Cloud Services
        awsBedrock = softwareSystem "AWS Bedrock" "Remote LLM inference via AWS" "External Cloud"
        googleVertex = softwareSystem "Google Vertex AI" "Remote LLM inference via Google Cloud" "External Cloud"
        azureOpenAI = softwareSystem "Azure OpenAI" "Remote LLM inference via Azure" "External Cloud"
        ibmWatsonX = softwareSystem "IBM WatsonX" "Remote LLM inference via IBM" "External Cloud"
        openai = softwareSystem "OpenAI API" "Remote LLM inference via OpenAI" "External Cloud"
        s3 = softwareSystem "S3 Storage" "File storage backend (AWS S3 or compatible)" "External Cloud"
        huggingface = softwareSystem "HuggingFace Hub" "Dataset and model download" "External"
        braveSearch = softwareSystem "Brave Search API" "Web search tool for agentic workflows" "External"
        tavilySearch = softwareSystem "Tavily Search API" "Web search tool for agentic workflows" "External"

        # User interactions
        dataScientist -> llamaStack "Sends inference, RAG, evaluation, and agent requests via HTTP API"
        mlEngineer -> llamaStack "Configures providers via environment variables and config.yaml"

        # Internal container relationships
        server -> inferenceProviders "Routes inference requests to configured provider"
        server -> vectorProviders "Routes vector I/O requests to configured provider"
        server -> safetyProviders "Routes safety/eval requests to configured provider"
        server -> toolProviders "Routes tool runtime requests to configured provider"
        configYaml -> server "Provides provider wiring configuration"

        # Internal platform dependencies
        llamaStack -> vllm "LLM inference and embedding" "HTTP/HTTPS, Bearer Token"
        llamaStack -> postgresql "Persistent state storage" "PostgreSQL/5432"
        llamaStack -> trustyaiFMS "Safety shield evaluation" "HTTP/HTTPS"
        llamaStack -> trustyaiLMEval "Model evaluation" "HTTP + K8s Jobs"
        llamaStack -> kubeflowPipelines "RAGAS/Garak evaluation pipelines" "HTTPS/TLS 1.2+"
        llamaStack -> kubernetesAPI "Create evaluation Jobs" "HTTPS/443"
        llamaStack -> otelCollector "Export traces and metrics (optional)" "HTTP/OTLP"

        # Vector databases
        llamaStack -> milvus "Vector similarity search" "HTTP/gRPC, mTLS, Token"
        llamaStack -> pgvector "Vector search via PostgreSQL" "PostgreSQL"
        llamaStack -> qdrant "Vector similarity search" "HTTP/gRPC, API Key"

        # External cloud services
        llamaStack -> awsBedrock "Remote LLM inference" "HTTPS/443, Bearer Token (12h TTL)"
        llamaStack -> googleVertex "Remote LLM inference" "HTTPS/443, ADC"
        llamaStack -> azureOpenAI "Remote LLM inference" "HTTPS/443, API Key"
        llamaStack -> ibmWatsonX "Remote LLM inference" "HTTPS/443, API Key"
        llamaStack -> openai "Remote LLM inference" "HTTPS/443, API Key"
        llamaStack -> s3 "File storage" "HTTPS/443, AWS IAM"
        llamaStack -> huggingface "Dataset/model download" "HTTPS/443"
        llamaStack -> braveSearch "Web search for agents" "HTTPS/443, API Key"
        llamaStack -> tavilySearch "Web search for agents" "HTTPS/443, API Key"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Cloud" {
                background #e8842c
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

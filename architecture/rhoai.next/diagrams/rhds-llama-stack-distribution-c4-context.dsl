workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models, runs evaluations, and queries LLMs"
        developer = person "Application Developer" "Builds AI-powered applications using Llama Stack APIs"

        llamaStack = softwareSystem "Llama Stack Distribution" "Unified AI inference gateway aggregating multiple LLM backends, vector stores, evaluation frameworks, and tool runtimes behind a single REST API" {
            server = container "Llama Stack Server" "FastAPI/Uvicorn service serving unified REST API on port 8321" "Python 3.12"
            config = container "Distribution Config" "Defines all API providers, storage backends, and registered resources with env-based conditional activation" "YAML"
            embeddingModel = container "Embedded Granite Model" "ibm-granite/granite-embedding-125m-english model embedded at build time for inline embedding" "sentence-transformers"
        }

        # Internal Platform Dependencies
        vllm = softwareSystem "vLLM" "Primary on-cluster LLM inference and embedding server" "Internal RHOAI"
        trustyaiFMS = softwareSystem "TrustyAI FMS Orchestrator" "Safety evaluation and guardrails service" "Internal RHOAI"
        trustyaiLMEval = softwareSystem "TrustyAI LM Eval" "Model evaluation via LM Eval harness" "Internal RHOAI"
        kubeflow = softwareSystem "Kubeflow Pipelines" "Remote evaluation pipeline orchestration (RAGAS, Garak)" "Internal RHOAI"
        milvus = softwareSystem "Milvus" "Remote vector database for production RAG workloads" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Persistent state storage for KV store, inference logs, agent state, and file metadata" "Internal"

        # Cloud Inference Providers
        bedrock = softwareSystem "AWS Bedrock" "Cloud-hosted LLM inference via AWS" "External Cloud"
        watsonx = softwareSystem "IBM watsonx" "Cloud-hosted LLM inference via IBM" "External Cloud"
        azureOpenAI = softwareSystem "Azure OpenAI" "Cloud-hosted LLM inference via Azure" "External Cloud"
        vertexAI = softwareSystem "Google Vertex AI" "Cloud-hosted LLM inference via Google" "External Cloud"
        openai = softwareSystem "OpenAI" "Cloud-hosted LLM inference via OpenAI" "External Cloud"

        # Vector Databases
        pgvector = softwareSystem "pgvector" "PostgreSQL-based vector database" "External"
        qdrant = softwareSystem "Qdrant" "Remote vector database" "External"

        # Tool Runtimes & Data Services
        braveSearch = softwareSystem "Brave Search API" "Web search tool runtime for agents" "External SaaS"
        tavilySearch = softwareSystem "Tavily Search API" "Web search tool runtime for agents" "External SaaS"
        huggingface = softwareSystem "HuggingFace Hub" "Dataset downloads for evaluation" "External SaaS"
        s3 = softwareSystem "S3-compatible Storage" "File storage backend for model artifacts and results" "External Cloud"
        mcpServers = softwareSystem "MCP Servers" "Model Context Protocol tool integration" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry traces and metrics collection" "Internal"

        # Relationships
        datascientist -> llamaStack "Runs evaluations, queries models via REST API"
        developer -> llamaStack "Builds apps using /v1/chat/completions, /v1/agents, etc."

        llamaStack -> vllm "Inference and embedding requests" "HTTP/HTTPS, Bearer Token"
        llamaStack -> bedrock "LLM inference" "HTTPS/443, Bearer Token"
        llamaStack -> watsonx "LLM inference" "HTTPS/443, API Key"
        llamaStack -> azureOpenAI "LLM inference" "HTTPS/443, API Key"
        llamaStack -> vertexAI "LLM inference" "HTTPS/443, Google ADC"
        llamaStack -> openai "LLM inference" "HTTPS/443, API Key"

        llamaStack -> postgresql "KV store, inference logs, agent state" "PostgreSQL/5432, Password"
        llamaStack -> milvus "Vector similarity search for RAG" "HTTP/HTTPS, Token"
        llamaStack -> pgvector "Vector database queries" "PostgreSQL, Password"
        llamaStack -> qdrant "Vector database queries" "HTTP/gRPC 6333-6334, API Key"

        llamaStack -> trustyaiFMS "Safety guardrail evaluation" "HTTPS, Custom TLS Cert"
        llamaStack -> trustyaiLMEval "Model evaluation" "HTTP"
        llamaStack -> kubeflow "Remote evaluation pipelines (RAGAS, Garak)" "HTTP/HTTPS, Bearer Token"

        llamaStack -> braveSearch "Web search for agents" "HTTPS/443, API Key"
        llamaStack -> tavilySearch "Web search for agents" "HTTPS/443, API Key"
        llamaStack -> huggingface "Dataset downloads" "HTTPS/443"
        llamaStack -> s3 "File storage" "HTTPS/443, AWS IAM"
        llamaStack -> mcpServers "Tool integration" "HTTP/HTTPS"
        llamaStack -> otlpCollector "Traces and metrics export" "HTTP"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External Cloud" {
                background #e1d5e7
                color #333333
            }
            element "External SaaS" {
                background #f8cecc
                color #333333
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #50e3c2
                color #333333
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
        }
    }
}

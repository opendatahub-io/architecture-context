workspace {
    model {
        datascientist = person "Data Scientist" "Creates AI applications using Llama Stack APIs"
        developer = person "Application Developer" "Builds generative AI applications against OpenAI-compatible API"

        llamastack = softwareSystem "Llama Stack Distribution" "Red Hat-supported Llama Stack server providing OpenAI-compatible HTTP API for inference, agents, RAG, safety, and evaluation" {
            server = container "Llama Stack Server" "Serves HTTP API on port 8321 with environment-variable-driven provider activation" "Python / llama-stack v0.5.0+rhai0"
            configYaml = container "Configuration" "Declares APIs, providers, storage backends, registered resources, and server settings" "YAML"
            embeddingModel = container "Embedded Model" "Pre-downloaded ibm-granite/granite-embedding-125m-english for local embeddings" "sentence-transformers"
        }

        # Internal Platform Dependencies
        vllm = softwareSystem "vLLM Serving Runtime" "Primary LLM inference backend for chat completions and embeddings" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "Safety shield evaluation (FMS orchestrator) and LM evaluation (lmeval, RAGAS, Garak)" "Internal RHOAI"
        kubeflow = softwareSystem "Kubeflow Pipelines" "Remote evaluation job orchestration for RAGAS and Garak benchmarks" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for agent state, inference logs, file metadata, KV store" "Internal Platform"

        # External Cloud Inference Providers
        bedrock = softwareSystem "AWS Bedrock" "Remote inference provider for AWS-hosted models" "External Cloud"
        watsonx = softwareSystem "IBM Watsonx" "Remote inference provider for IBM-hosted models" "External Cloud"
        azureai = softwareSystem "Azure AI" "Remote inference provider for Azure-hosted models" "External Cloud"
        vertexai = softwareSystem "Google Vertex AI" "Remote inference provider for Google-hosted models" "External Cloud"
        openai = softwareSystem "OpenAI API" "Remote inference provider for OpenAI models" "External Cloud"

        # Vector Databases
        milvus = softwareSystem "Milvus" "Vector database for similarity search (inline lite or remote)" "External"
        pgvector = softwareSystem "pgvector" "PostgreSQL-based vector database" "External"
        qdrant = softwareSystem "Qdrant" "Vector database for similarity search" "External"

        # External Services
        s3 = softwareSystem "S3 Storage" "Model artifact and file storage, evaluation results" "External Cloud"
        hfhub = softwareSystem "HuggingFace Hub" "Model and dataset downloads" "External"
        brave = softwareSystem "Brave Search API" "Web search tool runtime" "External"
        tavily = softwareSystem "Tavily Search API" "Web search tool runtime" "External"
        mcpservers = softwareSystem "MCP Servers" "External tool servers via Model Context Protocol" "External"
        otelcollector = softwareSystem "OpenTelemetry Collector" "Traces and metrics export target" "External"

        # User relationships
        datascientist -> llamastack "Creates AI applications, runs evaluations via" "HTTP/8321"
        developer -> llamastack "Sends chat completions, manages agents via" "HTTP/8321"

        # Internal platform integrations
        llamastack -> vllm "Inference requests (chat completions, embeddings)" "HTTP(S)/8000, API token"
        llamastack -> postgresql "KV store, SQL tables (agent state, logs, metadata)" "PostgreSQL/5432, username/password"
        llamastack -> trustyai "Safety shield evaluation, LM evaluation" "HTTPS, custom TLS cert"
        llamastack -> kubeflow "Remote evaluation pipelines (RAGAS, Garak)" "HTTPS, API token"

        # Cloud inference providers
        llamastack -> bedrock "Remote LLM inference" "HTTPS/443, Bearer token"
        llamastack -> watsonx "Remote LLM inference" "HTTPS/443, API key"
        llamastack -> azureai "Remote LLM inference" "HTTPS/443, API key"
        llamastack -> vertexai "Remote LLM inference" "HTTPS/443, OAuth2"
        llamastack -> openai "Remote LLM inference" "HTTPS/443, API key"

        # Vector databases
        llamastack -> milvus "Vector similarity search" "gRPC/HTTP, TLS, Token"
        llamastack -> pgvector "Vector similarity search" "PostgreSQL/5432"
        llamastack -> qdrant "Vector similarity search" "HTTP-gRPC/6333-6334, API key"

        # External services
        llamastack -> s3 "File storage, evaluation artifacts" "HTTPS/443, AWS IAM"
        llamastack -> hfhub "Dataset and model downloads" "HTTPS/443"
        llamastack -> brave "Web search tool" "HTTPS/443, API key"
        llamastack -> tavily "Web search tool" "HTTPS/443, API key"
        llamastack -> mcpservers "External tool invocations" "HTTP, configurable"
        llamastack -> otelcollector "Traces and metrics" "HTTP OTLP"

        # Kubeflow to S3
        kubeflow -> s3 "Evaluation result storage" "HTTPS/443, AWS IAM"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #f5a623
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

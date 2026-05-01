workspace {
    model {
        user = person "Data Scientist / Developer" "Creates inference requests, evaluations, RAG queries, and agent sessions"

        llamaStack = softwareSystem "Llama Stack Distribution" "Multi-provider AI orchestration server exposing inference, agents, eval, safety, vector_io, and tool_runtime APIs" {
            server = container "Llama Stack Server" "FastAPI/Uvicorn HTTP server on port 8321/TCP" "Python 3.12"
            config = container "Distribution Config" "Defines APIs, provider mappings, storage backends, registered resources" "YAML (config.yaml)"
            entrypoint = container "Entrypoint Script" "Starts server with optional OpenTelemetry instrumentation" "Shell Script"
            inlineProviders = container "Inline Providers" "Milvus Lite, FAISS, Sentence Transformers, RAGAS inline" "Python Libraries"
        }

        // Internal Platform Dependencies
        vllm = softwareSystem "vLLM Serving Runtime" "Primary inference backend for LLM and embedding model serving" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL 17+" "Persistent storage: KV store, SQL store, inference logs, agent state" "Internal"
        trustyaiFMS = softwareSystem "TrustyAI FMS Orchestrator" "Safety shield evaluation for content moderation" "Internal RHOAI"
        trustyaiLMEval = softwareSystem "TrustyAI LMEval" "LLM evaluation job orchestration via Kubernetes Jobs" "Internal RHOAI"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Remote RAGAS and Garak evaluation pipeline execution" "Internal RHOAI"
        platformOperator = softwareSystem "rhods-operator" "Manages deployment, ingress, and auth for Llama Stack" "Internal RHOAI"

        // Cloud Inference Backends
        awsBedrock = softwareSystem "AWS Bedrock" "Remote inference via AWS-hosted models" "External Cloud"
        watsonx = softwareSystem "IBM WatsonX" "Remote inference via WatsonX-hosted models" "External Cloud"
        azureOpenAI = softwareSystem "Azure OpenAI" "Remote inference via Azure-hosted models" "External Cloud"
        vertexAI = softwareSystem "Google Vertex AI" "Remote inference via Vertex AI models" "External Cloud"
        openai = softwareSystem "OpenAI API" "Remote inference via OpenAI models" "External Cloud"

        // Vector Databases
        milvusRemote = softwareSystem "Milvus (Remote)" "Remote vector database" "External/Internal"
        pgvector = softwareSystem "pgvector" "Vector database via PostgreSQL extension" "Internal"
        qdrant = softwareSystem "Qdrant" "Remote vector database" "External/Internal"

        // External Services
        s3 = softwareSystem "S3-compatible Storage" "File storage backend" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset downloads" "External"
        braveSearch = softwareSystem "Brave Search API" "Web search tool runtime" "External"
        tavilySearch = softwareSystem "Tavily Search API" "Web search tool runtime" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics" "Internal"

        // Relationships
        user -> llamaStack "Sends inference, eval, safety, RAG requests" "HTTP/8321"
        platformOperator -> llamaStack "Deploys and manages ingress/auth"

        llamaStack -> vllm "LLM inference and embedding requests" "HTTP(S)/8000, Bearer Token"
        llamaStack -> postgresql "Persistent KV/SQL storage" "PostgreSQL/5432, Password"
        llamaStack -> trustyaiFMS "Safety shield evaluation" "HTTP(S), configurable SSL"
        llamaStack -> trustyaiLMEval "LLM evaluation jobs" "K8s API, SA token"
        llamaStack -> kubeflowPipelines "Remote eval pipelines" "HTTP, Bearer Token"

        llamaStack -> awsBedrock "Cloud inference" "HTTPS/443, Bearer Token"
        llamaStack -> watsonx "Cloud inference" "HTTPS/443, API Key"
        llamaStack -> azureOpenAI "Cloud inference" "HTTPS/443, API Key"
        llamaStack -> vertexAI "Cloud inference" "HTTPS/443, Google ADC"
        llamaStack -> openai "Cloud inference" "HTTPS/443, API Key"

        llamaStack -> milvusRemote "Vector search" "REST/gRPC, Token"
        llamaStack -> pgvector "Vector search" "PostgreSQL/5432, Password"
        llamaStack -> qdrant "Vector search" "REST(6333)/gRPC(6334), API Key"

        llamaStack -> s3 "File storage" "HTTPS/443, AWS IAM"
        llamaStack -> huggingface "Dataset and model downloads" "HTTPS/443"
        llamaStack -> braveSearch "Web search" "HTTPS/443, API Key"
        llamaStack -> tavilySearch "Web search" "HTTPS/443, API Key"
        llamaStack -> otelCollector "Traces and metrics" "HTTP/4318, OTLP"
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
                background #fff2cc
                shape RoundedBox
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal" {
                background #336791
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External/Internal" {
                background #d5e8d4
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

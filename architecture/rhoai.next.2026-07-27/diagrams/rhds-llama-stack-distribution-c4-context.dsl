workspace {
    model {
        user = person "Data Scientist / Developer" "Sends inference requests, manages agents, runs evaluations"

        llamaStack = softwareSystem "rhds-llama-stack-distribution" "Red Hat distribution of Meta's Llama Stack framework providing unified HTTP API for AI/ML inference, safety, evaluation, and vector storage on RHOAI" {
            server = container "Llama Stack Server" "Single-container server running llama stack run with config-driven provider architecture" "Python / RHEL 9"
            configManager = container "Configuration Manager" "Environment variable interpolation and conditional provider activation" "config.yaml"
            kvStore = container "KV Storage Backend" "Key-value state for registry, vector_io persistence, agent state" "kv_postgres"
            sqlStore = container "SQL Storage Backend" "Structured records for inference_store, files_metadata, conversations" "sql_postgres"
        }

        # Inference Providers
        vllm = softwareSystem "vLLM" "High-performance LLM inference engine" "External"
        bedrock = softwareSystem "AWS Bedrock" "Amazon managed AI service" "External Cloud"
        watsonx = softwareSystem "IBM WatsonX" "IBM enterprise AI platform" "External Cloud"
        azureOpenAI = softwareSystem "Azure OpenAI" "Microsoft managed OpenAI service" "External Cloud"
        vertexAI = softwareSystem "Google Vertex AI" "Google Cloud AI platform" "External Cloud"
        openAI = softwareSystem "OpenAI" "OpenAI API service" "External Cloud"

        # Storage
        postgresql = softwareSystem "PostgreSQL" "Persistent state storage for KV and SQL backends" "External"
        milvus = softwareSystem "Milvus" "Default vector database for embedding storage and retrieval" "External"
        pgvector = softwareSystem "PgVector" "PostgreSQL extension for vector similarity search" "External"
        qdrant = softwareSystem "Qdrant" "Vector similarity search engine" "External"

        # Safety & Evaluation
        trustyAI = softwareSystem "TrustyAI FMS Orchestrator" "Safety guardrail evaluation service" "Internal RHOAI"
        lmeval = softwareSystem "TrustyAI LMEval" "Language model evaluation service" "Internal RHOAI"
        ragas = softwareSystem "RAGAS" "RAG evaluation framework" "Internal RHOAI"
        garak = softwareSystem "Garak" "LLM security benchmarking tool" "Internal RHOAI"

        # Observability
        otelCollector = softwareSystem "OTLP Collector" "OpenTelemetry traces and metrics collection" "External"

        # Platform
        platform = softwareSystem "RHOAI Platform" "Red Hat OpenShift AI platform providing auth, routing, and lifecycle management" "Internal RHOAI"

        # Relationships
        user -> llamaStack "Sends inference/agent/eval requests" "HTTP/8321"
        platform -> llamaStack "Manages deployment, enforces auth and TLS" "Platform APIs"

        llamaStack -> vllm "Routes inference requests" "HTTP/gRPC"
        llamaStack -> bedrock "Routes inference requests" "HTTPS/443"
        llamaStack -> watsonx "Routes inference requests" "HTTPS/443"
        llamaStack -> azureOpenAI "Routes inference requests" "HTTPS/443"
        llamaStack -> vertexAI "Routes inference requests" "HTTPS/443"
        llamaStack -> openAI "Routes inference requests" "HTTPS/443"

        llamaStack -> postgresql "Persists agent state, inference records, metadata" "TCP/5432"
        llamaStack -> milvus "Stores/queries vector embeddings" "gRPC/HTTP"
        llamaStack -> pgvector "Stores/queries vector embeddings" "TCP/5432"
        llamaStack -> qdrant "Stores/queries vector embeddings" "HTTP/gRPC"

        llamaStack -> trustyAI "Safety guardrail evaluation" "HTTP"
        llamaStack -> lmeval "Dispatches evaluation workloads" "HTTP"
        llamaStack -> ragas "Dispatches RAG evaluation" "HTTP"
        llamaStack -> garak "Dispatches security benchmarking" "HTTP"

        llamaStack -> otelCollector "Exports traces and metrics (optional)" "OTLP"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Cloud" {
                background #ff9900
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

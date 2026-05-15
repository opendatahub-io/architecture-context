workspace {
    model {
        datascientist = person "Data Scientist" "Creates AI applications using Llama Stack APIs for inference, RAG, safety, and evaluation"
        platformadmin = person "Platform Admin" "Deploys and configures Llama Stack via RHOAI operator"

        ogxDistribution = softwareSystem "ogx-distribution (Llama Stack)" "Containerized Llama Stack server providing standardized APIs for inference, safety, evaluation, vector I/O, tool runtime, and more" {
            llamaStackServer = container "Llama Stack Server" "Serves Llama Stack APIs as an HTTP service with conditional provider activation" "Python 3.12 (FastAPI/Uvicorn)" "WebApp"
            distroConfig = container "Distribution Config" "Defines active providers, storage backends, auth policy, and registered resources" "YAML (config.yaml)" "Config"
            oauth2Middleware = container "OAuth2 Auth Middleware" "Validates JWT tokens against JWKS endpoint when AUTH_ISSUER is configured" "Python" "Component"
            kvPostgres = container "kv_postgres Store" "Key-value storage for metadata, vector IO state, batches" "PostgreSQL client" "Database"
            sqlPostgres = container "sql_postgres Store" "Relational storage for inference records, files metadata, agent responses" "PostgreSQL client" "Database"
        }

        # Internal RHOAI Platform Dependencies
        vllm = softwareSystem "vLLM Serving Runtime" "LLM and embedding model inference serving" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI safety guardrails (FMS) and model evaluation (LM-Eval, RAGAS, Garak)" "Internal RHOAI"
        kubeflow = softwareSystem "Kubeflow Pipelines" "Pipeline orchestration for remote evaluation jobs" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Persistent relational database for KV store, SQL store, inference store" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for files (MinIO/ODF)" "Internal RHOAI"
        otelCollector = softwareSystem "OTEL Collector" "OpenTelemetry traces and metrics aggregation" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys and manages Llama Stack" "Internal RHOAI"

        # External Cloud Inference Providers
        awsBedrock = softwareSystem "AWS Bedrock" "Cloud LLM inference via Amazon Bedrock" "External Cloud"
        googleVertexAI = softwareSystem "Google Vertex AI" "Cloud LLM inference via Google AI Platform" "External Cloud"
        openaiAPI = softwareSystem "OpenAI API" "Cloud LLM inference via OpenAI" "External Cloud"
        ibmWatsonX = softwareSystem "IBM WatsonX" "Cloud LLM inference via IBM AI Platform" "External Cloud"
        azureOpenAI = softwareSystem "Azure OpenAI" "Cloud LLM inference via Microsoft Azure" "External Cloud"

        # External Vector Databases
        milvus = softwareSystem "Milvus" "Distributed vector database for similarity search" "External"
        qdrant = softwareSystem "Qdrant" "Vector database with REST and gRPC APIs" "External"

        # External Tools & Services
        braveSearch = softwareSystem "Brave Search" "Web search API for tool runtime" "External"
        tavilySearch = softwareSystem "Tavily Search" "Web search API for tool runtime" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        oauth2Provider = softwareSystem "OAuth2 Identity Provider" "JWT token issuer and JWKS endpoint" "External"

        # Relationships - Users
        datascientist -> ogxDistribution "Creates AI applications via REST APIs" "HTTP/8321"
        platformadmin -> rhodsOperator "Configures and deploys Llama Stack" "kubectl/oc"

        # Relationships - Platform operator
        rhodsOperator -> ogxDistribution "Deploys and manages container lifecycle" "Kubernetes API"

        # Relationships - Internal platform
        ogxDistribution -> vllm "Sends inference and embedding requests" "HTTP/HTTPS, Bearer Token"
        ogxDistribution -> trustyai "Sends safety checks and evaluation jobs" "HTTP/HTTPS, Certificate/Token"
        ogxDistribution -> kubeflow "Submits evaluation pipelines (RAGAS, Garak)" "HTTP, Bearer Token"
        ogxDistribution -> postgresql "Stores state (KV + SQL)" "TCP/5432, Password"
        ogxDistribution -> s3Storage "Stores and retrieves files" "HTTPS/443, AWS IAM"
        ogxDistribution -> otelCollector "Exports traces and metrics" "HTTP OTLP"

        # Relationships - External cloud
        ogxDistribution -> awsBedrock "Cloud LLM inference" "HTTPS/443, Bearer Token"
        ogxDistribution -> googleVertexAI "Cloud LLM inference" "HTTPS/443, Google ADC"
        ogxDistribution -> openaiAPI "Cloud LLM inference" "HTTPS/443, API Key"
        ogxDistribution -> ibmWatsonX "Cloud LLM inference" "HTTPS/443, API Key"
        ogxDistribution -> azureOpenAI "Cloud LLM inference" "HTTPS/443, API Key"

        # Relationships - External services
        ogxDistribution -> milvus "Vector similarity search" "TCP, TLS/mTLS optional"
        ogxDistribution -> qdrant "Vector similarity search" "HTTP-gRPC/6333-6334, API Key"
        ogxDistribution -> braveSearch "Web search tool" "HTTPS/443, API Key"
        ogxDistribution -> tavilySearch "Web search tool" "HTTPS/443, API Key"
        ogxDistribution -> huggingface "Downloads datasets" "HTTPS/443, Token"
        ogxDistribution -> oauth2Provider "Validates JWT tokens via JWKS" "HTTPS/443"
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
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External Cloud" {
                background #f5a623
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "WebApp" {
                shape WebBrowser
            }
            element "Database" {
                shape Cylinder
            }
            element "Config" {
                shape Folder
            }
            element "Component" {
                shape Hexagon
            }
        }
    }
}

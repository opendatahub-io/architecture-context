workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models, runs inference, evaluation, and safety checks"
        mlEngineer = person "ML Engineer" "Configures inference backends and manages agentic workflows"

        llamaStackDistro = softwareSystem "Llama Stack Distribution" "Unified API gateway for LLM inference, evaluation, safety, vector I/O, agents, and tool runtime" {
            server = container "Llama Stack Server" "Unified API gateway implementing Llama Stack native and OpenAI-compatible APIs" "Python 3.12 / FastAPI / uvicorn" {
                inferenceAPI = component "Inference API" "Handles /v1/chat/completions and /v1/inference/chat_completion" "Provider Plugin"
                agentsAPI = component "Agents API" "Manages agentic workflows via /v1/agents" "Provider Plugin"
                vectorIOAPI = component "Vector I/O API" "Vector database operations via /v1/vector-io/*" "Provider Plugin"
                safetyAPI = component "Safety API" "Safety shield evaluation via /v1/safety/*" "Provider Plugin"
                evalAPI = component "Eval API" "Model evaluation orchestration via /v1/eval/*" "Provider Plugin"
                toolRuntimeAPI = component "Tool Runtime API" "Tool runtime (search, RAG, MCP) via /v1/tool-runtime/*" "Provider Plugin"
                scoringAPI = component "Scoring API" "Scoring functions via /v1/scoring/*" "Provider Plugin"
                storageLayer = component "Storage Layer" "Async PostgreSQL backend for kvstore, logs, state" "kv_postgres + sql_postgres"
            }
        }

        # Internal Platform Dependencies
        vllm = softwareSystem "vLLM" "Primary LLM inference and embedding backend" "Internal RHOAI"
        trustyaiFMS = softwareSystem "TrustyAI FMS Orchestrator" "Safety shield evaluation for content moderation" "Internal RHOAI"
        trustyaiLMEval = softwareSystem "TrustyAI LMEval" "Model evaluation using LM Evaluation Harness" "Internal RHOAI"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Pipeline orchestration for RAGAS and Garak evaluations" "Internal RHOAI"

        # External Dependencies
        postgresql = softwareSystem "PostgreSQL 17+" "Persistent storage for kvstore, inference logs, agent state, conversations" "External"
        milvus = softwareSystem "Milvus" "Vector database (inline milvus-lite or remote)" "External"
        pgvector = softwareSystem "pgvector" "PostgreSQL-backed vector database" "External"
        qdrant = softwareSystem "Qdrant" "Vector database" "External"
        s3 = softwareSystem "S3 / S3-compatible Storage" "File storage backend" "External"

        # Cloud Inference Providers
        awsBedrock = softwareSystem "AWS Bedrock" "Remote LLM inference via AWS" "Cloud Provider"
        googleVertexAI = softwareSystem "Google Vertex AI" "Remote LLM inference via Google Cloud" "Cloud Provider"
        azureOpenAI = softwareSystem "Azure OpenAI" "Remote LLM inference via Azure" "Cloud Provider"
        ibmWatsonX = softwareSystem "IBM WatsonX" "Remote LLM inference via IBM" "Cloud Provider"
        openaiAPI = softwareSystem "OpenAI API" "Remote LLM inference via OpenAI" "Cloud Provider"

        # Tool Services
        braveSearch = softwareSystem "Brave Search API" "Web search tool for agents" "External"
        tavilySearch = softwareSystem "Tavily Search API" "Web search tool for agents" "External"
        mcpServers = softwareSystem "MCP Servers" "Model Context Protocol tool servers" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Dataset and model download" "External"

        # Observability
        otelCollector = softwareSystem "OTEL Collector" "Traces and metrics export (optional)" "External"

        # Platform Infrastructure
        platformIngress = softwareSystem "Platform Ingress" "kube-rbac-proxy / Gateway API for TLS and auth" "Infrastructure"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for LMEval Job creation" "Infrastructure"

        # Relationships - Users
        dataScientist -> llamaStackDistro "Inference, evaluation, safety checks" "HTTP/8321 via Platform Ingress"
        mlEngineer -> llamaStackDistro "Configure backends, manage agents" "HTTP/8321 via Platform Ingress"

        # Relationships - Platform Ingress
        platformIngress -> llamaStackDistro "Forwards authenticated requests" "HTTP/8321"

        # Relationships - Internal
        llamaStackDistro -> vllm "LLM inference and embedding" "HTTP/HTTPS, Bearer Token"
        llamaStackDistro -> trustyaiFMS "Safety shield evaluation" "HTTP/HTTPS"
        llamaStackDistro -> trustyaiLMEval "Model evaluation" "HTTP"
        llamaStackDistro -> kubeflowPipelines "RAGAS/Garak evaluation pipelines" "HTTPS/443, Bearer Token"

        # Relationships - Storage
        llamaStackDistro -> postgresql "Persistent state storage" "PostgreSQL/5432"
        llamaStackDistro -> s3 "File storage" "HTTPS/443, AWS IAM"

        # Relationships - Vector DBs
        llamaStackDistro -> milvus "Vector search operations" "HTTP/gRPC, Token"
        llamaStackDistro -> pgvector "Vector search via PostgreSQL" "PostgreSQL"
        llamaStackDistro -> qdrant "Vector search operations" "HTTP/gRPC, API Key"

        # Relationships - Cloud Providers
        llamaStackDistro -> awsBedrock "Remote LLM inference" "HTTPS/443, Bearer Token"
        llamaStackDistro -> googleVertexAI "Remote LLM inference" "HTTPS/443, Google ADC"
        llamaStackDistro -> azureOpenAI "Remote LLM inference" "HTTPS/443, API Key"
        llamaStackDistro -> ibmWatsonX "Remote LLM inference" "HTTPS/443, API Key"
        llamaStackDistro -> openaiAPI "Remote LLM inference" "HTTPS/443, API Key"

        # Relationships - Tools
        llamaStackDistro -> braveSearch "Web search for agents" "HTTPS/443, API Key"
        llamaStackDistro -> tavilySearch "Web search for agents" "HTTPS/443, API Key"
        llamaStackDistro -> mcpServers "Tool runtime" "HTTP/HTTPS"
        llamaStackDistro -> huggingfaceHub "Dataset/model download" "HTTPS/443"

        # Relationships - Infrastructure
        llamaStackDistro -> k8sAPI "Create LMEval evaluation Jobs" "HTTPS/443, SA Token"
        llamaStackDistro -> otelCollector "Export traces and metrics" "HTTP OTLP"
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

        component server "Components" {
            include *
            autoLayout
        }

        styles {
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Cloud Provider" {
                background #f5a623
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

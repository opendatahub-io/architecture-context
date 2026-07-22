workspace {
    model {
        dataScientist = person "Data Scientist" "Creates experiments, tracks runs, registers models, and deploys ML workflows"
        appDeveloper = person "Application Developer" "Integrates LLM endpoints via AI Gateway, submits jobs"

        mlflow = softwareSystem "MLflow" "ML lifecycle management platform providing experiment tracking, model registry, artifact storage, AI gateway, and MCP server registry" {
            trackingServer = container "MLflow Tracking Server" "Core experiment tracking, model registry, artifact management" "Python (FastAPI + Flask)" "Service"
            aiGateway = container "AI Gateway" "Multi-provider LLM endpoint management with traffic splitting, guardrails, and budget limits" "FastAPI Router"
            mcpRegistry = container "MCP Server Registry" "Model Context Protocol server, version, and endpoint lifecycle management" "FastAPI Router"
            otelIngestion = container "OpenTelemetry Ingestion" "OTLP/HTTP trace export endpoint converting OTel spans to MLflow traces" "FastAPI Router"
            jobEngine = container "Job Execution Engine" "Async job submission, execution, and status tracking" "FastAPI Router + Huey"
            authModule = container "Authentication Module" "Basic auth, RBAC, Kubernetes auth providers, workspace mapping" "Flask Extension + Python Module"
            secretsManager = container "Secrets Manager" "AES-GCM-256 encrypted secrets storage with KEK rotation" "Python Module"
            webUI = container "Web UI" "Experiment tracking, model registry, and trace visualization frontend" "React + TypeScript + PatternFly"
        }

        postgresql = softwareSystem "PostgreSQL" "Backend store for experiment metadata, model registry, workspace state, and trace storage" "External"
        s3 = softwareSystem "S3-compatible Storage" "Artifact storage for models, datasets, and files (AWS S3, MinIO, GCS, Azure Blob)" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Service account token validation and namespace discovery for workspace mapping" "Internal Platform"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Deploys and manages MLflow instance lifecycle and configuration" "Internal Platform"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Embeds MLflow UI components via module federation" "Internal Platform"
        openaiAPI = softwareSystem "OpenAI API" "Chat completions, embeddings, and responses API" "External"
        anthropicAPI = softwareSystem "Anthropic API" "Messages API for Claude LLM inference" "External"
        geminiAPI = softwareSystem "Google Gemini API" "generateContent and streamGenerateContent API" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping for monitoring and alerting" "Internal Platform"
        otelCollectors = softwareSystem "OpenTelemetry Collectors" "External OTel span sources sending traces to MLflow" "External"

        # User interactions
        dataScientist -> mlflow "Creates experiments, logs runs, registers models via Python SDK" "HTTP/5000"
        appDeveloper -> mlflow "Sends LLM inference requests via AI Gateway" "HTTP/5000"

        # Internal container interactions
        trackingServer -> postgresql "Stores experiment metadata, run data, model versions" "PostgreSQL/5432"
        trackingServer -> s3 "Uploads/downloads model artifacts" "HTTPS/443"
        aiGateway -> openaiAPI "Proxies chat/embeddings/responses requests" "HTTPS/443"
        aiGateway -> anthropicAPI "Proxies messages requests" "HTTPS/443"
        aiGateway -> geminiAPI "Proxies generateContent requests" "HTTPS/443"
        aiGateway -> secretsManager "Retrieves encrypted LLM API keys"
        authModule -> kubernetesAPI "Validates SA tokens, discovers namespaces" "HTTPS/6443"
        otelIngestion -> postgresql "Stores converted trace data" "PostgreSQL/5432"

        # Platform interactions
        rhoaiOperator -> mlflow "Deploys and manages lifecycle"
        rhoaiDashboard -> webUI "Embeds via module federation" "HTTPS"
        prometheus -> mlflow "Scrapes /metrics endpoint" "HTTP/5000"
        otelCollectors -> otelIngestion "Exports OTLP/HTTP spans" "HTTP/5000"
    }

    views {
        systemContext mlflow "SystemContext" {
            include *
            autoLayout
        }

        container mlflow "Containers" {
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
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6c8ebf
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

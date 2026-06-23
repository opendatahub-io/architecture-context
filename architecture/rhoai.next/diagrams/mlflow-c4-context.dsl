workspace {
    model {
        dataScientist = person "Data Scientist" "Creates experiments, logs runs, registers models, and compares results"
        mlEngineer = person "ML Engineer" "Deploys models, manages versions, configures AI Gateway routes"
        appDeveloper = person "Application Developer" "Integrates LLM calls via AI Gateway, instruments apps with OTel tracing"

        mlflow = softwareSystem "MLflow" "ML experiment tracking, model registry, AI gateway, and trace ingestion platform for RHOAI" {
            trackingServer = container "Tracking Server" "Records experiments, runs, metrics, parameters; serves REST API" "Python Flask + FastAPI/Uvicorn" "Service"
            webUI = container "Web UI" "Interactive interface for browsing experiments, comparing runs, managing models" "React/TypeScript (Module Federation)" "WebApp"
            modelRegistry = container "Model Registry" "Manages model versioning, staging, aliasing, and lifecycle transitions" "Python Module" "Service"
            aiGateway = container "AI Gateway" "Proxies LLM provider API calls with rate limiting, budgets, and guardrails" "FastAPI Router" "Service"
            otlpEndpoint = container "OTLP Trace Endpoint" "Ingests OpenTelemetry traces from client SDKs and external tools" "FastAPI Router" "Service"
            jobExecutor = container "Job Executor" "Asynchronous server-side task execution for long-running operations" "Huey Task Queue" "Service"
            authModule = container "Auth Module" "RBAC-based authentication with kubernetes-auth integration" "Flask Plugin" "Service"
            envelopeEncryption = container "Envelope Encryption" "AES-256-GCM encryption for gateway secrets with PBKDF2-derived KEK hierarchy" "Python Module" "Library"
            workspaceStore = container "Workspace Store" "Multi-tenant workspace isolation backed by Kubernetes namespaces" "Python Module" "Service"
            garbageCollector = container "Garbage Collection" "Periodically removes soft-deleted runs, experiments, and artifacts" "Helm CronJob" "CronJob"
        }

        postgresql = softwareSystem "PostgreSQL" "Primary backend metadata store for experiments, runs, models, and traces" "External"
        mysql = softwareSystem "MySQL" "Alternative backend metadata store" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifact and run artifact storage (AWS S3, MinIO, Ceph)" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Workspace namespace resolution and pod metadata" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor scrape" "Internal Platform"
        rhoaiPlatform = softwareSystem "RHOAI Platform Operator" "Deploys and manages MLflow as a platform component via Helm" "Internal Platform"
        konflux = softwareSystem "Konflux / Tekton" "CI/CD pipeline for hermetic container image builds" "Internal Platform"

        openAI = softwareSystem "OpenAI API" "LLM provider for chat, completion, and embedding" "External LLM"
        anthropic = softwareSystem "Anthropic API" "LLM provider for chat and completion" "External LLM"
        bedrock = softwareSystem "Amazon Bedrock" "AWS-hosted LLM models" "External LLM"
        gemini = softwareSystem "Google Gemini / Vertex AI" "Google LLM models" "External LLM"
        mistral = softwareSystem "Mistral API" "Mistral LLM models" "External LLM"

        # Person relationships
        dataScientist -> mlflow "Logs experiments, registers models via mlflow-skinny client" "HTTP/HTTPS 5000/TCP"
        mlEngineer -> mlflow "Manages model versions and AI Gateway routes" "HTTP/HTTPS 5000/TCP"
        appDeveloper -> mlflow "Sends LLM requests via AI Gateway, submits OTel traces" "HTTP/HTTPS 5000/TCP"

        # Container relationships
        webUI -> trackingServer "Fetches experiment/run data" "/ajax-api/2.0/mlflow/*"
        trackingServer -> authModule "Validates request credentials" "kubernetes-auth"
        trackingServer -> modelRegistry "Model CRUD operations" "Internal"
        trackingServer -> postgresql "Stores/retrieves metadata" "SQL/5432/TCP"
        trackingServer -> mysql "Alternative metadata store" "SQL/3306/TCP"
        trackingServer -> s3Storage "Stores/retrieves artifacts" "HTTPS/443"
        trackingServer -> workspaceStore "Resolves tenant workspace" "Internal"
        workspaceStore -> kubernetesAPI "Namespace resolution" "HTTPS/6443"
        aiGateway -> envelopeEncryption "Decrypts provider API keys" "Internal"
        aiGateway -> openAI "Proxies LLM requests" "HTTPS/443"
        aiGateway -> anthropic "Proxies LLM requests" "HTTPS/443"
        aiGateway -> bedrock "Proxies LLM requests" "HTTPS/443"
        aiGateway -> gemini "Proxies LLM requests" "HTTPS/443"
        aiGateway -> mistral "Proxies LLM requests" "HTTPS/443"
        otlpEndpoint -> postgresql "Stores trace spans" "SQL/5432/TCP"
        jobExecutor -> postgresql "Task state persistence" "SQL/5432/TCP"
        garbageCollector -> postgresql "Cleans soft-deleted records" "SQL/5432/TCP"
        garbageCollector -> s3Storage "Removes orphaned artifacts" "HTTPS/443"

        # External system relationships
        mlflow -> postgresql "Stores experiments, runs, metrics, models, traces" "SQL/5432/TCP Password Auth"
        mlflow -> s3Storage "Stores model artifacts and run artifacts" "HTTPS/443 AWS IAM"
        mlflow -> kubernetesAPI "Workspace namespace resolution" "HTTPS/6443 SA Token"
        prometheus -> mlflow "Scrapes /metrics endpoint" "HTTP/5000"
        rhoaiPlatform -> mlflow "Deploys via Helm chart" "Helm"
        konflux -> mlflow "Builds container image (hermetic)" "Tekton Pipeline"
    }

    views {
        systemContext mlflow "SystemContext" {
            include *
            autoLayout
            description "MLflow system context showing all external dependencies and users"
        }

        container mlflow "Containers" {
            include *
            autoLayout
            description "MLflow internal container structure showing tracking server, AI gateway, and supporting components"
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External LLM" {
                background #d6b656
                color #333333
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "WebApp" {
                background #6c8ebf
                color #ffffff
            }
            element "Library" {
                background #f5a623
                color #333333
            }
            element "CronJob" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

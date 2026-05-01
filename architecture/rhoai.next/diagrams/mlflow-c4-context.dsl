workspace {
    model {
        dataScientist = person "Data Scientist" "Creates experiments, logs metrics, registers models, and deploys ML workflows"
        mlEngineer = person "ML Engineer" "Manages model versions, staging, and production deployments"
        platformAdmin = person "Platform Admin" "Configures AI Gateway endpoints, manages workspaces, and rotates secrets"

        mlflow = softwareSystem "MLflow" "ML experiment tracking, model registry, artifact management, and AI Gateway platform for RHOAI" {
            flaskApi = container "Flask REST API" "Protobuf-backed REST endpoints for experiments, runs, models, users, permissions" "Python/Flask"
            fastApiApp = container "FastAPI App" "Async endpoints for jobs, AI Gateway, OTLP traces, assistant" "Python/FastAPI"
            graphqlApi = container "GraphQL API" "Experiment tracking queries via GraphQL" "Python/Ariadne"
            kubeAuthProvider = container "Kubernetes Auth Provider" "Validates SA tokens, resolves namespaces to workspaces" "Python Plugin"
            authMiddleware = container "Auth Middleware" "Per-resource permissions (READ/USE/EDIT/MANAGE)" "Python Middleware"
            securityMiddleware = container "Security Middleware" "CORS, Host validation, DNS rebinding protection" "Python Middleware"
            aiGateway = container "AI Gateway" "Proxies LLM provider calls with KEK-encrypted API keys" "Python/FastAPI"
            jobEngine = container "Job Engine" "Async job execution via Huey task queue" "Python/Huey"
            otlpIngestion = container "OTLP Ingestion" "Receives OpenTelemetry traces in protobuf binary format" "Python/FastAPI"
            trackingStore = container "Tracking Store" "Experiment, run, metric, param, and tag persistence" "SQLAlchemy"
            modelRegistryStore = container "Model Registry Store" "Model, version, alias, and stage persistence" "SQLAlchemy"
            workspaceStore = container "Workspace Store" "Multi-tenant workspace management with composite keys" "SQLAlchemy"
            artifactRepo = container "Artifact Repository" "Model files, logs, plots, trace data storage" "boto3/Azure SDK/GCS"
            standaloneUI = container "MLflow Standalone UI" "Web interface for experiment visualization and model management" "React/TypeScript"
            federatedUI = container "MLflow Federated UI" "Module Federation remote exposing experiment, prompt, run components" "React/TypeScript/Webpack"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar authenticating requests via Kubernetes SA tokens" "Platform Infrastructure"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Module Federation host embedding MLflow UI components" "Internal RHOAI"
        platformGateway = softwareSystem "Platform Gateway" "HTTPRoute-based external ingress with TLS termination" "Platform Infrastructure"

        postgresql = softwareSystem "PostgreSQL" "Metadata backend store for all MLflow state" "External"
        s3 = softwareSystem "S3 / MinIO" "Object storage for ML artifacts" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Alternative artifact storage backend" "External"
        gcs = softwareSystem "Google Cloud Storage" "Alternative artifact storage backend" "External"
        k8sApi = softwareSystem "Kubernetes API" "BatchV1 Job execution, SA token validation, namespace resolution" "Platform Infrastructure"
        openaiApi = softwareSystem "OpenAI API" "LLM provider for AI Gateway chat/completion/embedding" "External"
        anthropicApi = softwareSystem "Anthropic API" "LLM provider for AI Gateway chat/completion" "External"
        geminiApi = softwareSystem "Google Gemini API" "LLM provider for AI Gateway chat/completion" "External"
        mistralApi = softwareSystem "Mistral API" "LLM provider for AI Gateway chat/completion" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping via prometheus-flask-exporter" "Platform Infrastructure"

        # User interactions
        dataScientist -> mlflow "Logs experiments, metrics, artifacts via Python SDK" "HTTPS/443"
        mlEngineer -> mlflow "Registers models, manages versions and aliases" "HTTPS/443"
        platformAdmin -> mlflow "Configures AI Gateway, manages workspaces" "HTTPS/443"

        # Ingress chain
        dataScientist -> platformGateway "HTTPS/443 TLS 1.2+"
        platformGateway -> kubeRbacProxy "HTTPS/8443 TLS 1.2+"
        kubeRbacProxy -> mlflow "HTTP/5000 (pod-local, validated token)" "HTTP"

        # Dashboard integration
        rhoaiDashboard -> federatedUI "Loads remoteEntry.js via Module Federation" "HTTPS/443"

        # Internal container relationships
        flaskApi -> authMiddleware "Checks permissions"
        fastApiApp -> authMiddleware "Checks permissions"
        authMiddleware -> kubeAuthProvider "Validates token, resolves workspace"
        authMiddleware -> securityMiddleware "CORS/Host validation"
        flaskApi -> trackingStore "CRUD experiments, runs, metrics"
        flaskApi -> modelRegistryStore "CRUD models, versions"
        fastApiApp -> workspaceStore "Workspace management"
        flaskApi -> artifactRepo "Artifact upload/download"
        fastApiApp -> aiGateway "LLM proxy requests"
        fastApiApp -> jobEngine "Async job execution"
        fastApiApp -> otlpIngestion "Trace ingestion"

        # Egress
        trackingStore -> postgresql "SQL/5432 TLS 1.2+" "PostgreSQL wire protocol"
        modelRegistryStore -> postgresql "SQL/5432 TLS 1.2+" "PostgreSQL wire protocol"
        workspaceStore -> postgresql "SQL/5432 TLS 1.2+" "PostgreSQL wire protocol"
        artifactRepo -> s3 "HTTPS/443 TLS 1.2+ AWS IAM" "S3 API"
        artifactRepo -> azureBlob "HTTPS/443 TLS 1.2+" "Azure Blob API"
        artifactRepo -> gcs "HTTPS/443 TLS 1.2+" "GCS API"
        jobEngine -> k8sApi "HTTPS/443 TLS 1.2+ SA Token" "Kubernetes API"
        kubeAuthProvider -> k8sApi "HTTPS/443 TLS 1.2+ SA Token" "Kubernetes API"
        aiGateway -> openaiApi "HTTPS/443 TLS 1.2+ API Key" "REST API"
        aiGateway -> anthropicApi "HTTPS/443 TLS 1.2+ API Key" "REST API"
        aiGateway -> geminiApi "HTTPS/443 TLS 1.2+ API Key" "REST API"
        aiGateway -> mistralApi "HTTPS/443 TLS 1.2+ API Key" "REST API"
        mlflow -> prometheus "HTTP/5000 (metrics scrape)" "HTTP"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform Infrastructure" {
                background #e74c3c
                color #ffffff
            }
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
                background #438dd5
                color #ffffff
            }
        }
    }
}

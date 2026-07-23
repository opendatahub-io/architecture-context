workspace {
    model {
        dataScientist = person "Data Scientist" "Creates experiments, logs metrics, registers models, and browses MLflow UI"
        mlEngineer = person "ML Engineer" "Deploys models, manages AI Gateway routes, configures LLM providers"
        platformAdmin = person "Platform Admin" "Deploys and configures MLflow via rhods-operator Helm chart"

        mlflow = softwareSystem "MLflow" "ML experiment tracking, model registry, artifact management, and AI Gateway platform" {
            trackingServer = container "MLflow Tracking Server" "Experiment tracking, run management, metrics/params/tags storage" "Python (Flask + FastAPI/uvicorn)"
            modelRegistry = container "Model Registry" "Model versioning, staging, aliases, and lifecycle management" "Python (SQLAlchemy)"
            aiGateway = container "AI Gateway" "LLM proxy with rate limiting, budget policies, guardrails, and provider abstraction" "Python (FastAPI)"
            mcpRegistry = container "MCP Server Registry" "Model Context Protocol server registration and versioning" "Python"
            artifactProxy = container "Artifact Proxy" "Proxied artifact upload/download for S3, filesystem, cloud storage" "Python"
            webUI = container "MLflow UI" "Web interface for experiment visualization, model registry, and trace inspection" "React + TypeScript + PatternFly"
            authMiddleware = container "Auth Middleware" "Pluggable authentication and workspace-scoped RBAC" "Python (Flask before_request)"
            cryptoEngine = container "Crypto Engine" "AESGCM envelope encryption for gateway secrets" "Python (cryptography 46.0.7)"
            helmChart = container "Helm Chart" "Kubernetes deployment packaging with RBAC, NetworkPolicy, ServiceMonitor, CronJob" "Helm"
        }

        postgresql = softwareSystem "PostgreSQL" "Relational database for experiments, runs, models, workspaces, and gateway config" "External"
        s3 = softwareSystem "S3 / MinIO" "Object storage for model artifacts, datasets, and logs" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Workspace namespace resolution, SA token validation, job submission" "Platform"
        rhodsOperator = softwareSystem "rhods-operator" "Deploys MLflow via Helm chart with workspace configuration" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Platform UI that embeds MLflow components via module federation" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform"
        llmProviders = softwareSystem "LLM Providers" "OpenAI, Anthropic, Bedrock, Gemini - proxied via AI Gateway" "External"
        mlflowK8sPlugins = softwareSystem "mlflow-kubernetes-plugins" "Kubernetes workspace provider, namespaced auth, K8s job backend" "Internal RHOAI"

        # Relationships - Users
        dataScientist -> mlflow "Creates experiments, logs runs, registers models" "HTTP/HTTPS 5000/TCP"
        mlEngineer -> mlflow "Manages AI Gateway routes and model deployments" "HTTP/HTTPS 5000/TCP"
        platformAdmin -> rhodsOperator "Configures MLflow deployment" "kubectl / GitOps"

        # Relationships - Internal
        trackingServer -> modelRegistry "Stores and retrieves model metadata"
        trackingServer -> authMiddleware "Validates requests"
        trackingServer -> artifactProxy "Handles artifact storage"
        aiGateway -> cryptoEngine "Decrypts provider API keys"
        webUI -> trackingServer "REST/GraphQL API calls"

        # Relationships - External
        mlflow -> postgresql "Stores experiments, runs, models, workspaces" "PostgreSQL/5432"
        mlflow -> s3 "Stores model artifacts, datasets, logs" "HTTPS/443, HTTP/9000"
        mlflow -> kubernetesAPI "Workspace resolution, token validation, job submission" "HTTPS/6443"
        mlflow -> llmProviders "Proxies LLM requests via AI Gateway" "HTTPS/443"

        # Relationships - Platform
        rhodsOperator -> mlflow "Deploys via Helm chart"
        rhoaiDashboard -> mlflow "Embeds UI via module federation" "HTTPS"
        prometheus -> mlflow "Scrapes metrics" "HTTP/5000"
        mlflowK8sPlugins -> mlflow "Provides K8s workspace provider and auth" "In-process plugin"
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
            element "Platform" {
                background #9013fe
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
        }
    }
}

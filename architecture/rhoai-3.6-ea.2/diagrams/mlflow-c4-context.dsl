workspace {
    model {
        dataScientist = person "Data Scientist" "Trains models, logs experiments, manages model lifecycle"
        mlEngineer = person "ML Engineer" "Deploys models, manages model registry, configures serving"
        platformAdmin = person "Platform Admin" "Configures MLflow deployment, manages tenancy"

        mlflow = softwareSystem "MLflow" "Experiment tracking, model registry, and artifact management service for RHOAI" {
            server = container "MLflow Server" "Main tracking server providing experiment tracking, model registry, artifact serving, and API endpoints" "Python (FastAPI/Flask), gunicorn/uvicorn" "Port 5000"
            ui = container "MLflow UI" "Web interface for experiment visualization, model registry browsing, prompt management" "React, Module Federation"
            authPlugin = container "kubernetes-auth Plugin" "Server-side authentication and workspace authorization middleware" "Python (mlflow-kubernetes-plugins v1.6.0)"
            skinnyClient = container "mlflow-skinny" "Lightweight client library with minimal dependencies" "Python Library"
            tracingSDK = container "mlflow-tracing" "Distributed tracing instrumentation SDK" "Python Library"
        }

        postgresql = softwareSystem "PostgreSQL" "Relational database for experiment metadata, model registry, and workspace data" "External"
        objectStorage = softwareSystem "Object Storage" "S3-compatible, GCS, or Azure Blob storage for ML artifacts (models, datasets, logs)" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for workspace store operations, token validation, and namespace resolution" "Platform"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Red Hat OpenShift AI management dashboard" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform"

        llmProviders = softwareSystem "LLM Providers" "OpenAI, AWS Bedrock, and other LLM APIs for AI Gateway (disabled by default)" "External"

        # User interactions
        dataScientist -> mlflow "Logs experiments, registers models via Python SDK"
        mlEngineer -> mlflow "Manages model registry, deploys model versions"
        platformAdmin -> mlflow "Configures deployment, manages workspaces"

        # Internal container interactions
        server -> ui "Serves static assets"
        server -> authPlugin "Loads via Python entry point for per-request auth"
        dataScientist -> skinnyClient "Uses lightweight SDK for tracking"
        dataScientist -> tracingSDK "Instruments code with distributed tracing"
        skinnyClient -> server "HTTP/5000 with K8s Bearer Token" "REST API"
        tracingSDK -> server "HTTP/5000 with K8s Bearer Token" "REST API"

        # External dependencies
        server -> postgresql "Stores metadata, registry data (workspace-scoped)" "TCP/5432, Password Auth"
        server -> objectStorage "Stores/retrieves ML artifacts (workspace-prefixed)" "HTTPS/443, Provider Auth"
        authPlugin -> kubernetesAPI "Validates bearer tokens, resolves workspaces" "HTTPS/443, SA Token"
        server -> kubernetesAPI "Workspace store operations, project execution" "HTTPS/443, SA Token"
        rhoaiDashboard -> ui "Embeds via module federation" "HTTP, micro-frontend"
        prometheus -> server "Scrapes metrics endpoint" "HTTP/5000"

        # Optional AI Gateway
        server -> llmProviders "Proxies LLM requests (when AI Gateway enabled)" "HTTPS/443, API Key"
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
            element "Platform" {
                background #9673a6
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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

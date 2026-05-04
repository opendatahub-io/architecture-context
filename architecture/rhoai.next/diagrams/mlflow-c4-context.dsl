workspace {
    model {
        dataScientist = person "Data Scientist" "Creates experiments, logs metrics, registers models, and deploys ML models via MLflow"
        mlEngineer = person "ML Engineer" "Manages model registry, configures AI gateway endpoints, reviews model versions"

        mlflow = softwareSystem "MLflow" "ML lifecycle platform providing experiment tracking, model registry, artifact management, LLM observability, and AI gateway" {
            flaskApp = container "Flask REST API" "Tracking, model registry, artifact, and GraphQL APIs" "Python Flask + WSGIMiddleware"
            fastApiApp = container "FastAPI Endpoints" "AI gateway, OTLP trace ingestion, job management, workspace APIs" "Python FastAPI + Uvicorn"
            k8sAuthPlugin = container "Kubernetes Auth Plugin" "Enforces K8s RBAC on each API request via SelfSubjectAccessReview" "Python Module (entry point)"
            workspaceProvider = container "K8s Workspace Provider" "Maps K8s namespaces to MLflow workspaces, reads MLflowConfig CRD" "Python Module"
            reactUI = container "React UI" "Web interface for experiment tracking, model management, trace visualization" "TypeScript React 18 + PatternFly"
            aiGateway = container "AI Gateway" "Unified proxy for LLM providers with traffic routing, fallback, and tracing" "Python FastAPI"
            prometheusExporter = container "Prometheus Exporter" "Optional metrics endpoint for monitoring" "Python Module"
        }

        mlflowOperator = softwareSystem "MLflow Operator" "Deploys and configures MLflow server via Helm chart; reconciles MLflow CR" "Internal RHOAI"
        odhGateway = softwareSystem "ODH Data Science Gateway" "Routes external traffic to MLflow at /mlflow path via HTTPRoute" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Platform UI that embeds MLflow UI via iframe" "Internal RHOAI"
        dsc = softwareSystem "DataScienceCluster" "Platform operator enabling MLflow via DSC component toggle" "Internal RHOAI"

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for RBAC delegation, namespace discovery, CRD access" "External"
        postgresql = softwareSystem "PostgreSQL" "Backend metadata store for experiments, runs, models, traces, workspaces" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Artifact storage for experiments, models, and traces" "External"

        openai = softwareSystem "OpenAI API" "LLM provider for chat completions and embeddings" "External LLM"
        anthropic = softwareSystem "Anthropic API" "LLM provider for messages API" "External LLM"
        gemini = softwareSystem "Google Gemini API" "LLM provider for content generation" "External LLM"
        mistral = softwareSystem "Mistral API" "LLM provider for chat completions" "External LLM"
        prometheus = softwareSystem "Prometheus" "Monitoring system that scrapes MLflow metrics" "External"

        # Relationships - Users
        dataScientist -> mlflow "Tracks experiments, logs metrics, stores artifacts via SDK/UI" "HTTPS/443"
        mlEngineer -> mlflow "Manages model registry and AI gateway configuration" "HTTPS/443"

        # Relationships - Ingress
        dataScientist -> odhGateway "Accesses MLflow via platform gateway" "HTTPS/443"
        odhGateway -> mlflow "Routes /mlflow traffic" "HTTP/5000 (HTTPRoute)"

        # Relationships - Internal containers
        flaskApp -> k8sAuthPlugin "Delegates auth" "before_request hook"
        fastApiApp -> k8sAuthPlugin "Delegates auth" "middleware"
        k8sAuthPlugin -> workspaceProvider "Resolves workspace" "in-process"

        # Relationships - Platform
        mlflowOperator -> mlflow "Deploys and configures via Helm chart"
        dsc -> mlflowOperator "Enables MLflow component"
        odhDashboard -> mlflow "Embeds MLflow UI via iframe" "HTTPS/443"

        # Relationships - External
        k8sAuthPlugin -> k8sApi "SelfSubjectAccessReview for RBAC" "HTTPS/443"
        workspaceProvider -> k8sApi "Namespace list/watch, MLflowConfig watch" "HTTPS/443"
        flaskApp -> postgresql "Metadata persistence" "TCP/5432"
        flaskApp -> s3Storage "Artifact storage" "HTTPS/443"
        fastApiApp -> postgresql "Trace and job persistence" "TCP/5432"
        aiGateway -> openai "LLM invocation" "HTTPS/443"
        aiGateway -> anthropic "LLM invocation" "HTTPS/443"
        aiGateway -> gemini "LLM invocation" "HTTPS/443"
        aiGateway -> mistral "LLM invocation" "HTTPS/443"
        prometheus -> mlflow "Scrapes metrics" "HTTP/5000"
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
            element "External LLM" {
                background #c62828
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
                background #1565c0
                color #ffffff
            }
        }
    }
}

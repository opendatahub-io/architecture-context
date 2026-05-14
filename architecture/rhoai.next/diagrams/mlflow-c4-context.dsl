workspace {
    model {
        dataScientist = person "Data Scientist" "Creates experiments, logs runs, registers models, and queries traces using MLflow SDK or web UI"
        platformAdmin = person "Platform Admin" "Configures MLflow deployment and workspace access via MLflow Operator and Kubernetes RBAC"

        mlflow = softwareSystem "MLflow" "ML lifecycle platform providing experiment tracking, model registry, artifact management, trace ingestion, and AI gateway for RHOAI" {
            flaskApp = container "Flask App" "Legacy REST APIs for tracking, model registry, artifacts, and GraphQL" "Python Flask + Gunicorn"
            fastApiApp = container "FastAPI App" "Modern APIs for AI gateway, OTLP traces, jobs, workspaces" "Python FastAPI + Uvicorn"
            reactUI = container "React UI" "Web-based experiment tracking, model management, and trace visualization" "TypeScript React 18 + PatternFly"
            k8sAuthPlugin = container "Kubernetes Auth Plugin" "Enforces K8s RBAC on each API request via SelfSubjectAccessReview" "Python Module"
            workspaceProvider = container "Kubernetes Workspace Provider" "Maps K8s namespaces to MLflow workspaces, reads MLflowConfig CRD" "Python Module"
            prometheusExporter = container "Prometheus Exporter" "Optional /metrics endpoint for request monitoring" "Python Module"
        }

        mlflowOperator = softwareSystem "MLflow Operator" "Deploys and configures MLflow server via Helm chart; reconciles MLflow CR" "Internal RHOAI"
        odhGateway = softwareSystem "ODH Data Science Gateway" "Routes external traffic to MLflow at /mlflow path via HTTPRoute" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Embeds MLflow UI in dashboard iframe" "Internal RHOAI"
        dsc = softwareSystem "DataScienceCluster" "Platform operator enables MLflow via DSC component toggle" "Internal RHOAI"

        k8sApiServer = softwareSystem "Kubernetes API Server" "Authentication, authorization, namespace and CRD management" "Platform"
        postgresql = softwareSystem "PostgreSQL" "Backend metadata store for experiments, runs, models, traces, workspaces" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Artifact storage for experiment data, model artifacts, and traces" "External"

        openai = softwareSystem "OpenAI API" "LLM provider for chat completions and embeddings" "External"
        anthropic = softwareSystem "Anthropic API" "LLM provider for messages API" "External"
        gemini = softwareSystem "Google Gemini API" "LLM provider for content generation" "External"
        mistral = softwareSystem "Mistral API" "LLM provider for chat completions" "External"

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform"

        # Relationships - External
        dataScientist -> mlflow "Creates experiments, logs runs, registers models" "HTTPS/443 via Gateway, Bearer Token"
        dataScientist -> reactUI "Views experiments, traces, and models" "HTTPS/443 via Browser"
        platformAdmin -> mlflowOperator "Configures MLflow deployment" "kubectl / CR"

        # Relationships - Platform
        mlflowOperator -> mlflow "Deploys and configures via Helm chart" "Kubernetes API"
        odhGateway -> mlflow "Routes /mlflow traffic" "HTTPRoute, 5000/TCP"
        odhDashboard -> mlflow "Embeds UI iframe" "HTTPS/443"
        dsc -> mlflowOperator "Enables MLflow component" "CRD reconciliation"

        # Relationships - Internal
        flaskApp -> k8sAuthPlugin "Delegates auth via before_request" "In-process"
        fastApiApp -> k8sAuthPlugin "Delegates auth via middleware" "In-process"
        k8sAuthPlugin -> workspaceProvider "Resolves workspace context" "In-process"
        k8sAuthPlugin -> k8sApiServer "SelfSubjectAccessReview for RBAC" "HTTPS/443, SA token"
        workspaceProvider -> k8sApiServer "Namespace list/watch, MLflowConfig watch" "HTTPS/443, SA token"
        flaskApp -> postgresql "Experiment, run, model metadata CRUD" "TCP/5432, DB credentials"
        fastApiApp -> postgresql "Trace, workspace, gateway config CRUD" "TCP/5432, DB credentials"
        flaskApp -> s3Storage "Artifact read/write" "HTTPS/443, AWS IAM"
        fastApiApp -> openai "AI gateway LLM invocation" "HTTPS/443, API key (KEK-encrypted)"
        fastApiApp -> anthropic "AI gateway LLM invocation" "HTTPS/443, API key (KEK-encrypted)"
        fastApiApp -> gemini "AI gateway LLM invocation" "HTTPS/443, API key (KEK-encrypted)"
        fastApiApp -> mistral "AI gateway LLM invocation" "HTTPS/443, API key (KEK-encrypted)"
        prometheus -> prometheusExporter "Scrapes /metrics" "HTTP/5000"
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
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
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

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates experiments, logs metrics, registers models, and deploys ML workloads"
        mlEngineer = person "ML Engineer" "Manages model lifecycle, configures AI gateway endpoints, monitors traces"
        instrumentedApp = softwareSystem "Instrumented Application" "Application with OpenTelemetry tracing sending OTLP spans to MLflow" "External Client"

        mlflow = softwareSystem "MLflow" "ML lifecycle platform providing experiment tracking, model registry, artifact management, AI gateway, and LLM observability" {
            flaskApp = container "Flask WSGI Layer" "Legacy tracking and model registry REST APIs (/api/2.0/mlflow/*)" "Python Flask"
            fastapiApp = container "FastAPI ASGI Layer" "AI gateway, OTLP trace ingestion, job management, workspace APIs (/api/3.0/*, /gateway/*, /v1/traces)" "Python FastAPI"
            reactUI = container "React UI" "Web-based experiment tracking, model management, and trace visualization" "TypeScript React 18 + PatternFly"
            k8sAuthPlugin = container "Kubernetes Auth Plugin" "Enforces Kubernetes RBAC on each API request via SelfSubjectAccessReview delegation" "Python Module"
            workspaceProvider = container "Workspace Provider" "Maps Kubernetes namespaces to MLflow workspaces, reads MLflowConfig CRD for per-namespace overrides" "Python Module"
            sqlalchemyStore = container "SQLAlchemy Data Store" "Workspace-aware ORM layer with auto-filtered queries per active workspace" "Python SQLAlchemy"
            artifactStore = container "Artifact Repository" "Pluggable artifact storage supporting S3, GCS, Azure, HDFS backends" "Python Module"
            aiGateway = container "AI Gateway" "Unified LLM proxy with traffic routing, fallback chains, and KEK-encrypted credential management" "Python FastAPI"
            prometheusExporter = container "Prometheus Exporter" "Optional /metrics endpoint for server request monitoring" "Python Module"
        }

        mlflowOperator = softwareSystem "MLflow Operator" "Deploys and configures MLflow server via Helm chart; reconciles MLflow CR" "Internal RHOAI"
        odhGateway = softwareSystem "ODH Data Science Gateway" "Routes external traffic to MLflow at /mlflow path via Gateway API HTTPRoute" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Platform dashboard embedding MLflow UI via iframe" "Internal RHOAI"
        dsc = softwareSystem "DataScienceCluster" "Platform operator enables MLflow via DSC component toggle" "Internal RHOAI"

        k8sAPI = softwareSystem "Kubernetes API Server" "Provides SelfSubjectAccessReview, namespace discovery, and CRD access" "Platform"
        postgresql = softwareSystem "PostgreSQL" "Backend metadata store for experiments, runs, models, traces, and workspaces" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Artifact storage for experiment data, model artifacts, and trace data" "External"

        openai = softwareSystem "OpenAI API" "LLM provider for chat completions and embeddings" "External LLM"
        anthropic = softwareSystem "Anthropic API" "LLM provider for messages API" "External LLM"
        gemini = softwareSystem "Google Gemini API" "LLM provider for content generation" "External LLM"
        mistral = softwareSystem "Mistral API" "LLM provider for chat completions" "External LLM"

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform"

        # System-level relationships
        dataScientist -> mlflow "Creates experiments, logs metrics, registers models via SDK/UI" "HTTPS/443"
        mlEngineer -> mlflow "Manages models, configures AI gateway, monitors traces" "HTTPS/443"
        instrumentedApp -> mlflow "Sends OTLP traces" "HTTPS/443"

        mlflow -> k8sAPI "SelfSubjectAccessReview, namespace list/watch, MLflowConfig watch" "HTTPS/443"
        mlflow -> postgresql "Stores experiment, run, model, trace, workspace metadata" "TCP/5432"
        mlflow -> s3Storage "Reads/writes experiment artifacts, model artifacts, trace data" "HTTPS/443"
        mlflow -> openai "AI gateway proxied LLM requests" "HTTPS/443"
        mlflow -> anthropic "AI gateway proxied LLM requests" "HTTPS/443"
        mlflow -> gemini "AI gateway proxied LLM requests" "HTTPS/443"
        mlflow -> mistral "AI gateway proxied LLM requests" "HTTPS/443"

        mlflowOperator -> mlflow "Deploys and configures via Helm chart" "CRD reconciliation"
        odhGateway -> mlflow "Routes traffic at /mlflow path" "HTTPRoute/5000"
        odhDashboard -> mlflow "Embeds MLflow UI in iframe" "HTTPS/443"
        dsc -> mlflowOperator "Enables MLflow component" "CRD"
        prometheus -> mlflow "Scrapes /metrics endpoint" "HTTP/5000"

        # Container-level relationships
        dataScientist -> reactUI "Browses experiments, models, traces" "HTTPS via Gateway"
        dataScientist -> flaskApp "SDK API calls for tracking and model registry" "HTTPS via Gateway"
        mlEngineer -> fastapiApp "Configures AI gateway, manages workspaces" "HTTPS via Gateway"
        instrumentedApp -> fastapiApp "OTLP/HTTP protobuf trace ingestion" "HTTPS via Gateway"

        flaskApp -> k8sAuthPlugin "before_request auth hook"
        fastapiApp -> k8sAuthPlugin "middleware auth hook"
        k8sAuthPlugin -> k8sAPI "SelfSubjectAccessReview" "HTTPS/443"
        k8sAuthPlugin -> workspaceProvider "Resolve workspace context"
        workspaceProvider -> k8sAPI "Namespace list/watch, MLflowConfig watch" "HTTPS/443"

        flaskApp -> sqlalchemyStore "CRUD operations"
        fastapiApp -> sqlalchemyStore "CRUD operations"
        sqlalchemyStore -> postgresql "SQL queries" "TCP/5432"

        flaskApp -> artifactStore "Artifact read/write"
        fastapiApp -> artifactStore "Artifact read/write"
        artifactStore -> s3Storage "S3 API calls" "HTTPS/443"

        aiGateway -> openai "Proxied LLM requests" "HTTPS/443"
        aiGateway -> anthropic "Proxied LLM requests" "HTTPS/443"
        aiGateway -> gemini "Proxied LLM requests" "HTTPS/443"
        aiGateway -> mistral "Proxied LLM requests" "HTTPS/443"

        prometheus -> prometheusExporter "Scrapes metrics" "HTTP/5000"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Client" {
                background #999999
                color #ffffff
            }
            element "External LLM" {
                background #d4a017
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #326ce5
                color #ffffff
            }
        }
    }
}

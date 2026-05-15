workspace {
    model {
        dataScientist = person "Data Scientist" "Creates experiments, logs runs, registers models, and views traces via SDK or UI"
        platformAdmin = person "Platform Admin" "Deploys and configures MLflow via MLflow Operator"

        mlflow = softwareSystem "MLflow" "Shared experiment tracking, model registry, and AI gateway service for RHOAI" {
            server = container "MLflow Server" "Tracking API, model registry, artifact proxy, AI gateway, and UI serving" "Python (FastAPI + Flask)" "Port 5000/TCP"
            ui = container "MLflow UI" "Experiment visualization, model registry UI, trace viewer" "React/TypeScript" "Module Federation"
            k8sAuthPlugin = container "Kubernetes Auth Plugin" "Enforces K8s RBAC via SelfSubjectAccessReview for each API request" "Python Plugin (mlflow-kubernetes-plugins)"
            k8sWorkspaceProvider = container "Kubernetes Workspace Provider" "Maps Kubernetes namespaces to MLflow workspaces for multi-tenancy" "Python Plugin (mlflow-kubernetes-plugins)"
            cryptoEngine = container "Secrets Encryption Engine" "AES-256-GCM envelope encryption for gateway API keys using PBKDF2-derived KEK" "Python Module"
            prometheusExporter = container "Prometheus Exporter" "Exposes Prometheus metrics for request latency, counts, and server health" "Python Module"
        }

        mlflowOperator = softwareSystem "MLflow Operator" "Reconciles MLflow CR, deploys server via Helm chart" "Internal RHOAI"
        odhGateway = softwareSystem "ODH Data Science Gateway" "Routes /mlflow traffic to MLflow service via HTTPRoute" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Embeds MLflow UI as federated module" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "SelfSubjectAccessReview, namespace listing, MLflowConfig reads" "Platform"
        postgresql = softwareSystem "PostgreSQL" "Experiment, run, model, trace metadata storage" "Platform"
        s3Storage = softwareSystem "S3-compatible Storage" "Artifact storage for models, datasets, logs" "External"
        openai = softwareSystem "OpenAI API" "LLM inference (AI Gateway routing)" "External"
        anthropic = softwareSystem "Anthropic API" "LLM inference (AI Gateway routing)" "External"
        gemini = softwareSystem "Google Gemini API" "LLM inference (AI Gateway routing)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection from /metrics endpoint" "Platform"

        # System context relationships
        dataScientist -> mlflow "Logs experiments, registers models, views traces" "HTTPS/443 via ODH Gateway"
        platformAdmin -> mlflowOperator "Deploys and configures MLflow" "kubectl / CR"
        mlflowOperator -> mlflow "Deploys server, manages TLS certs, creates HTTPRoute" "Helm chart"
        odhGateway -> mlflow "Routes /mlflow traffic" "HTTPRoute, HTTPS/443 → HTTP/5000"
        odhDashboard -> mlflow "Embeds MLflow UI via Module Federation" "HTTPS/443"
        mlflow -> k8sAPI "SelfSubjectAccessReview, namespace discovery" "HTTPS/6443"
        mlflow -> postgresql "Stores metadata (experiments, runs, models, traces)" "PostgreSQL/5432 TLS"
        mlflow -> s3Storage "Reads/writes artifacts" "HTTPS/443"
        mlflow -> openai "AI Gateway inference routing (disabled by default)" "HTTPS/443"
        mlflow -> anthropic "AI Gateway inference routing (disabled by default)" "HTTPS/443"
        mlflow -> gemini "AI Gateway inference routing (disabled by default)" "HTTPS/443"
        prometheus -> mlflow "Scrapes metrics" "HTTP/5000"

        # Container relationships
        dataScientist -> server "API calls via SDK" "HTTPS/443 via Gateway"
        dataScientist -> ui "Views experiments, models, traces" "HTTPS/443 via Gateway"
        ui -> server "AJAX API calls" "HTTP/5000, X-MLFLOW-WORKSPACE header"
        server -> k8sAuthPlugin "Authenticates every request" "In-process"
        k8sAuthPlugin -> k8sWorkspaceProvider "Resolves workspace from namespace" "In-process"
        k8sAuthPlugin -> k8sAPI "SelfSubjectAccessReview" "HTTPS/6443"
        k8sWorkspaceProvider -> k8sAPI "Namespace list/watch" "HTTPS/6443"
        server -> cryptoEngine "Encrypts/decrypts gateway API keys" "In-process"
        server -> postgresql "SQL queries for metadata" "PostgreSQL/5432"
        server -> s3Storage "Artifact read/write" "HTTPS/443"
        prometheusExporter -> prometheus "Exposes /metrics" "HTTP/5000"
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

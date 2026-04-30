workspace {
    model {
        dataScientist = person "Data Scientist" "Creates experiments, tracks runs, registers models, and deploys ML workloads"
        platformAdmin = person "Platform Admin" "Configures MLflow deployment, manages workspaces, and provisions secrets"

        mlflow = softwareSystem "MLflow" "ML experiment tracking, model registry, artifact management, and AI Gateway platform for RHOAI" {
            server = container "MLflow Server" "REST/GraphQL API server for experiment tracking, model registry, artifact storage, AI Gateway, and job execution" "Python (Flask + FastAPI)"
            authProvider = container "Kubernetes Auth Provider" "Authenticates requests via K8s service account tokens and resolves workspace from namespace context" "Python Plugin"
            federatedUI = container "MLflow Federated UI" "Embeddable UI components (experiments, prompts, runs) for RHOAI dashboard integration" "React/TypeScript (Module Federation)"
            standaloneUI = container "MLflow Standalone UI" "Web interface for experiment visualization, model management, and prompt engineering" "React/TypeScript"
            jobExecutor = container "Job Executor" "Async task queue for scorer invocation and prompt optimization" "Python (Huey)"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar proxy that validates Kubernetes service account tokens before forwarding to MLflow" "Platform Sidecar"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Platform dashboard that hosts MLflow UI as a federated remote" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Provides service account token validation, namespace resolution, and BatchV1 Job execution" "Platform"
        postgresql = softwareSystem "PostgreSQL" "Stores metadata for experiments, runs, metrics, models, workspaces, auth, jobs, gateway endpoints, and secrets" "External"
        s3Storage = softwareSystem "S3 / MinIO" "Stores model artifacts, logs, plots, and trace data" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Alternative artifact storage backend" "External"
        gcs = softwareSystem "Google Cloud Storage" "Alternative artifact storage backend" "External"
        openAI = softwareSystem "OpenAI API" "LLM inference provider for AI Gateway chat/completion/embedding proxying" "External"
        anthropic = softwareSystem "Anthropic API" "LLM inference provider for AI Gateway chat/completion proxying" "External"
        gemini = softwareSystem "Google Gemini API" "LLM inference provider for AI Gateway chat/completion proxying" "External"
        mistral = softwareSystem "Mistral API" "LLM inference provider for AI Gateway chat/completion proxying" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes metrics from MLflow via prometheus-flask-exporter" "Platform"

        dataScientist -> mlflow "Tracks experiments, logs metrics, registers models via REST API"
        dataScientist -> rhoaiDashboard "Views experiments and models in federated UI"
        platformAdmin -> mlflow "Configures workspaces, gateway endpoints, and secrets"

        kubeRbacProxy -> mlflow "Forwards authenticated requests" "HTTP/5000"
        rhoaiDashboard -> federatedUI "Loads federated components via remoteEntry.js" "HTTPS/443"

        server -> postgresql "Reads/writes metadata" "PostgreSQL/5432 TLS 1.2+"
        server -> s3Storage "Stores/retrieves artifacts" "HTTPS/443"
        server -> azureBlob "Stores/retrieves artifacts (alternative)" "HTTPS/443"
        server -> gcs "Stores/retrieves artifacts (alternative)" "HTTPS/443"
        server -> openAI "Proxies LLM requests via AI Gateway" "HTTPS/443"
        server -> anthropic "Proxies LLM requests via AI Gateway" "HTTPS/443"
        server -> gemini "Proxies LLM requests via AI Gateway" "HTTPS/443"
        server -> mistral "Proxies LLM requests via AI Gateway" "HTTPS/443"
        authProvider -> kubernetesAPI "Validates SA tokens, resolves namespaces" "HTTPS/443"
        jobExecutor -> kubernetesAPI "Creates BatchV1 Jobs for project execution" "HTTPS/443"
        prometheus -> server "Scrapes /metrics endpoint" "HTTP/5000"
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
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Platform" {
                background #775599
                color #ffffff
            }
            element "Platform Sidecar" {
                background #775599
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

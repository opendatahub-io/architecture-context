workspace {
    model {
        dataScientist = person "Data Scientist" "Creates experiments, logs metrics/artifacts, registers models, and views traces"
        platformAdmin = person "Platform Admin" "Deploys and configures MLflow via the MLflow Operator"

        mlflow = softwareSystem "MLflow" "Experiment tracking, model registry, artifact management, and AI gateway for RHOAI" {
            flaskApp = container "Flask App" "Legacy REST API handlers for experiments, runs, models, and artifacts" "Python/Flask"
            fastApiApp = container "FastAPI/ASGI App" "Modern API layer for jobs, traces (OTLP), AI gateway, and GraphQL" "Python/FastAPI"
            k8sAuthPlugin = container "Kubernetes Auth Plugin" "Enforces Kubernetes RBAC per-request via SelfSubjectAccessReview" "Python Plugin"
            k8sWorkspaceProvider = container "Kubernetes Workspace Provider" "Maps Kubernetes namespaces to MLflow workspaces for multi-tenancy" "Python Plugin"
            reactUI = container "MLflow UI" "Web interface for experiment management, model registry, and trace visualization" "React/TypeScript"
            gcCronJob = container "Garbage Collection CronJob" "Periodically removes soft-deleted resources" "Kubernetes CronJob"
        }

        mlflowOperator = softwareSystem "MLflow Operator" "Deploys and manages MLflow server via Helm chart reconciliation" "Internal RHOAI"
        dataScienceCluster = softwareSystem "DataScienceCluster" "Platform CRD that enables/disables MLflow component" "Internal RHOAI"
        odhGateway = softwareSystem "ODH Data Science Gateway" "Gateway API ingress exposing MLflow at /mlflow" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Platform web UI embedding MLflow experiment views" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"

        postgresql = softwareSystem "PostgreSQL" "Backend metadata store for experiments, runs, models, and auth" "External"
        s3 = softwareSystem "S3/MinIO Storage" "Artifact storage for model files, datasets, and trace archives" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Namespace listing, RBAC checks, MLflowConfig CR reads, Job management" "External"
        llmProviders = softwareSystem "External LLM Providers" "OpenAI, Anthropic, etc. accessed via AI gateway proxy" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model downloads for artifact management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "External"

        # Relationships - Users
        dataScientist -> mlflow "Tracks experiments, logs artifacts, registers models via SDK" "HTTPS/443"
        dataScientist -> reactUI "Browses experiments, models, and traces" "HTTPS/443"
        platformAdmin -> mlflowOperator "Configures MLflow deployment" "kubectl"

        # Relationships - Internal containers
        flaskApp -> k8sAuthPlugin "Authenticates API requests"
        fastApiApp -> k8sAuthPlugin "Authenticates API requests"
        flaskApp -> k8sWorkspaceProvider "Resolves workspace context"
        fastApiApp -> k8sWorkspaceProvider "Resolves workspace context"
        reactUI -> flaskApp "AJAX API calls" "HTTP/5000"
        reactUI -> fastApiApp "AJAX API calls" "HTTP/5000"

        # Relationships - Platform
        mlflowOperator -> mlflow "Deploys via Helm chart"
        dataScienceCluster -> mlflowOperator "Enables MLflow component"
        odhGateway -> mlflow "Routes traffic via HTTPRoute at /mlflow" "HTTPS/443 → HTTP/5000"
        odhDashboard -> mlflow "Embeds experiment and trace views" "HTTPS/443"

        # Relationships - External
        mlflow -> postgresql "Stores experiment metadata, runs, models, auth" "PostgreSQL/5432"
        mlflow -> s3 "Stores and retrieves model artifacts" "HTTPS/443 or HTTP/9000"
        mlflow -> k8sAPI "RBAC checks, namespace listing, CR reads, Job ops" "HTTPS/6443"
        mlflow -> llmProviders "AI gateway proxy calls" "HTTPS/443"
        mlflow -> huggingface "Model downloads" "HTTPS/443"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates experiments, logs metrics, registers models"
        mlEngineer = person "ML Engineer" "Deploys models, manages lifecycle"

        mlflow = softwareSystem "MLflow" "Experiment tracking, model registry, and ML lifecycle management for RHOAI" {
            server = container "MLflow Server" "REST API server and UI host" "Python FastAPI/uvicorn, Port 5000"
            ui = container "MLflow UI" "Web interface for experiment tracking, model registry, and prompt management" "React/TypeScript"
            kubernetesAuthPlugin = container "kubernetes-auth Plugin" "Enforces Kubernetes RBAC via SelfSubjectAccessReview for API requests" "Python Plugin (mlflow-kubernetes-plugins)"
            workspaceProvider = container "Kubernetes Workspace Provider" "Maps Kubernetes namespaces to MLflow workspaces, reads MLflowConfig CRs" "Python Plugin (mlflow-kubernetes-plugins)"
            skinny = container "mlflow-skinny" "Lightweight client-only MLflow package" "Python Library"
            tracing = container "mlflow-tracing" "Standalone tracing instrumentation SDK" "Python SDK"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for RBAC and namespace management" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for experiment and model metadata" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for ML artifacts (models, datasets, etc.)" "External"
        odhGateway = softwareSystem "ODH Data Science Gateway" "Gateway routing external traffic via HTTPRoute" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "RHOAI management console with embedded MLflow UI" "Internal RHOAI"
        mlflowOperator = softwareSystem "MLflow Operator" "Manages MLflow server Deployment lifecycle via CRDs" "Internal RHOAI"

        dataScientist -> mlflow "Creates experiments, logs runs via SDK or UI"
        mlEngineer -> mlflow "Registers models, manages deployments"

        server -> ui "Serves"
        server -> kubernetesAuthPlugin "Delegates authentication"
        server -> workspaceProvider "Resolves workspaces"
        dataScientist -> skinny "Uses lightweight SDK"
        dataScientist -> tracing "Instruments ML code"

        mlflow -> kubernetesAPI "SelfSubjectAccessReview, namespace listing" "HTTPS/6443"
        mlflow -> postgresql "Stores experiment/run/model metadata" "SQL/5432"
        mlflow -> s3Storage "Stores/retrieves ML artifacts" "HTTPS/443"
        odhGateway -> mlflow "Routes /mlflow traffic" "HTTPS/443 → HTTP/5000"
        odhDashboard -> mlflow "Embeds MLflow UI components" "HTTP/5000"
        mlflowOperator -> mlflow "Manages Deployment lifecycle" "Kubernetes API"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

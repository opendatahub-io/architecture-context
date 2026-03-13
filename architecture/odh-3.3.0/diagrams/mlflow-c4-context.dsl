workspace {
    model {
        # External Users
        user = person "Data Scientist / ML Engineer" "Tracks experiments, manages models, and monitors LLM applications"

        # MLflow System
        mlflow = softwareSystem "MLflow" "Machine learning lifecycle platform for experiment tracking, model versioning, and LLM observability" {
            api = container "MLflow REST API" "Python/Flask" "REST API for experiment tracking, model registry, and LLM traces"
            ui = container "React Frontend" "TypeScript/React" "Web UI for visualizing experiments, models, and traces"
            k8sWorkspace = container "Kubernetes Workspace Provider" "Python" "Maps Kubernetes namespaces to MLflow workspaces for multi-tenancy"
            k8sAuth = container "Kubernetes Auth Plugin" "Python" "Enforces Kubernetes RBAC on MLflow API requests via SubjectAccessReview"
            promExporter = container "Prometheus Exporter" "Python" "Exposes MLflow server metrics"
        }

        # External Dependencies
        postgresql = softwareSystem "PostgreSQL" "Backend store for experiments, runs, and model metadata (v12+)" "External"
        s3 = softwareSystem "S3-compatible Storage" "Artifact store for models, datasets, and traces" "External"
        kubernetes = softwareSystem "Kubernetes API" "Namespace listing and RBAC enforcement (v1.24+)" "External"
        nodejs = softwareSystem "Node.js" "React frontend build (build-time only, not runtime)" "External"

        # Internal ODH Dependencies
        s3Internal = softwareSystem "S3 Storage (Minio/Ceph)" "Artifact storage backend" "ODH"
        pgInternal = softwareSystem "PostgreSQL Database" "Persistent metadata storage" "ODH"
        istio = softwareSystem "Istio Gateway" "External HTTPS exposure with TLS termination" "ODH"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Optional service-to-service mTLS encryption" "ODH"

        # Monitoring
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Relationships - User Interactions
        user -> mlflow "Tracks experiments, registers models, monitors LLM traces"

        # Relationships - External Dependencies
        mlflow -> postgresql "Stores metadata (experiments, runs, models)"
        mlflow -> s3 "Stores artifacts (models, datasets, traces)"
        mlflow -> kubernetes "Lists namespaces, enforces RBAC via SubjectAccessReview"
        mlflow -> prometheus "Exposes metrics for monitoring"

        # Relationships - Internal ODH
        api -> s3Internal "Stores artifacts"
        api -> pgInternal "Stores metadata"
        istio -> api "Routes external HTTPS traffic with TLS termination"
        serviceMesh -> api "Optional mTLS encryption"

        # Internal MLflow Relationships
        ui -> api "Calls REST API for data"
        api -> k8sWorkspace "Maps namespaces to workspaces"
        api -> k8sAuth "Enforces RBAC on every request"
        k8sWorkspace -> kubernetes "Lists namespaces and MLflowConfigs"
        k8sAuth -> kubernetes "Creates SubjectAccessReviews"
        promExporter -> prometheus "Exposes metrics"
    }

    views {
        systemContext mlflow "MLflowContext" {
            include *
            autoLayout lr
        }

        container mlflow "MLflowContainers" {
            include *
            autoLayout lr
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "ODH" {
                background #0066cc
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

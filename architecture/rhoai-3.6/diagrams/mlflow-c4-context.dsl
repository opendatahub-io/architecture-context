workspace {
    model {
        dataScientist = person "Data Scientist" "Creates experiments, logs runs, registers models via SDK or UI"
        platformAdmin = person "Platform Admin" "Manages MLflow deployment and RBAC via MLflow Operator"

        mlflow = softwareSystem "MLflow" "ML lifecycle platform providing experiment tracking, model registry, artifact management, and workspace-scoped multi-tenancy" {
            server = container "MLflow Server" "Main tracking server with REST API and bundled React UI" "Python FastAPI/Flask on uvicorn, Port 5000"
            kubeAuthPlugin = container "kubernetes-auth Plugin" "Authentication and authorization middleware using Kubernetes RBAC" "Python Plugin (mlflow-kubernetes-plugins 1.6.0)"
            workspaceStore = container "Workspace Store" "Maps Kubernetes namespaces to MLflow workspaces; reads MLflowConfig CRDs" "Python Plugin (kubernetes://)"
            artifactProxy = container "Artifact Proxy" "Proxies artifact upload/download to configured storage backends" "Python"
            reactUI = container "MLflow UI" "Single-page web application for experiment tracking and model registry" "React/TypeScript"
        }

        odhGateway = softwareSystem "ODH Data Science Gateway" "Reverse proxy providing external ingress to platform services" "Internal RHOAI"
        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator managing MLflow Deployment, Service, HTTPRoute, and MLflowConfig CRDs" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for namespace resolution, RBAC checks, and CRD access" "Infrastructure"
        postgresql = softwareSystem "PostgreSQL" "Relational database for experiment, run, and model metadata storage" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for ML artifacts (models, datasets, logs)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"

        # Relationships
        dataScientist -> odhGateway "Accesses MLflow via /mlflow endpoint" "HTTPS/443"
        dataScientist -> mlflow "Uses MLflow SDK (mlflow-skinny/mlflow-tracing)" "HTTPS/443 via gateway"
        platformAdmin -> mlflowOperator "Manages MLflow deployment" "kubectl / CRDs"

        odhGateway -> server "Forwards requests" "HTTP or HTTPS/5000"

        server -> kubeAuthPlugin "Delegates authentication" "In-process"
        server -> workspaceStore "Resolves workspace context" "In-process"
        server -> artifactProxy "Proxies artifact operations" "In-process"
        reactUI -> server "API calls from browser" "HTTP/5000"

        kubeAuthPlugin -> k8sAPI "SelfSubjectAccessReview for RBAC" "HTTPS/443"
        workspaceStore -> k8sAPI "Namespace list/watch, MLflowConfig read" "HTTPS/443"
        server -> postgresql "Stores/retrieves metadata" "TCP/5432"
        artifactProxy -> s3Storage "Uploads/downloads artifacts" "HTTPS/443"
        server -> prometheus "Exposes metrics" "HTTP/5000 /metrics"

        mlflowOperator -> mlflow "Manages deployment lifecycle" "Kubernetes API"
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
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "External" {
                background #e74c3c
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

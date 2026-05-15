workspace {
    model {
        datascientist = person "Data Scientist" "Creates and tracks ML experiments, registers models, browses results via UI"
        platformadmin = person "Platform Admin" "Manages MLflow deployment via MLflow Operator"

        mlflow = softwareSystem "MLflow" "Experiment tracking, model registry, and ML lifecycle management for RHOAI" {
            trackingServer = container "MLflow Tracking Server" "REST API for experiment tracking, model registry, artifact management, and workspace isolation" "Python (FastAPI + Flask)"
            kubeAuthPlugin = container "kubernetes-auth Plugin" "Authenticates and authorizes requests via K8s SelfSubjectAccessReview" "Python Module"
            kubeWorkspaceProvider = container "kubernetes:// Workspace Store" "Maps Kubernetes namespaces to MLflow workspaces" "Python Module"
            envelopeEncryption = container "Envelope Encryption Engine" "AES-256-GCM secrets encryption with KEK/DEK key management" "Python Module"
            mlflowUI = container "MLflow UI" "Web interface for browsing experiments, runs, metrics, models, and traces" "React SPA"
            dbMigrations = container "Database Migration System" "40+ schema migrations for PostgreSQL backends" "Alembic"
        }

        rhoaiGateway = softwareSystem "RHOAI Data Science Gateway" "Platform Gateway API ingress (Envoy) exposing MLflow at /mlflow" "Internal RHOAI"
        mlflowOperator = softwareSystem "MLflow Operator" "Deploys and configures the MLflow server, creates MLflow CR" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Namespace listing, SelfSubjectAccessReview, MLflowConfig CR reads" "External"
        postgresql = softwareSystem "PostgreSQL" "Backend store for tracking data, model registry, auth, and workspaces" "External"
        objectStorage = softwareSystem "S3/GCS/Azure Storage" "Model artifact storage backend" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via /metrics scrape endpoint" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collectors" "OTLP/HTTP trace ingestion at /v1/traces" "External"

        # External interactions
        datascientist -> mlflow "Logs experiments, registers models via SDK and UI" "HTTPS/443"
        platformadmin -> mlflowOperator "Configures MLflow deployment"

        # System interactions
        rhoaiGateway -> mlflow "Routes /mlflow traffic" "HTTPRoute, 443→5000"
        mlflowOperator -> mlflow "Deploys and manages lifecycle" "Helm"
        mlflow -> kubernetesAPI "Authorization checks, namespace enumeration, config reads" "HTTPS/6443"
        mlflow -> postgresql "Stores tracking data, model registry, workspace metadata" "PostgreSQL/5432"
        mlflow -> objectStorage "Reads/writes model artifacts" "HTTPS/443"
        prometheus -> mlflow "Scrapes metrics" "HTTP/5000"
        otelCollector -> mlflow "Sends trace spans" "HTTP/5000 OTLP"

        # Container interactions
        trackingServer -> kubeAuthPlugin "Authenticates requests"
        kubeAuthPlugin -> kubeWorkspaceProvider "Resolves workspace from namespace"
        trackingServer -> envelopeEncryption "Encrypts/decrypts gateway secrets"
        trackingServer -> dbMigrations "Runs schema migrations on startup"
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

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates experiments, logs metrics, registers models, and manages ML artifacts"
        mlEngineer = person "ML Engineer" "Deploys registered models, manages model versions and stages"

        mlflow = softwareSystem "MLflow Tracking Server" "Multi-tenant experiment tracking, model registry, and artifact serving with Kubernetes-native authentication and workspace isolation" {
            serverProcess = container "Gunicorn/Uvicorn" "ASGI/WSGI server hosting the MLflow Flask application on port 5000" "Python 3.12"
            kubeAuthPlugin = container "kubernetes-auth Plugin" "Validates Kubernetes SA bearer tokens and enforces authentication" "mlflow-kubernetes-plugins v1.5.0"
            rbacModule = container "RBAC Module" "Role-based per-resource authorization for experiments, models, gateways, and workspaces" "Python (mlflow/server/auth)"
            workspaceStore = container "Workspace Store" "Namespace-scoped multi-tenant workspace isolation" "kubernetes:// URI"
            trackingAPI = container "Tracking API" "Experiment tracking, run logging, metric recording" "Flask/FastAPI"
            modelRegistryAPI = container "Model Registry API" "Model versioning, staging, aliasing" "Flask/FastAPI"
            artifactProxy = container "Artifact Proxy" "Proxies artifact uploads/downloads to storage backends" "Flask/FastAPI"
            mlflowSkinny = container "mlflow-skinny" "Minimal-dependency client SDK for tracking operations" "Python SDK"
            mlflowTracing = container "mlflow-tracing" "Lightweight instrumentation SDK for tracing ML code" "Python SDK"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for SA token validation, workspace namespace management, and Job execution" "Internal Platform"
        sqlBackend = softwareSystem "SQL Backend" "PostgreSQL or SQLite database for experiment metadata, model registry, and RBAC data" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for ML model artifacts and experiment data via boto3" "External"
        gcsStorage = softwareSystem "Google Cloud Storage" "Alternative object storage for ML artifacts" "External"
        openaiAPI = softwareSystem "OpenAI API" "LLM provider for AI Gateway (disabled in RHOAI by default)" "External"

        # Person -> System relationships
        dataScientist -> mlflow "Creates experiments, logs runs, uploads artifacts via REST API" "HTTPS/5000, Bearer Token"
        mlEngineer -> mlflow "Registers models, manages versions and aliases" "HTTPS/5000, Bearer Token"

        # Internal container relationships
        serverProcess -> kubeAuthPlugin "Dispatches requests through auth middleware"
        kubeAuthPlugin -> rbacModule "Delegates authorization after authentication"
        rbacModule -> workspaceStore "Resolves workspace context from X-MLFLOW-WORKSPACE header"
        rbacModule -> trackingAPI "Routes authorized tracking requests"
        rbacModule -> modelRegistryAPI "Routes authorized registry requests"
        rbacModule -> artifactProxy "Routes authorized artifact requests"

        # System -> External relationships
        kubeAuthPlugin -> k8sAPI "Validates SA bearer tokens" "HTTPS/443, SA Token"
        workspaceStore -> k8sAPI "Looks up namespace for workspace mapping" "HTTPS/443, SA Token"
        trackingAPI -> sqlBackend "Stores experiment metadata, runs, metrics" "SQLAlchemy/psycopg2"
        modelRegistryAPI -> sqlBackend "Stores model versions, stages, aliases" "SQLAlchemy/psycopg2"
        artifactProxy -> s3Storage "Uploads/downloads model artifacts" "HTTPS/443, AWS IAM"
        artifactProxy -> gcsStorage "Uploads/downloads model artifacts" "HTTPS/443, GCP credentials"
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
            element "Internal Platform" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

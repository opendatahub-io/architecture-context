workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and tracks ML experiments, registers models, and manages artifacts"
        mlPipeline = person "ML Pipeline" "Automated pipeline that logs runs, metrics, and artifacts to MLflow"

        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking, model registry, and artifact serving with Kubernetes-native authentication" {
            gunicorn = container "Gunicorn / Uvicorn" "WSGI/ASGI server accepting HTTP connections on port 5000" "Python Server"
            flaskApp = container "Flask Application" "Core MLflow server with route handlers for tracking, registry, and artifacts" "Python Flask"
            authPlugin = container "kubernetes-auth Plugin" "Authentication middleware delegating to Kubernetes API" "mlflow-kubernetes-plugins 1.5.0"
            workspaceStore = container "Workspace Store" "Kubernetes-backed workspace isolation via kubernetes:// URI" "Python Plugin"
            trackingHandlers = container "Tracking API" "Experiment and run management endpoints" "Python Handlers"
            registryHandlers = container "Model Registry API" "Model versioning, aliasing, and endpoint management" "Python Handlers"
            artifactHandlers = container "Artifact Serving" "Proxies artifact downloads from remote storage backends" "Python Handlers"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for authentication, workspace state, and job execution" "Internal"
        sqlBackend = softwareSystem "SQL Backend" "Relational database for experiment and model metadata (PostgreSQL/MySQL/SQLite)" "Internal"
        s3Storage = softwareSystem "AWS S3" "Object storage for ML artifacts (models, datasets, logs)" "External"
        gcsStorage = softwareSystem "Google Cloud Storage" "Alternative artifact storage backend" "External"
        azureStorage = softwareSystem "Azure Blob Storage" "Alternative artifact storage backend" "External"
        openaiAPI = softwareSystem "OpenAI API" "AI provider integration (disabled in RHOAI deployment)" "External"

        # External interactions
        dataScientist -> mlflow "Tracks experiments, registers models via HTTP/SDK"
        mlPipeline -> mlflow "Logs runs, metrics, and artifacts via MLflow SDK"

        # Internal container interactions
        gunicorn -> flaskApp "Forwards HTTP requests"
        flaskApp -> authPlugin "Delegates authentication"
        authPlugin -> kubernetesAPI "Validates credentials" "HTTPS/443"
        flaskApp -> workspaceStore "Manages workspace state"
        workspaceStore -> kubernetesAPI "Reads/writes workspace data" "HTTPS/443"
        flaskApp -> trackingHandlers "Routes tracking requests"
        flaskApp -> registryHandlers "Routes registry requests"
        flaskApp -> artifactHandlers "Routes artifact requests"
        trackingHandlers -> sqlBackend "Stores/retrieves experiment metadata" "SQL"
        registryHandlers -> sqlBackend "Stores/retrieves model metadata" "SQL"
        artifactHandlers -> s3Storage "Downloads/uploads artifacts" "HTTPS/443"
        artifactHandlers -> gcsStorage "Downloads/uploads artifacts" "HTTPS/443"
        artifactHandlers -> azureStorage "Downloads/uploads artifacts" "HTTPS/443"
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
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

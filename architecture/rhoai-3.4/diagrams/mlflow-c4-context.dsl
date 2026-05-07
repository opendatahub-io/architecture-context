workspace {
    model {
        dataScientist = person "Data Scientist" "Creates experiments, logs metrics, registers models via Python SDK"
        mlEngineer = person "ML Engineer" "Manages model lifecycle, deploys models, reviews experiment results"
        platformAdmin = person "Platform Admin" "Manages MLflow deployment, configures workspaces and auth"

        mlflow = softwareSystem "MLflow" "ML experiment tracking, model registry, and artifact management server (v3.10.1+rhaiv.3)" {
            trackingServer = container "MLflow Tracking Server" "Hybrid WSGI/ASGI server providing REST API and GraphQL for experiment tracking and model registry" "Python (Flask + FastAPI)"
            webUI = container "MLflow Web UI" "Single-page application for visualizing experiments, runs, metrics, and models" "React (TypeScript)"
            authModule = container "Auth Module" "Pluggable authentication with Kubernetes SA token validation and workspace-scoped authorization" "Python (Flask plugin + FastAPI middleware)"
            cryptoModule = container "Crypto Module" "Envelope encryption (AES-256-GCM + PBKDF2) for secrets management with KEK rotation" "Python (cryptography)"
            storeLayer = container "Store Layer" "Database abstraction with workspace-aware query filtering" "Python (SQLAlchemy)"
            artifactRepo = container "Artifact Repository" "Pluggable artifact storage supporting S3, Azure Blob, GCS" "Python (boto3, azure-storage-blob)"
            jobRunner = container "Job Runner" "Background task execution system" "Python (Huey, SQLite-backed)"
            prometheusExporter = container "Prometheus Exporter" "Gunicorn-integrated metrics exporter" "Python (prometheus_flask_exporter)"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization sidecar proxy" "Sidecar"
        platformGateway = softwareSystem "Platform Gateway (Envoy)" "External ingress routing via RHOAI platform Gateway" "External"
        rhodsOperator = softwareSystem "rhods-operator" "Deploys MLflow pods, manages HTTPRoute and kube-rbac-proxy sidecar" "Internal RHOAI"

        postgresql = softwareSystem "PostgreSQL" "Backend store for experiments, runs, metrics, models, auth, workspaces" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Artifact storage for experiment data and model files (MinIO/Ceph)" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "ServiceAccount token validation, namespace listing for workspaces" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing export" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Relationships - External Users
        dataScientist -> mlflow "Creates experiments, logs metrics, registers models" "Python SDK / HTTPS"
        mlEngineer -> mlflow "Reviews experiments, manages model versions" "Web UI / HTTPS"
        platformAdmin -> rhodsOperator "Configures MLflow deployment" "Kubernetes API"

        # Relationships - Ingress Chain
        dataScientist -> platformGateway "HTTPS/443, Bearer Token (K8s SA)"
        mlEngineer -> platformGateway "HTTPS/443, Bearer Token (K8s SA)"
        platformGateway -> kubeRbacProxy "HTTPS/8443, TLS 1.2+"
        kubeRbacProxy -> trackingServer "HTTP/5000, localhost"

        # Relationships - Internal
        trackingServer -> authModule "Authenticates requests"
        trackingServer -> storeLayer "Reads/writes experiment data"
        trackingServer -> artifactRepo "Manages artifact uploads/downloads"
        trackingServer -> cryptoModule "Encrypts/decrypts gateway secrets"
        trackingServer -> jobRunner "Submits background tasks"
        trackingServer -> prometheusExporter "Exports metrics"
        webUI -> trackingServer "AJAX API calls" "HTTP/5000"
        authModule -> storeLayer "Queries permissions and workspaces"

        # Relationships - External Dependencies
        storeLayer -> postgresql "SQL queries" "PostgreSQL/5432, TLS"
        artifactRepo -> s3Storage "S3 API (PUT/GET objects)" "HTTPS/443, AWS IAM"
        authModule -> k8sAPI "Token validation, namespace listing" "HTTPS/6443, Bearer Token"
        trackingServer -> otelCollector "Trace/span export" "OTLP/4317 gRPC"
        prometheus -> trackingServer "Metrics scrape" "HTTP/5000"

        # Relationships - Operator
        rhodsOperator -> mlflow "Deploys and manages" "Kubernetes API"
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
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Sidecar" {
                background #e67e22
            }
        }
    }
}

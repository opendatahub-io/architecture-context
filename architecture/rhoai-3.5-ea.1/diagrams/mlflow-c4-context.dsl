workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and tracks ML experiments, registers models, and stores artifacts"
        mlEngineer = person "ML Engineer" "Deploys and manages model versions, monitors experiment metrics"

        mlflow = softwareSystem "MLflow" "ML experiment tracking, model registry, and artifact storage server for RHOAI" {
            trackingServer = container "MLflow Tracking Server" "REST API server for experiment tracking, model registry, artifact proxy, workspace management, and trace ingestion" "Python (FastAPI + Flask on Uvicorn)" {
                fastApiApp = component "FastAPI Application" "Modern async web framework handling v3.0 API, OTLP traces, jobs, gateway" "FastAPI"
                flaskApp = component "Flask Application" "Legacy framework handling protobuf-generated v2.0 REST endpoints" "Flask"
                k8sAuthPlugin = component "Kubernetes Auth Provider" "ServiceAccount token-based authentication with 60s TTL cache" "Python Plugin"
                workspaceProvider = component "Workspace Provider" "Maps Kubernetes namespaces to MLflow workspaces via kubernetes:// URI" "mlflow-kubernetes-plugins"
                sqlStore = component "SQLAlchemy Store" "Workspace-aware ORM store for experiments, runs, metrics, models, traces" "SQLAlchemy"
                artifactRepo = component "Artifact Repository" "Plugin-based artifact storage abstraction (S3, GCS, Azure, local)" "Python"
                envelopeEncryption = component "Envelope Encryption" "AES-256-GCM with PBKDF2-HMAC-SHA256 for gateway secret encryption" "cryptography"
                securityMiddleware = component "Security Middleware" "CORS blocking, host validation, security headers" "Python Middleware"
            }

            webUI = container "MLflow Web UI" "Single-page application for visualizing experiments, runs, metrics, models, and traces" "React/TypeScript" "Browser"
            skinnyClient = container "MLflow Skinny" "Lightweight Python client library with minimal dependencies for tracking" "Python Library"
            tracingSDK = container "MLflow Tracing" "OpenTelemetry-based tracing SDK for instrumenting ML code" "Python Library"
            fs2db = container "fs2db Migration Tool" "Migrates data from legacy FileStore (YAML) to SQL database backends" "Python CLI"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication enforcement sidecar managed by rhods-operator" "Sidecar"
        rhoaiGateway = softwareSystem "RHOAI Platform Gateway" "HTTPRoute-based ingress with TLS termination, managed by rhods-operator" "Platform"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Platform dashboard with module federation for MLflow UI embedding" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator managing MLflow deployment lifecycle (Deployment, Service, HTTPRoute, RBAC)" "Internal RHOAI"

        postgresql = softwareSystem "PostgreSQL" "Primary database for tracking store, model registry, workspace store, job store, and trace store" "External"
        k8sApiServer = softwareSystem "Kubernetes API Server" "Workspace namespace resolution and SA token validation" "External"
        s3 = softwareSystem "S3-compatible Object Store" "Artifact storage backend (models, data, plots)" "External"
        gcs = softwareSystem "Google Cloud Storage" "Alternative artifact storage backend" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Alternative artifact storage backend" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping via prometheus-flask-exporter" "External"

        # Relationships - Users
        dataScientist -> mlflow "Tracks experiments, logs metrics, stores artifacts via SDK and Web UI"
        mlEngineer -> mlflow "Registers models, manages versions, queries model registry"
        dataScientist -> webUI "Visualizes experiments and results" "HTTPS/443"
        dataScientist -> skinnyClient "Logs experiments and metrics from training code" "Python API"
        dataScientist -> tracingSDK "Instruments ML code with distributed tracing" "Python API"

        # Relationships - Internal
        webUI -> trackingServer "Frontend API calls" "HTTP/5000 (via Gateway)"
        skinnyClient -> trackingServer "REST API calls" "HTTP/5000 (via Gateway)"
        tracingSDK -> trackingServer "OTLP/HTTP protobuf span export" "HTTP/5000 /v1/traces"
        rhoaiGateway -> kubeRbacProxy "Forwards authenticated traffic" "HTTPS/8443"
        kubeRbacProxy -> trackingServer "Pre-validated requests" "HTTP/5000 localhost"

        # Relationships - External
        trackingServer -> postgresql "Persists experiments, runs, metrics, models, traces, jobs" "PostgreSQL/5432 TLS configurable"
        trackingServer -> k8sApiServer "Resolves workspace namespaces, validates SA tokens" "HTTPS/443"
        trackingServer -> s3 "Stores and retrieves model artifacts" "HTTPS/443 AWS IAM"
        trackingServer -> gcs "Stores and retrieves model artifacts" "HTTPS/443 GCP SA"
        trackingServer -> azureBlob "Stores and retrieves model artifacts" "HTTPS/443 Azure AD"
        prometheus -> trackingServer "Scrapes request metrics" "HTTP/5000"

        # Relationships - Platform
        rhodsOperator -> mlflow "Manages deployment lifecycle (Deployment, Service, HTTPRoute, RBAC)" "Kubernetes API"
        rhoaiDashboard -> webUI "Embeds via Module Federation" "Build-time integration"
    }

    views {
        systemContext mlflow "SystemContext" {
            include *
            autoLayout
        }

        container mlflow "Containers" {
            include *
            include kubeRbacProxy
            include rhoaiGateway
            include postgresql
            include k8sApiServer
            include s3
            include prometheus
            autoLayout
        }

        component trackingServer "Components" {
            include *
            include postgresql
            include k8sApiServer
            include s3
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
            element "Sidecar" {
                background #f5a623
                color #ffffff
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Browser" {
                shape WebBrowser
            }
            element "Python Library" {
                background #fff3e0
                color #333333
            }
        }
    }
}

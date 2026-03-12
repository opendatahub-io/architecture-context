workspace {
    model {
        # Actors
        dataScientist = person "Data Scientist" "Creates features and trains ML models using historical data"
        mlEngineer = person "ML Engineer" "Deploys models and integrates real-time feature serving"
        streamDev = person "Stream Developer" "Pushes features from streaming pipelines"

        # Feast System
        feast = softwareSystem "Feast Feature Store" "Manages features consistently for ML training and serving with offline and online stores" {
            operator = container "Feast Operator" "Manages FeatureStore CRs and deploys Feast services" "Go Operator" "Operator"
            onlineServer = container "Feature Server (Online)" "Serves pre-computed features for real-time inference" "Python FastAPI/gRPC" "Service"
            offlineServer = container "Feature Server (Offline)" "Serves historical features for batch scoring/training" "Python FastAPI" "Service"
            registry = container "Registry Service" "Stores and serves feature definitions and metadata" "Python gRPC/REST" "Service"
            transform = container "Transformation Service" "Executes on-demand feature transformations" "Python gRPC" "Service"
            ui = container "UI Service" "Web interface for exploring and managing features" "TypeScript/React" "WebApp"
        }

        # Storage Systems
        onlineStore = softwareSystem "Online Store" "Low-latency storage for online features (Redis, PostgreSQL, DynamoDB, etc.)" "Storage"
        offlineStore = softwareSystem "Offline Store" "Historical feature storage (BigQuery, Snowflake, Spark, S3, etc.)" "Storage"
        registryBackend = softwareSystem "Registry Backend" "Feature metadata storage (PostgreSQL, S3, GCS, File)" "Storage"

        # Kubernetes & Platform
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "Platform"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for mTLS and traffic management" "Platform"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "Platform"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning and rotation" "Platform"

        # ML Platform Components
        mlflow = softwareSystem "MLflow" "ML model lifecycle and experiment tracking" "ML Platform"
        kubeflow = softwareSystem "Kubeflow" "ML workflow orchestration" "ML Platform"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "ML Platform"
        seldonCore = softwareSystem "Seldon Core" "ML model serving platform" "ML Platform"

        # Streaming & Data Processing
        kafka = softwareSystem "Apache Kafka" "Streaming data ingestion" "External"
        spark = softwareSystem "Apache Spark" "Distributed batch feature engineering" "External"
        ray = softwareSystem "Ray" "Distributed computing for feature engineering" "External"

        # Observability
        openTelemetry = softwareSystem "OpenTelemetry" "Distributed tracing and metrics" "Observability"
        openLineage = softwareSystem "OpenLineage" "Data lineage tracking" "Observability"

        # Relationships - Users to Feast
        dataScientist -> feast "Creates features and retrieves historical data via Python SDK"
        mlEngineer -> feast "Integrates real-time feature serving in production models"
        streamDev -> feast "Pushes features from streaming pipelines"
        dataScientist -> ui "Explores features and metadata"

        # Relationships - Feast Internal
        operator -> kubernetes "Manages Deployments, Services, ConfigMaps, Secrets" "HTTPS/6443, ServiceAccount Token"
        onlineServer -> registry "Queries feature metadata" "gRPC/6570"
        offlineServer -> registry "Queries feature metadata" "gRPC/6570"
        onlineServer -> transform "Executes feature transformations" "gRPC/6569"
        ui -> registry "Queries feature metadata" "HTTP/6572"

        # Relationships - Feast to Storage
        onlineServer -> onlineStore "Reads/writes online features" "Redis/PostgreSQL/DynamoDB, TLS Optional"
        offlineServer -> offlineStore "Queries historical features" "HTTPS/443, Cloud IAM"
        onlineServer -> offlineStore "Materializes features from offline to online" "HTTPS/443, Cloud IAM"
        registry -> registryBackend "Reads/writes feature definitions" "PostgreSQL/HTTPS, TLS Optional"

        # Relationships - Feast to Platform
        feast -> istio "Uses for mTLS and service mesh integration" "Optional"
        feast -> prometheus "Exposes metrics for monitoring" "HTTP/8000, HTTPS/8443"
        feast -> certManager "Uses for TLS certificate provisioning" "Optional"

        # Relationships - Feast to ML Platform
        feast -> mlflow "Integrates for feature selection in experiments" "Python SDK"
        feast -> kubeflow "Serves features in ML pipelines" "Python SDK"
        kserve -> feast "Retrieves features for model inference" "gRPC/HTTP"
        seldonCore -> feast "Retrieves features for model serving" "gRPC/HTTP"

        # Relationships - Feast to Data Processing
        feast -> kafka "Ingests streaming features" "Kafka/9092, TLS Optional"
        feast -> spark "Uses for batch feature engineering" "Python SDK"
        feast -> ray "Uses for distributed feature engineering" "Python SDK"

        # Relationships - Feast to Observability
        feast -> openTelemetry "Exports distributed traces and metrics" "gRPC/4317, Optional TLS"
        feast -> openLineage "Tracks feature lineage" "HTTPS/443"
    }

    views {
        systemContext feast "SystemContext" {
            include *
            autoLayout
        }

        container feast "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "Storage" {
                background #7ed321
                color #000000
            }
            element "ML Platform" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #000000
            }
            element "Observability" {
                background #9673a6
                color #ffffff
            }
            element "Operator" {
                background #d79b00
                color #000000
            }
            element "Service" {
                background #438dd5
                color #ffffff
            }
            element "WebApp" {
                background #82b366
                color #ffffff
            }
        }
    }
}

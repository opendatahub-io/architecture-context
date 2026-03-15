workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and manages ML features, trains models"
        mlEngineer = person "ML Engineer" "Deploys and serves ML models in production"

        # Feast Feature Store System
        feast = softwareSystem "Feast Feature Store" "Provides consistent, point-in-time correct features for ML training and serving" {
            operator = container "Feast Operator" "Manages FeatureStore lifecycle and deployments" "Go Operator" {
                controller = component "Controller Manager" "Reconciles FeatureStore CRs" "Go"
                webhook = component "Webhook Server" "Validates FeatureStore CRs" "Go"
            }

            onlineServer = container "Online Feature Server" "Serves low-latency features for real-time inference" "Python/FastAPI/gRPC" {
                onlineAPI = component "Online API" "REST/gRPC endpoints for feature retrieval" "FastAPI"
                onlineStore = component "Online Store Client" "Connects to Redis/PostgreSQL/SQLite" "Python"
            }

            offlineServer = container "Offline Feature Server" "Serves historical features for training" "Python/FastAPI" {
                offlineAPI = component "Offline API" "REST endpoints for historical features" "FastAPI"
                offlineStore = component "Offline Store Client" "Reads from S3/Parquet files" "Python"
            }

            registryServer = container "Registry Server" "Manages feature metadata and definitions" "Python/gRPC/REST" {
                registryAPI = component "Registry API" "gRPC/REST endpoints for metadata" "Python"
                registryStore = component "Registry Store" "Persists feature definitions" "Python"
            }

            uiServer = container "UI Server" "Web interface for feature exploration" "React/TypeScript" {
                webUI = component "Web UI" "Feature discovery interface" "React"
                uiBackend = component "UI Backend" "API for web UI" "TypeScript"
            }

            cronJob = container "Materialization CronJob" "Scheduled feature materialization tasks" "Kubernetes CronJob/Bash"
        }

        # External Systems - Kubernetes/OpenShift
        kubernetes = softwareSystem "Kubernetes API" "Container orchestration platform" "External"
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes platform" "External" {
            routes = container "OpenShift Routes" "External access to feature servers" "OpenShift"
        }

        # External Systems - Persistence
        postgresql = softwareSystem "PostgreSQL" "Relational database for registry and online features" "External Database"
        redis = softwareSystem "Redis" "In-memory cache for online features" "External Database"
        s3 = softwareSystem "S3 Object Storage" "Stores offline features and registry backups" "External Storage"

        # External Systems - Authentication
        oidc = softwareSystem "OIDC Provider" "Authentication and token validation" "External Auth"

        # External Systems - Monitoring
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Monitoring"

        # Internal RHOAI/ODH Components
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Interactive data science workbenches" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "RHOAI management console" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning" "Internal RHOAI"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "ML workflow orchestration" "Internal RHOAI"

        # Client Applications
        mlApplication = softwareSystem "ML Application" "Production inference service" "Client"
        trainingJob = softwareSystem "Training Job" "Model training pipeline" "Client"

        # Relationships - Users to Systems
        dataScientist -> feast "Defines features, retrieves training data"
        mlEngineer -> feast "Configures feature stores, monitors serving"
        dataScientist -> kubeflowNotebooks "Develops and tests features"
        dataScientist -> odhDashboard "Manages RHOAI resources"

        # Relationships - Feast Internal
        operator -> kubernetes "Manages Kubernetes resources"
        operator -> onlineServer "Deploys and configures"
        operator -> offlineServer "Deploys and configures"
        operator -> registryServer "Deploys and configures"
        operator -> uiServer "Deploys and configures"
        operator -> cronJob "Creates materialization schedules"
        operator -> routes "Creates external access routes"

        onlineServer -> registryServer "Fetches feature metadata" "gRPC/6570"
        offlineServer -> registryServer "Fetches feature metadata" "gRPC/6570"
        uiServer -> registryServer "Queries feature definitions" "REST/6572"
        cronJob -> onlineServer "Triggers materialization" "HTTP/6566"
        onlineServer -> offlineServer "Fetches historical features" "HTTP/8815"

        # Relationships - External Persistence
        onlineServer -> redis "Reads/writes online features" "Redis/6379"
        onlineServer -> postgresql "Reads/writes online features" "PostgreSQL/5432"
        registryServer -> postgresql "Persists feature registry" "PostgreSQL/5432"
        registryServer -> s3 "Stores registry backups" "HTTPS/443"
        offlineServer -> s3 "Reads offline features" "HTTPS/443"

        # Relationships - Authentication
        onlineServer -> oidc "Validates JWT tokens" "HTTPS/443"
        offlineServer -> oidc "Validates JWT tokens" "HTTPS/443"
        registryServer -> oidc "Validates JWT tokens" "HTTPS/443"

        # Relationships - Monitoring
        onlineServer -> prometheus "Exports metrics" "HTTP/8000"
        offlineServer -> prometheus "Exports metrics" "HTTP/8000"
        operator -> prometheus "Exports operator metrics" "HTTPS/8443"

        # Relationships - RHOAI Integration
        operator -> kubeflowNotebooks "Injects client configuration" "ConfigMap"
        operator -> certManager "Requests TLS certificates"
        odhDashboard -> feast "Displays FeatureStore status"
        dataSciencePipelines -> offlineServer "Retrieves training features"

        # Relationships - Client Applications
        mlApplication -> onlineServer "Gets real-time features" "gRPC/6566 or HTTP"
        trainingJob -> offlineServer "Gets historical features" "HTTP/8815"
        kubeflowNotebooks -> onlineServer "Tests feature retrieval"
        kubeflowNotebooks -> registryServer "Applies feature definitions" "gRPC/6570"

        # Relationships - External Access
        mlApplication -> routes "Accesses via external URL" "HTTPS/443"
        trainingJob -> routes "Accesses via external URL" "HTTPS/443"
        routes -> onlineServer "Routes traffic"
        routes -> offlineServer "Routes traffic"
        routes -> registryServer "Routes traffic"
        routes -> uiServer "Routes traffic"
    }

    views {
        systemContext feast "FeastSystemContext" {
            include *
            autoLayout lr
        }

        container feast "FeastContainers" {
            include *
            autoLayout lr
        }

        component onlineServer "OnlineServerComponents" {
            include *
            autoLayout lr
        }

        component registryServer "RegistryServerComponents" {
            include *
            autoLayout lr
        }

        dynamic feast "OnlineFeatureRetrieval" "Online feature retrieval flow" {
            mlApplication -> onlineServer "1. Request online features"
            onlineServer -> oidc "2. Validate JWT token (optional)"
            onlineServer -> registryServer "3. Fetch feature metadata"
            onlineServer -> redis "4. Retrieve feature values"
            onlineServer -> mlApplication "5. Return features"
            autoLayout lr
        }

        dynamic feast "OfflineFeatureRetrieval" "Historical feature retrieval flow" {
            trainingJob -> offlineServer "1. Request historical features"
            offlineServer -> oidc "2. Validate JWT token (optional)"
            offlineServer -> registryServer "3. Fetch feature metadata"
            offlineServer -> s3 "4. Read offline data"
            offlineServer -> trainingJob "5. Return point-in-time correct features"
            autoLayout lr
        }

        dynamic feast "FeatureMaterialization" "Feature materialization flow" {
            cronJob -> onlineServer "1. Trigger materialization"
            onlineServer -> offlineServer "2. Fetch historical features"
            offlineServer -> s3 "3. Read offline data"
            offlineServer -> onlineServer "4. Return feature values"
            onlineServer -> redis "5. Write to online store"
            autoLayout lr
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Database" {
                shape Cylinder
                background #999999
                color #ffffff
            }
            element "External Storage" {
                shape Cylinder
                background #999999
                color #ffffff
            }
            element "External Auth" {
                background #f5a623
                color #ffffff
            }
            element "External Monitoring" {
                background #f8cecc
                color #333333
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Client" {
                background #d5e8d4
                color #333333
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

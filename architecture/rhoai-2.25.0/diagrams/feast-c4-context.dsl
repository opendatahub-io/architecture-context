workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models and manages feature definitions for training and inference"
        mlApplication = softwareSystem "ML Application" "Production application serving real-time predictions" "External"
        trainingJob = softwareSystem "Training Job" "Batch training pipeline consuming historical features" "External"

        feast = softwareSystem "Feast Feature Store" "Open-source platform for managing ML features across training and serving" {
            operator = container "Feast Operator" "Manages FeatureStore CR lifecycle and deploys feature services" "Go Operator" {
                controller = component "Controller Manager" "Watches FeatureStore CRs and reconciles Kubernetes resources" "Go"
                webhook = component "Webhook Server" "Validates and mutates FeatureStore resources" "Go"
            }

            onlineStore = container "Online Feature Store" "Low-latency serving of pre-computed features for real-time inference" "Python Service" {
                onlineAPI = component "Online API" "REST/gRPC endpoints for feature retrieval" "Python"
                onlineCache = component "Feature Cache" "In-memory feature cache for performance" "Python"
            }

            offlineStore = container "Offline Feature Store" "Historical feature retrieval for batch scoring and training" "Python Service" {
                offlineAPI = component "Offline API" "REST endpoints for historical feature queries" "Python"
                pointInTime = component "Point-in-Time Engine" "Ensures data leakage prevention with temporal joins" "Python"
            }

            registry = container "Registry Server" "Centralized metadata repository for feature definitions" "Python gRPC/REST Service" {
                registryAPI = component "Registry API" "Feature schema and metadata management" "Python"
                registryStore = component "Metadata Store" "Persists feature definitions and versions" "Python"
            }

            ui = container "UI Server" "Web interface for feature discovery and registry exploration" "Python Web Service" "Optional"
            cronjob = container "Materialization CronJob" "Scheduled jobs for feature ingestion and materialization" "Kubernetes CronJob"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "Infrastructure"
        postgresql = softwareSystem "PostgreSQL" "Relational database for registry and online store" "External Dependency"
        redis = softwareSystem "Redis" "High-performance key-value store for online features" "External Dependency"
        s3 = softwareSystem "S3/GCS/Azure Blob" "Object storage for offline data and registry files" "External Dependency"
        snowflake = softwareSystem "Snowflake" "Cloud data warehouse for offline/online/registry storage" "External Dependency"
        git = softwareSystem "Git Repository" "Version control for feature definitions" "External Dependency"
        certManager = softwareSystem "cert-manager" "Automatic TLS certificate provisioning" "External Dependency"

        odhDashboard = softwareSystem "ODH Dashboard" "Centralized UI for data science platform" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Monitoring and alerting platform" "Internal ODH"
        openShiftOAuth = softwareSystem "OpenShift OAuth" "Authentication provider" "Internal ODH"
        serviceMesh = softwareSystem "Service Mesh" "mTLS and traffic management" "Internal ODH"
        trustedCA = softwareSystem "Trusted CA Bundle" "Certificate authority bundle for TLS trust" "Internal ODH"

        # User interactions
        dataScientist -> feast "Creates FeatureStore CR, defines features, monitors deployments" "kubectl/OpenShift Console"
        mlApplication -> onlineStore "Retrieves real-time features for inference" "HTTPS/443, gRPC/6566"
        trainingJob -> offlineStore "Fetches historical features for training" "HTTPS/443"

        # Operator interactions
        operator -> kubernetes "Manages Deployments, Services, ConfigMaps, PVCs, Routes" "Kubernetes API/6443"
        operator -> onlineStore "Monitors health and readiness" "HTTP/HTTPS"
        operator -> offlineStore "Monitors health and readiness" "HTTP/HTTPS"
        operator -> registry "Monitors health and readiness" "HTTP/HTTPS"
        operator -> ui "Monitors health and readiness" "HTTP/HTTPS"
        operator -> cronjob "Creates and manages CronJob schedules" "Kubernetes API/6443"

        # Feature service interactions
        onlineStore -> registry "Queries feature metadata and schemas" "gRPC/6570, HTTP/80"
        offlineStore -> registry "Queries feature metadata and schemas" "gRPC/6570, HTTP/80"
        cronjob -> onlineStore "Materializes computed features" "HTTP/HTTPS"
        cronjob -> offlineStore "Reads source data for materialization" "HTTP/HTTPS"

        # Storage backend connections
        onlineStore -> redis "Reads/writes feature values" "Redis Protocol/6379"
        onlineStore -> postgresql "Reads/writes feature values" "PostgreSQL/5432"
        offlineStore -> s3 "Reads Parquet files with historical data" "HTTPS/443"
        offlineStore -> postgresql "Queries historical data" "PostgreSQL/5432"
        offlineStore -> snowflake "Queries cloud data warehouse" "HTTPS/443"
        registry -> postgresql "Persists feature metadata" "PostgreSQL/5432"
        registry -> s3 "Stores registry files" "HTTPS/443"
        registry -> snowflake "Stores registry in cloud warehouse" "HTTPS/443"

        # External dependencies
        operator -> certManager "Requests TLS certificates" "Kubernetes API/6443"
        cronjob -> git "Syncs feature repository" "HTTPS/443"
        onlineStore -> openShiftOAuth "Validates OIDC tokens" "HTTPS/443"
        offlineStore -> openShiftOAuth "Validates OIDC tokens" "HTTPS/443"
        registry -> openShiftOAuth "Validates OIDC tokens" "HTTPS/443"
        ui -> openShiftOAuth "Validates OIDC tokens" "HTTPS/443"

        # ODH integrations
        odhDashboard -> feast "Discovers and displays FeatureStore instances" "Kubernetes API/6443"
        prometheus -> operator "Scrapes metrics" "HTTPS/8443"
        operator -> trustedCA "Injects CA certificates for TLS trust" "ConfigMap Injection"
        feast -> serviceMesh "Optional mTLS enforcement" "Istio Sidecar"
    }

    views {
        systemContext feast "FeastSystemContext" {
            include *
            autoLayout
        }

        container feast "FeastContainers" {
            include *
            autoLayout
        }

        component operator "FeastOperatorComponents" {
            include *
            autoLayout
        }

        component onlineStore "OnlineStoreComponents" {
            include *
            autoLayout
        }

        component offlineStore "OfflineStoreComponents" {
            include *
            autoLayout
        }

        component registry "RegistryComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Dependency" {
                background #cccccc
                color #000000
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Infrastructure" {
                background #ff6b6b
                color #ffffff
            }
            element "Optional" {
                background #95a5a6
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
            element "Component" {
                shape Component
            }
        }

        theme default
    }
}

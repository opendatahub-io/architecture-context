workspace {
    model {
        dataSciRBACist = person "Data Scientist" "Creates and deploys ML models that require features for training and inference"
        mlEngineer = person "ML Engineer" "Manages feature definitions and feature store infrastructure"

        feast = softwareSystem "Feast Feature Store" "Open-source feature store for managing ML features across training and serving" {
            operator = container "Feast Operator" "Manages FeatureStore CR lifecycle and deploys feature store services" "Go Operator"
            onlineStore = container "Online Feature Store" "Low-latency serving of pre-computed features for real-time inference" "Python Service"
            offlineStore = container "Offline Feature Store" "Historical feature retrieval for batch scoring and model training" "Python Service"
            registry = container "Registry Server" "Centralized metadata repository for feature definitions and schemas" "Python gRPC/REST Service"
            ui = container "UI Server" "Web interface for feature discovery and registry exploration" "Python Web Service"
            cronJob = container "Materialization CronJob" "Scheduled feature ingestion and materialization tasks" "Kubernetes CronJob"
        }

        # External dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for registry and online store persistence" "External"
        redis = softwareSystem "Redis" "In-memory data store for high-performance online feature serving" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for offline data and registry files" "External"
        snowflake = softwareSystem "Snowflake" "Cloud data warehouse for offline/online/registry storage" "External"
        certManager = softwareSystem "cert-manager" "Automatic TLS certificate provisioning" "External"

        # Internal ODH dependencies
        odhDashboard = softwareSystem "ODH Dashboard" "Unified UI for OpenShift AI components" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Monitoring and alerting platform" "Internal ODH"
        oauthProxy = softwareSystem "OpenShift OAuth" "Authentication and authorization service" "Internal ODH"

        # User interactions
        dataSciRBACist -> feast "Creates FeatureStore CR via kubectl"
        dataSciRBACist -> onlineStore "Retrieves real-time features for inference" "HTTPS/gRPC"
        dataSciRBACist -> offlineStore "Fetches historical features for training" "HTTPS"
        dataSciRBACist -> ui "Discovers and explores features" "HTTPS"
        mlEngineer -> feast "Manages feature definitions and store configuration"
        mlEngineer -> registry "Registers feature schemas and metadata" "HTTPS/gRPC"
        mlEngineer -> ui "Views and validates feature registry" "HTTPS"

        # Operator interactions
        operator -> kubernetes "Creates and manages Deployments, Services, ConfigMaps, Routes" "HTTPS/6443"
        operator -> onlineStore "Deploys and configures"
        operator -> offlineStore "Deploys and configures"
        operator -> registry "Deploys and configures"
        operator -> ui "Deploys and configures"
        operator -> cronJob "Creates and schedules"

        # Feature store interactions
        onlineStore -> redis "Reads/writes pre-computed features" "Redis Protocol/6379"
        onlineStore -> postgresql "Reads/writes features" "PostgreSQL/5432"
        onlineStore -> registry "Queries feature metadata" "gRPC/HTTP"

        offlineStore -> s3 "Reads historical Parquet files" "HTTPS/443"
        offlineStore -> snowflake "Queries historical data" "HTTPS/443"
        offlineStore -> postgresql "Queries historical features" "PostgreSQL/5432"
        offlineStore -> registry "Queries feature definitions" "gRPC/HTTP"

        registry -> postgresql "Stores feature metadata" "PostgreSQL/5432"
        registry -> s3 "Stores registry database file" "HTTPS/443"

        ui -> registry "Displays feature metadata" "gRPC/HTTP"

        cronJob -> offlineStore "Fetches latest features" "HTTP"
        cronJob -> onlineStore "Materializes features" "HTTP"

        # External integrations
        feast -> odhDashboard "Appears in component list for discovery"
        feast -> prometheus "Exposes operator metrics" "HTTPS/8443"
        feast -> oauthProxy "Authenticates users" "HTTPS/443"
        feast -> certManager "Requests TLS certificates" "Kubernetes API"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6ba3d9
                color #ffffff
            }
            element "Person" {
                background #f5a623
                color #ffffff
                shape person
            }
        }

        themes default
    }
}

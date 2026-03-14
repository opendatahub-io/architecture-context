workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models and needs consistent features for training and inference"
        mlEngineer = person "ML Engineer" "Deploys and monitors ML models in production"
        dataEngineer = person "Data Engineer" "Manages feature pipelines and data quality"

        feast = softwareSystem "Feast Feature Store" "Provides centralized feature management for ML workflows with online/offline serving" {
            operator = container "Feast Operator" "Manages FeatureStore CR lifecycle and service deployment" "Go Operator"
            onlineStore = container "Online Feature Store" "Low-latency feature serving for real-time inference" "Python Service"
            offlineStore = container "Offline Feature Store" "Historical feature retrieval for model training" "Python Service"
            registry = container "Registry Server" "Centralized metadata repository for feature definitions" "Python gRPC/REST Service"
            ui = container "UI Server" "Web interface for feature discovery and exploration" "Python Web Service"
            cronJob = container "Materialization CronJob" "Scheduled feature materialization and maintenance" "Kubernetes CronJob"
        }

        k8s = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        odhDashboard = softwareSystem "ODH Dashboard" "Unified dashboard for data science tools" "Internal ODH"
        certManager = softwareSystem "cert-manager" "Automatic TLS certificate provisioning" "External"

        postgres = softwareSystem "PostgreSQL" "Persistent database for registry and online store" "External"
        redis = softwareSystem "Redis" "High-performance key-value store for online features" "External"
        s3 = softwareSystem "S3 / GCS" "Object storage for offline data and registry files" "External"
        snowflake = softwareSystem "Snowflake" "Cloud data warehouse for online/offline/registry" "External"
        oidcProvider = softwareSystem "OIDC Provider" "Authentication and authorization (e.g., OpenShift OAuth)" "External"
        gitRepo = softwareSystem "Git Repository" "Version control for feature definitions" "External"

        mlApplication = softwareSystem "ML Application" "Production application serving real-time predictions" "External"
        trainingPipeline = softwareSystem "Training Pipeline" "Model training workflows (e.g., Kubeflow, DSP)" "Internal ODH"

        %% User interactions
        dataScientist -> feast "Creates FeatureStore CR, defines features via kubectl/UI"
        mlEngineer -> feast "Configures feature serving and monitoring"
        dataEngineer -> feast "Manages feature pipelines and materialization"

        %% Feast dependencies
        feast -> k8s "Deploys and manages feature store services" "HTTPS/6443"
        feast -> prometheus "Exposes operator and service metrics" "HTTPS/8443"
        feast -> postgres "Persists registry metadata and online features" "PostgreSQL/5432"
        feast -> redis "Stores online features for low-latency access" "Redis/6379"
        feast -> s3 "Reads/writes offline data and registry files" "HTTPS/443"
        feast -> snowflake "Integrates with cloud data warehouse" "HTTPS/443"
        feast -> oidcProvider "Authenticates users and services" "HTTPS/443"
        feast -> gitRepo "Syncs feature repository definitions" "HTTPS/443"
        feast -> certManager "Requests TLS certificates for HTTPS endpoints" "HTTPS/6443"

        %% ODH integrations
        odhDashboard -> feast "Displays feature store instances for discovery" "HTTP/HTTPS"
        trainingPipeline -> feast "Fetches historical features for model training" "HTTP/HTTPS"

        %% External applications
        mlApplication -> feast "Retrieves online features for inference" "HTTPS/443"

        %% Container-level relationships
        operator -> k8s "Creates Deployments, Services, ConfigMaps, PVCs, Routes" "HTTPS/6443"
        operator -> onlineStore "Manages lifecycle"
        operator -> offlineStore "Manages lifecycle"
        operator -> registry "Manages lifecycle"
        operator -> ui "Manages lifecycle"
        operator -> cronJob "Manages lifecycle"

        onlineStore -> redis "Reads/writes pre-computed features"
        onlineStore -> postgres "Reads/writes online features"
        onlineStore -> registry "Queries feature metadata"

        offlineStore -> s3 "Reads historical Parquet data"
        offlineStore -> snowflake "Queries historical features"
        offlineStore -> registry "Queries feature definitions"

        registry -> postgres "Persists feature metadata"
        registry -> s3 "Stores registry database files"

        cronJob -> onlineStore "Writes materialized features"
        cronJob -> offlineStore "Fetches feature data"

        mlApplication -> onlineStore "POST /get-online-features"
        trainingPipeline -> offlineStore "POST /get-historical-features"
        dataScientist -> ui "Browses feature registry"
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
                background #7ed321
                color #000000
            }
        }

        theme default
    }
}

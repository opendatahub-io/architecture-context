workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML feature stores, defines features, and deploys feature serving infrastructure"
        mlApplication = person "ML Application" "Production ML model or pipeline consuming online features for inference"

        feast = softwareSystem "Feast" "Feature store platform for managing, storing, and serving ML features at scale" {
            feastOperator = container "feast-operator" "Manages FeatureStore CRDs, deploys and configures feature serving infrastructure" "Go Operator (controller-runtime)" "operator"
            featureServer = container "Feature Server" "Serves online features via REST/gRPC APIs, handles materialization" "Python (FastAPI/Gunicorn/Uvicorn)" "server"
            feastRegistry = container "Feast Registry" "Stores feature definitions, metadata, and permission policies" "Python (gRPC + REST)" "registry"
            feastUI = container "Feast UI" "Web UI for feature store exploration and permissions management" "React (TypeScript)" "ui"
            materializationCronJob = container "Materialization CronJob" "Periodically materializes features from offline to online store" "Kubernetes CronJob" "cronjob"
        }

        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        openshiftApi = softwareSystem "OpenShift API" "OpenShift-specific APIs for TLS profiles, routes, service certs" "External"
        rhodsOperator = softwareSystem "RHOAI Operator" "Deploys feast-operator via component manifests" "Internal Platform"
        sparkOperator = softwareSystem "Spark Operator" "Manages SparkApplication CRs for batch compute" "Internal Platform"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics scraping configuration via ServiceMonitor CRDs" "Internal Platform"
        odhNotebooks = softwareSystem "ODH Notebooks" "Jupyter notebook environment for data scientists" "Internal Platform"
        oidcProvider = softwareSystem "OIDC Provider" "Identity provider (Keycloak, Dex) for user authentication" "External"

        redis = softwareSystem "Redis" "In-memory data store for online features" "External Store"
        postgresql = softwareSystem "PostgreSQL" "Relational database for online/offline feature storage" "External Store"
        dynamodb = softwareSystem "DynamoDB" "AWS managed NoSQL database for online features" "External Store"
        bigTable = softwareSystem "Google BigTable" "GCP managed wide-column store for online features" "External Store"
        snowflake = softwareSystem "Snowflake" "Cloud data warehouse for offline feature queries" "External Store"
        cloudStorage = softwareSystem "S3 / GCS / Azure Blob" "Object storage for registry persistence" "External Store"
        gitRepos = softwareSystem "Git Repositories" "Source code repositories hosting feature definitions" "External"

        # Person relationships
        dataScientist -> feast "Creates FeatureStore CRs, defines features" "kubectl / CLI"
        dataScientist -> feastUI "Browses features and manages permissions" "HTTPS/443"
        mlApplication -> featureServer "Retrieves online features for inference" "HTTP/6566 or HTTPS/6567"

        # Internal container relationships
        feastOperator -> k8sApi "Watches CRDs, creates resources" "HTTPS/443, SA Token"
        feastOperator -> openshiftApi "Fetches TLS profile, detects cluster type" "HTTPS/443, SA Token"
        feastOperator -> feastRegistry "Fetches permission policies for auto-access RBAC" "HTTP/6572, JWT"
        featureServer -> feastRegistry "Resolves feature definitions and permissions" "gRPC/6570, JWT"
        featureServer -> oidcProvider "Validates user tokens" "HTTPS/443"
        feastUI -> feastRegistry "Reads feature metadata" "HTTP/6572"
        materializationCronJob -> feastRegistry "Fetches feature definitions" "gRPC/6570, JWT"

        # External store relationships
        featureServer -> redis "Reads/writes online features" "TCP/6379"
        featureServer -> postgresql "Reads/writes features" "TCP/5432, TLS"
        featureServer -> dynamodb "Reads/writes online features" "HTTPS/443, IAM"
        featureServer -> bigTable "Reads/writes online features" "HTTPS/443, GCP SA"
        featureServer -> cloudStorage "Persists registry data" "HTTPS/443"
        materializationCronJob -> postgresql "Reads offline features" "TCP/5432, TLS"
        materializationCronJob -> redis "Writes materialized features" "TCP/6379"

        # Platform relationships
        rhodsOperator -> feast "Deploys feast-operator via Kustomize manifests" "Kustomize"
        feastOperator -> sparkOperator "Creates SparkApplication CRs" "Kubernetes API"
        feastOperator -> prometheusOperator "Creates ServiceMonitor CRs" "Kubernetes API"
        feastOperator -> odhNotebooks "Creates Feast client ConfigMaps" "Kubernetes API"
        feastOperator -> gitRepos "Clones feature definitions" "HTTPS/443 or SSH/22"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Store" {
                background #d4a017
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "operator" {
                background #4a90e2
            }
            element "server" {
                background #50a14f
            }
            element "registry" {
                background #e5a00d
            }
            element "ui" {
                background #9b59b6
            }
            element "cronjob" {
                background #e67e22
            }
        }
    }
}

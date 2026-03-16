workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models and consumes features for training"
        mlEngineer = person "ML Engineer" "Deploys and manages ML inference services"

        feast = softwareSystem "Feast Feature Store" "Provides centralized feature management and serving for ML workloads" {
            operator = container "Feast Operator" "Manages Feast deployments via FeatureStore CRs" "Go Operator" {
                tags "Operator"
            }

            onlineServer = container "Online Feature Server" "Low-latency real-time feature serving for inference" "Python Service" {
                tags "FeatureServer"
            }

            offlineServer = container "Offline Feature Server" "Historical feature data for training and batch processing" "Python Service" {
                tags "FeatureServer"
            }

            registryServer = container "Registry Server" "Feature metadata and configuration management" "Python Service (gRPC/HTTP)" {
                tags "FeatureServer"
            }

            ui = container "Feast UI" "Web interface for feature discovery and exploration" "Python/React" {
                tags "UI"
            }

            cronJob = container "Materialization CronJob" "Scheduled feature materialization from offline to online stores" "Kubernetes CronJob" {
                tags "CronJob"
            }
        }

        kubernetes = softwareSystem "Kubernetes API" "Container orchestration platform" "External" {
            tags "External"
        }

        s3 = softwareSystem "S3-compatible Storage" "Object storage for feature data and registry" "External" {
            tags "External"
        }

        database = softwareSystem "Database" "Relational database for feature registry and online store (PostgreSQL/Snowflake)" "External" {
            tags "External"
        }

        onlineStoreBackend = softwareSystem "Online Store Backend" "Low-latency key-value store (Redis/Cassandra/DynamoDB)" "External" {
            tags "External"
        }

        oidcProvider = softwareSystem "OIDC Provider" "User authentication (OpenShift OAuth/Keycloak)" "External" {
            tags "External"
        }

        git = softwareSystem "Git Repository" "Feature definition source control" "External" {
            tags "External"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "ODH Platform" {
            tags "ODH"
        }

        serviceMesh = softwareSystem "Service Mesh (Istio)" "mTLS and traffic management (optional)" "ODH Platform" {
            tags "ODH"
        }

        certManager = softwareSystem "cert-manager" "TLS certificate management (optional)" "ODH Platform" {
            tags "ODH"
        }

        mlInferenceService = softwareSystem "ML Inference Service" "Deployed ML models consuming real-time features" "ODH Component" {
            tags "ODH"
        }

        jupyterNotebook = softwareSystem "Jupyter Notebook" "Interactive development environment for data scientists" "ODH Component" {
            tags "ODH"
        }

        # Relationships - Users
        dataScientist -> ui "Browses and explores features"
        dataScientist -> jupyterNotebook "Develops models and retrieves training features"
        dataScientist -> operator "Creates FeatureStore CRs via kubectl"
        mlEngineer -> operator "Manages Feast deployments"

        # Relationships - Feast Internal
        operator -> onlineServer "Creates and manages deployment"
        operator -> offlineServer "Creates and manages deployment"
        operator -> registryServer "Creates and manages deployment"
        operator -> ui "Creates and manages deployment"
        operator -> cronJob "Creates and manages CronJob"

        onlineServer -> registryServer "Fetches feature metadata" "gRPC/HTTP"
        offlineServer -> registryServer "Fetches feature metadata" "gRPC/HTTP"
        cronJob -> registryServer "Fetches feature definitions" "HTTP"
        cronJob -> offlineServer "Reads latest features" "HTTP/HTTPS"
        cronJob -> onlineServer "Pushes features to online store" "HTTP/HTTPS"
        ui -> registryServer "Queries feature metadata" "gRPC/HTTP"

        # Relationships - External Systems
        operator -> kubernetes "Manages Kubernetes resources (Deployments, Services, ConfigMaps, RBAC)" "HTTPS/6443"

        onlineServer -> onlineStoreBackend "Stores and retrieves real-time features" "Native Protocol"
        offlineServer -> s3 "Reads historical feature data" "HTTPS/443"
        offlineServer -> database "Queries historical features" "Postgres/HTTPS"
        registryServer -> s3 "Persists feature metadata" "HTTPS/443"
        registryServer -> database "Persists feature metadata" "Postgres/HTTPS"
        registryServer -> git "Syncs feature definitions (optional)" "HTTPS/SSH"

        onlineServer -> oidcProvider "Validates JWT tokens for authentication" "HTTPS/443"
        offlineServer -> oidcProvider "Validates JWT tokens for authentication" "HTTPS/443"
        registryServer -> oidcProvider "Validates JWT tokens for authentication" "HTTPS/443"
        ui -> oidcProvider "Validates JWT tokens for authentication" "HTTPS/443"

        prometheus -> operator "Scrapes operator metrics" "HTTPS/8443"

        operator -> certManager "Requests TLS certificates (optional)" "K8s API"
        operator -> serviceMesh "Integrates for mTLS (optional)" "K8s API"

        # Relationships - ML Workloads
        mlInferenceService -> onlineServer "Retrieves real-time features for predictions" "HTTP/HTTPS"
        jupyterNotebook -> offlineServer "Retrieves historical features for training" "HTTP/HTTPS"
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

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "FeatureServer" {
                background #7ed321
                color #ffffff
            }
            element "UI" {
                background #f5a623
                color #ffffff
            }
            element "CronJob" {
                background #bd10e0
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "ODH" {
                background #50e3c2
                color #000000
            }
        }
    }
}

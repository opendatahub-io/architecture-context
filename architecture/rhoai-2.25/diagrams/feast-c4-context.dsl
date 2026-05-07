workspace {
    model {
        datascientist = person "Data Scientist" "Creates FeatureStore CRs and consumes ML features"
        mlapplication = person "ML Application" "Retrieves online features for inference"

        feast = softwareSystem "Feast" "Feature store for ML - manages feature serving infrastructure on Kubernetes" {
            operator = container "Feast Operator" "Manages FeatureStore CRDs, deploys and reconciles feature serving infrastructure" "Go Operator (controller-runtime)" "operator"
            onlineServer = container "Feature Server (Online)" "Serves ML features via REST/gRPC for real-time inference" "Python FastAPI / Go embedded" "server"
            offlineServer = container "Feature Server (Offline)" "Serves historical feature data for training" "Python FastAPI" "server"
            registryServer = container "Feature Server (Registry)" "Stores and serves feature definitions and metadata" "Python FastAPI + gRPC" "server"
            uiServer = container "Feast UI" "Web interface for browsing feature store metadata" "React/TypeScript" "ui"
            cronJob = container "Materialization CronJob" "Periodically materializes features from offline to online store" "origin-cli (kubectl exec)" "job"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster orchestration and resource management" "External"
        openshiftRoutes = softwareSystem "OpenShift Route API" "External traffic ingress via Routes" "External"
        openshiftCerts = softwareSystem "OpenShift Service Serving Certs" "Automatic TLS certificate provisioning" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        redis = softwareSystem "Redis" "In-memory data store for online features" "External Store"
        postgresql = softwareSystem "PostgreSQL" "Relational database for online/offline features" "External Store"
        dynamodb = softwareSystem "AWS DynamoDB" "Managed NoSQL for online features" "External Store"
        s3 = softwareSystem "AWS S3" "Object storage for registry and model artifacts" "External Store"
        gcs = softwareSystem "Google Cloud Storage" "Object storage for registry/offline data" "External Store"
        snowflake = softwareSystem "Snowflake" "Cloud data warehouse for offline features" "External Store"

        oidcProvider = softwareSystem "OIDC Identity Provider" "Token validation for authentication" "External"
        containerRegistry = softwareSystem "Container Registry" "Stores container images (quay.io)" "External"
        transformationSvc = softwareSystem "Transformation Service" "On-demand feature transformations" "External"

        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator that deploys feast-operator" "Internal RHOAI"

        // Relationships
        datascientist -> feast "Creates FeatureStore CR via kubectl/dashboard"
        mlapplication -> onlineServer "POST /get-online-features" "HTTPS/443 via Route"

        rhoaiOperator -> operator "Deploys via kustomize overlays"

        operator -> k8sApi "CRUD managed resources" "HTTPS/6443 SA Token"
        operator -> openshiftRoutes "Create/manage Routes" "HTTPS/6443 SA Token"
        operator -> openshiftCerts "Annotates Services for TLS" "Annotation-driven"
        operator -> containerRegistry "Pulls images" "HTTPS/443 Pull secret"

        onlineServer -> redis "Read/write features" "TCP/6379 Optional TLS"
        onlineServer -> postgresql "Read/write features" "TCP/5432 Optional TLS"
        onlineServer -> dynamodb "Read/write features" "HTTPS/443 AWS IAM"
        onlineServer -> transformationSvc "On-demand transforms" "gRPC (insecure)"
        onlineServer -> oidcProvider "Validate tokens" "HTTPS/443"

        registryServer -> s3 "Registry storage" "HTTPS/443 AWS IAM"
        registryServer -> gcs "Registry storage" "HTTPS/443 GCP creds"

        offlineServer -> postgresql "Historical features" "TCP/5432 Optional TLS"
        offlineServer -> snowflake "Historical features" "HTTPS/443"

        cronJob -> onlineServer "kubectl exec: feast materialize" "In-cluster, SA Token"

        prometheus -> operator "Scrape metrics" "HTTPS/8443"
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
            element "External Store" {
                background #f5a623
                color #333333
            }
            element "Internal RHOAI" {
                background #7ed321
                color #333333
            }
            element "operator" {
                background #4a90e2
                color #ffffff
            }
            element "server" {
                background #4a90e2
                color #ffffff
            }
            element "ui" {
                background #50e3c2
                color #333333
            }
            element "job" {
                background #bd10e0
                color #ffffff
            }
        }
    }
}

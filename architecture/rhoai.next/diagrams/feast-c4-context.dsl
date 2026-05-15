workspace {
    model {
        dataScientist = person "Data Scientist" "Creates FeatureStore CRs, defines features, queries feature data from notebooks"
        mlEngineer = person "ML Engineer" "Deploys and manages Feast feature stores, configures backends and auth"
        inferenceClient = person "ML Inference Client" "Applications that retrieve online features for real-time predictions"

        feast = softwareSystem "Feast" "Feature store platform for ML feature lifecycle management: registration, storage, serving, and materialization" {
            feastOperator = container "feast-operator" "Manages FeatureStore CRDs, deploys and configures all Feast services on Kubernetes" "Go Operator (controller-runtime)" {
                featureStoreCtrl = component "FeatureStore Controller" "Watches FeatureStore CRDs, reconciles Deployments, Services, RBAC, HPAs, PDBs, CronJobs" "Go"
                notebookCtrl = component "Notebook ConfigMap Controller" "Watches Kubeflow Notebooks, provides feast config via ConfigMap" "Go"
                accessManager = component "Access Manager" "Queries registry permissions, creates K8s RBAC for auto-access" "Go"
                tlsManager = component "TLS Manager" "Handles OpenShift service-serving certs and manual TLS" "Go"
            }
            onlineServer = container "Online Feature Server" "Serves online features via REST/gRPC with embedded Go server for high throughput" "Python (FastAPI) + Go" {
                tags "FeatureServer"
            }
            offlineServer = container "Offline Feature Server" "Serves batch features via Apache Arrow Flight protocol" "Python" {
                tags "FeatureServer"
            }
            registryServer = container "Registry Server" "Feature metadata CRUD via gRPC (40+ RPCs) and REST API" "Python (gRPC + FastAPI)" {
                tags "FeatureServer"
            }
            feastUI = container "Feast UI" "Web interface for browsing feature store metadata" "Python" {
                tags "FeatureServer"
            }
            materializationCronJob = container "Materialization CronJob" "Scheduled jobs to materialize features from offline to online store" "ose-cli container"
        }

        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator (rhods-operator) that deploys Feast via kustomize overlays" "Internal Platform" {
            tags "Internal"
        }
        odhDashboard = softwareSystem "ODH Dashboard / Notebooks" "Kubeflow notebooks with Feast integration label" "Internal Platform" {
            tags "Internal"
        }

        kubernetes = softwareSystem "Kubernetes API" "Cluster control plane for resource management" "External" {
            tags "Infrastructure"
        }
        openshift = softwareSystem "OpenShift Platform" "Service-serving certificates, Routes, cluster detection" "External" {
            tags "Infrastructure"
        }

        redis = softwareSystem "Redis" "In-memory data store for online feature storage (single/cluster)" "External" {
            tags "DataStore"
        }
        postgresql = softwareSystem "PostgreSQL" "Relational database for online/offline store and SQL registry" "External" {
            tags "DataStore"
        }
        dynamodb = softwareSystem "AWS DynamoDB" "Managed NoSQL for online feature storage" "External" {
            tags "CloudService"
        }
        bigquery = softwareSystem "Google BigQuery" "Serverless data warehouse for offline feature retrieval" "External" {
            tags "CloudService"
        }
        s3 = softwareSystem "AWS S3" "Object storage for registry metadata" "External" {
            tags "CloudService"
        }
        gcs = softwareSystem "Google Cloud Storage" "Object storage for registry metadata" "External" {
            tags "CloudService"
        }
        snowflake = softwareSystem "Snowflake" "Cloud data platform for online/offline store and registry" "External" {
            tags "CloudService"
        }
        oidcProvider = softwareSystem "OIDC Provider" "Identity provider for token validation via JWKS endpoint" "External" {
            tags "Security"
        }

        # Relationships - Users
        dataScientist -> feast "Creates FeatureStore CRs, queries features via SDK" "kubectl, Python SDK"
        mlEngineer -> feast "Manages feature store infrastructure" "kubectl, CLI"
        inferenceClient -> onlineServer "Retrieves online features" "HTTP/gRPC, 6566/TCP"

        # Relationships - Internal Platform
        rhoaiOperator -> feastOperator "Deploys via kustomize overlays" "Kustomize"
        odhDashboard -> feast "Notebooks query features" "Python SDK"

        # Relationships - Operator
        feastOperator -> kubernetes "Watches CRDs, manages resources" "HTTPS/6443, SA token"
        feastOperator -> openshift "Creates Routes, detects cluster type" "HTTPS/6443, SA token"
        feastOperator -> registryServer "Fetches permission policies" "HTTP/6572, JWT"

        # Relationships - Feature Servers → Stores
        onlineServer -> redis "Read/write online features" "TCP/6379, Password"
        onlineServer -> postgresql "Read/write features" "TCP/5432, User/Pass"
        onlineServer -> dynamodb "Read/write online features" "HTTPS/443, AWS IAM"
        offlineServer -> bigquery "Query historical features" "HTTPS/443, GCP SA"
        offlineServer -> snowflake "Query features" "HTTPS/443, Snowflake creds"
        registryServer -> s3 "Store/retrieve registry metadata" "HTTPS/443, AWS IAM"
        registryServer -> gcs "Store/retrieve registry metadata" "HTTPS/443, GCP SA"
        registryServer -> postgresql "SQL registry backend" "TCP/5432, User/Pass"

        # Relationships - Auth
        onlineServer -> oidcProvider "Validates OIDC tokens" "HTTPS/443, JWKS"
        offlineServer -> oidcProvider "Validates OIDC tokens" "HTTPS/443, JWKS"
        registryServer -> oidcProvider "Validates OIDC tokens" "HTTPS/443, JWKS"

        # Relationships - Materialization
        materializationCronJob -> registryServer "Fetch feature definitions" "gRPC/6570, SA token"
        materializationCronJob -> bigquery "Read historical features" "HTTPS/443"
        materializationCronJob -> redis "Write materialized features" "TCP/6379"
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

        component feastOperator "OperatorComponents" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "DataStore" {
                background #f5a623
                color #ffffff
                shape cylinder
            }
            element "CloudService" {
                background #ff6b6b
                color #ffffff
            }
            element "Security" {
                background #9b59b6
                color #ffffff
            }
            element "FeatureServer" {
                background #50c878
                color #ffffff
            }
        }
    }
}

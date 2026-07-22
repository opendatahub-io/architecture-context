workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML feature stores, defines feature views and entities"
        mlEngineer = person "ML Engineer" "Deploys inference services that consume online features"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and Feast operator installation"

        feast = softwareSystem "Feast" "Feature store platform for managing, storing, and serving ML features on Kubernetes/OpenShift" {
            feastOperator = container "feast-operator" "Manages FeatureStore CRs, deploys and configures all Feast services" "Go Operator (controller-runtime)" "operator"
            onlineServer = container "Online Store Server" "Serves online features via REST and gRPC" "Python (FastAPI/Gunicorn)" "server"
            offlineServer = container "Offline Store Server" "Serves historical feature data" "Python (FastAPI/Gunicorn)" "server"
            registryServer = container "Registry Server" "Feature metadata CRUD via gRPC and REST" "Python (gRPC/FastAPI)" "server"
            uiServer = container "UI Server" "Web UI for browsing feature store metadata" "TypeScript/React" "server"
            securityManager = container "SecurityManager" "Enforces OIDC/K8s auth and Feast permission policies" "Python" "security"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Container orchestration platform" "Platform"
        openshiftAPI = softwareSystem "OpenShift API" "Route, APIServer CR, service serving certs" "Platform"
        kubeflowNotebook = softwareSystem "Kubeflow Notebooks" "Jupyter notebook management on Kubernetes" "Internal RHOAI"
        sparkOperator = softwareSystem "Spark Operator" "Manages SparkApplication CRs for batch computation" "Internal RHOAI"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages ServiceMonitors for metrics scraping" "Platform"
        odhDashboard = softwareSystem "OpenDataHub Dashboard" "RHOAI management console" "Internal RHOAI"

        redis = softwareSystem "Redis" "In-memory online feature store backend" "External Store"
        postgresql = softwareSystem "PostgreSQL" "Relational database for online/offline store and registry" "External Store"
        dynamodb = softwareSystem "AWS DynamoDB" "Cloud-managed online store backend" "External Store"
        snowflake = softwareSystem "Snowflake" "Cloud data warehouse for offline store and registry" "External Store"
        bigquery = softwareSystem "Google BigQuery" "Cloud data warehouse for offline store" "External Store"
        bigtable = softwareSystem "Google Cloud Bigtable" "Cloud-managed online store backend" "External Store"
        oidcProvider = softwareSystem "OIDC Provider" "Identity provider for token validation and JWKS" "External"
        openlineage = softwareSystem "OpenLineage" "Data lineage event collection" "External"

        # User interactions
        dataScientist -> feast "Creates FeatureStore CR via kubectl"
        mlEngineer -> onlineServer "POST /get-online-features (Bearer token)" "HTTPS/443"
        platformAdmin -> feastOperator "Installs and configures operator"

        # Internal flows
        feastOperator -> kubernetesAPI "Manages Deployments, Services, RBAC, CronJobs" "HTTPS/443"
        feastOperator -> registryServer "Fetches permission policies" "HTTP(S)/6572-6573 (Intra-comm JWT)"
        feastOperator -> openshiftAPI "Creates Routes, fetches TLS profile" "HTTPS/443"
        feastOperator -> kubeflowNotebook "Watches Notebooks for ConfigMap injection" "HTTPS/443"
        feastOperator -> sparkOperator "Creates SparkApplication CRs" "HTTPS/443"
        feastOperator -> prometheusOperator "Creates ServiceMonitors" "HTTPS/443"

        feastOperator -> onlineServer "Creates and manages Deployment"
        feastOperator -> offlineServer "Creates and manages Deployment"
        feastOperator -> registryServer "Creates and manages Deployment"
        feastOperator -> uiServer "Creates and manages Deployment"

        onlineServer -> securityManager "Validates auth tokens"
        offlineServer -> securityManager "Validates auth tokens"
        registryServer -> securityManager "Validates auth tokens"

        # External service connections
        onlineServer -> redis "Read/write feature values" "Redis/6379 (TLS optional)"
        onlineServer -> postgresql "Read/write feature values" "PostgreSQL/5432"
        onlineServer -> dynamodb "Read/write feature values" "HTTPS/443"
        offlineServer -> snowflake "Read historical features" "HTTPS/443"
        offlineServer -> bigquery "Read historical features" "HTTPS/443"
        offlineServer -> postgresql "Read historical features" "PostgreSQL/5432"
        registryServer -> postgresql "Feature metadata CRUD" "PostgreSQL/5432"
        registryServer -> snowflake "Feature metadata CRUD" "HTTPS/443"
        securityManager -> oidcProvider "Token validation, JWKS retrieval" "HTTPS/443"
        onlineServer -> openlineage "Lineage event emission" "HTTP(S)"

        odhDashboard -> feast "Discovers via namespace labels" "opendatahub.io/feast: true"
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
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Store" {
                background #f5a623
                color #ffffff
            }
            element "operator" {
                background #4a90e2
                color #ffffff
                shape hexagon
            }
            element "server" {
                background #7ed321
                color #ffffff
            }
            element "security" {
                background #e74c3c
                color #ffffff
            }
        }
    }
}

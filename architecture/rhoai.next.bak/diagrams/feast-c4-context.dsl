workspace {
    model {
        dataScientist = person "Data Scientist" "Creates feature definitions, retrieves features for training and inference"
        platformAdmin = person "Platform Admin" "Deploys and manages FeatureStore CRs via RHOAI/ODH"

        feast = softwareSystem "Feast Feature Store" "Open-source feature store for ML — manages storage, retrieval, and serving of features for training and online inference" {
            feastOperator = container "Feast Operator" "Manages FeatureStore CRD lifecycle, deploys feature store services, handles RBAC, TLS, scaling, monitoring" "Go (controller-runtime)"
            featureServerPython = container "Feature Server (Python)" "Online feature serving (REST), registry (gRPC+REST), offline store, UI host" "Python (FastAPI/Gunicorn)"
            featureServerGo = container "Feature Server (Go)" "High-performance online feature serving via HTTP/gRPC" "Go"
            feastUI = container "Feast UI" "Web UI for browsing feature views, entities, data sources, feature services" "React (TypeScript)"
            materializationCronJob = container "Materialization CronJob" "Scheduled materialization of features from offline to online store" "ose-cli + feast SDK"
        }

        rhoaiOperator = softwareSystem "RHOAI / ODH Operator" "Platform operator that deploys feast-operator via Kustomize manifests" "Internal Platform"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Interactive notebook environments for data science" "Internal Platform"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring stack, scrapes metrics via ServiceMonitors" "Internal Platform"
        openshiftRouteAPI = softwareSystem "OpenShift Route API" "Exposes services externally via Routes" "Internal Platform"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Auto-provisions TLS certificates for services" "Internal Platform"

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for registry/store persistence" "External"
        redis = softwareSystem "Redis" "In-memory data store for online feature serving" "External"
        snowflake = softwareSystem "Snowflake" "Cloud data warehouse for offline/online store" "External"
        dynamodb = softwareSystem "AWS DynamoDB" "NoSQL database for online store" "External"
        bigquery = softwareSystem "GCP BigQuery" "Cloud data warehouse for offline store" "External"
        oidcProvider = softwareSystem "OIDC Provider" "Identity provider for token validation" "External"
        s3Storage = softwareSystem "Object Storage (S3)" "Feature repository / artifact storage" "External"

        # User relationships
        dataScientist -> feast "Retrieves features, pushes data, browses UI" "HTTP/HTTPS, gRPC"
        platformAdmin -> feast "Creates FeatureStore CRs" "kubectl"

        # Platform relationships
        rhoaiOperator -> feastOperator "Deploys via Kustomize manifests" "Kustomize"
        feastOperator -> kubernetesAPI "CRUD on managed resources" "HTTPS/443, SA token"
        feastOperator -> featureServerPython "Deploys and manages" "Kubernetes Deployment"
        feastOperator -> featureServerGo "Deploys and manages (optional)" "Kubernetes Deployment"
        feastOperator -> materializationCronJob "Creates and manages" "Kubernetes CronJob"
        feastOperator -> openshiftRouteAPI "Creates Routes for UI exposure" "HTTPS/443"
        feastOperator -> prometheusOperator "Creates ServiceMonitors" "HTTPS/443"
        feastOperator -> openshiftServiceCA "TLS cert provisioning via annotations" "Annotation-based"
        feastOperator -> featureServerPython "Fetches permissions (intra-comm)" "HTTP(S), HMAC-SHA256 JWT"

        kubeflowNotebooks -> featureServerPython "Retrieves features via Feast SDK" "HTTP(S)/6566"
        feastOperator -> kubeflowNotebooks "Watches Notebook CRs, creates ConfigMaps" "Kubernetes API"

        feastUI -> featureServerPython "Queries feature metadata" "REST/6572"

        # Data store relationships
        featureServerPython -> postgresql "Registry/store persistence" "TCP/5432, Password"
        featureServerPython -> redis "Online store backend" "TCP/6379, Password"
        featureServerPython -> snowflake "Offline/online store" "HTTPS/443, Account creds"
        featureServerPython -> dynamodb "Online store" "HTTPS/443, AWS IAM"
        featureServerPython -> bigquery "Offline store" "HTTPS/443, GCP creds"
        featureServerPython -> oidcProvider "Token validation" "HTTPS/443, Client creds"

        featureServerGo -> redis "Online store backend" "TCP/6379"

        materializationCronJob -> featureServerPython "feast apply + materialize" "In-process"

        # External client
        dataScientist -> featureServerPython "POST /get-online-features" "HTTP(S)/6566, Bearer JWT"
        dataScientist -> feastUI "Browse features" "HTTPS/443 (via Route)"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates feature definitions, manages feature stores, and browses feature metadata via UI"
        mlApp = person "ML Application" "Retrieves features for online inference and training"

        feast = softwareSystem "Feast" "Open-source feature store for ML - manages storage, retrieval, and serving of features for model training and online inference" {
            feastOperator = container "feast-operator" "Manages FeatureStore CRD lifecycle, deploys and configures all Feast services on Kubernetes" "Go Operator (controller-runtime)" {
                featureStoreReconciler = component "FeatureStore Reconciler" "Watches FeatureStore CRs and reconciles Deployments, Services, RBAC, CronJobs, PVCs, Routes, HPAs" "controller-runtime"
                notebookController = component "Notebook ConfigMap Controller" "Watches kubeflow.org/Notebook CRs and auto-creates feast config ConfigMaps" "controller-runtime"
                autoAccessRBAC = component "Auto-Access RBAC" "Periodically fetches permission policies from registry and creates corresponding Kubernetes RBAC" "Go goroutine"
            }
            featureServer = container "feature-server" "Runs Feast SDK services: online serving, offline store access, registry management, and UI" "Python (FastAPI/gRPC/uvicorn)" {
                onlineStore = component "Online Store" "Low-latency feature retrieval via gRPC (ports 6566/6567)" "gRPC Server"
                offlineStore = component "Offline Store" "Historical feature retrieval via gRPC (ports 8815/8816)" "gRPC Server"
                registry = component "Registry" "Feature metadata CRUD via gRPC (6570/6571) and REST (6572/6573)" "FastAPI + gRPC"
                ui = component "Web UI" "Feature store browsing, data quality monitoring, lineage visualization (ports 8888/8443)" "React/TypeScript"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management and RBAC" "External"
        openshiftAPI = softwareSystem "OpenShift API" "Route management, serving cert annotation, cluster detection" "External"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Auto-provisions TLS certificates via serving-cert annotations" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages ServiceMonitor CRDs for metrics scraping" "External"
        odhNotebooks = softwareSystem "OpenDataHub Notebooks" "Jupyter notebooks with Feast integration label" "Internal ODH"
        odhOperator = softwareSystem "ODH/RHOAI Operator" "Deploys feast-operator via platform component manifests" "Internal ODH"
        oidcProvider = softwareSystem "OIDC Provider" "Token validation via .well-known/openid-configuration" "External"

        redis = softwareSystem "Redis" "Online store backend (port 6379)" "External"
        postgresql = softwareSystem "PostgreSQL" "Offline/online store and registry backend (port 5432)" "External"
        snowflake = softwareSystem "Snowflake" "Offline/online store and registry backend" "External"
        s3 = softwareSystem "S3/GCS Object Storage" "Remote registry file storage and model artifacts" "External"

        # User interactions
        dataScientist -> feast "Creates FeatureStore CRs via kubectl, browses UI"
        mlApp -> feast "GetOnlineFeatures, get historical features via gRPC"

        # Operator dependencies
        feastOperator -> k8sAPI "CRUD on Deployments, Services, ConfigMaps, RBAC, CronJobs, PVCs" "HTTPS/443"
        feastOperator -> openshiftAPI "Route management, serving cert annotation" "HTTPS/443"
        feastOperator -> featureServer "Fetches permission policies for auto-access RBAC" "HTTP(S)/80|443 HMAC-SHA256 JWT"

        # Feature server dependencies
        featureServer -> redis "Read/write online features" "Redis/6379 TLS optional"
        featureServer -> postgresql "Read/write features and metadata" "PostgreSQL/5432 TLS optional"
        featureServer -> snowflake "Read/write features and metadata" "HTTPS/443"
        featureServer -> s3 "Registry file storage" "HTTPS/443 IAM auth"
        featureServer -> k8sAPI "TokenReview, SubjectAccessReview for auth" "HTTPS/443"
        featureServer -> oidcProvider "Token validation" "HTTPS/443"

        # Platform integrations
        odhOperator -> feast "Deploys feast-operator via Kustomize manifests"
        feastOperator -> odhNotebooks "Watches Notebook CRs, creates ConfigMaps" "HTTPS/443"
        feastOperator -> prometheusOperator "Creates ServiceMonitor for metrics" "HTTPS/443"
        feastOperator -> openshiftServiceCA "TLS cert provisioning via annotations"
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

        component featureServer "FeatureServerComponents" {
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
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

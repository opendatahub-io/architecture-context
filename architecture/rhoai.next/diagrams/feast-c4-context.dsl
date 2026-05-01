workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML feature stores, defines feature views and entities"
        mlApplication = person "ML Application" "Consumes online features for real-time inference"

        feast = softwareSystem "Feast" "Feature store platform providing online/offline feature serving, materialization, and registry management" {
            feastOperator = container "Feast Operator" "Manages FeatureStore CRD lifecycle, creates Deployments, Services, RBAC, CronJobs, and TLS" "Go 1.22.9, controller-runtime v0.18.4" {
                featureStoreReconciler = component "FeatureStore Reconciler" "Reconciles FeatureStore CRs, creates/updates all child resources" "Go Controller"
                notebookReconciler = component "Notebook ConfigMap Reconciler" "Injects feature_store.yaml config into Notebook pods" "Go Controller"
                autoAccessRBAC = component "Auto-Access RBAC Controller" "Fetches permission policies from registry and creates ClusterRoleBindings" "Go Controller"
            }
            featureServer = container "Feature Server" "Serves online features via REST/gRPC APIs, handles materialization and registry" "Python 3.12, FastAPI, Gunicorn/Uvicorn" {
                onlineAPI = component "Online Feature API" "REST endpoints for feature retrieval, push, and materialization" "FastAPI"
                securityManager = component "SecurityManager" "Token validation and per-request RBAC enforcement" "OIDC/K8s RBAC"
                registryGRPC = component "Registry gRPC Server" "Registry metadata CRUD via gRPC" "gRPC, port 6570/6571"
                registryREST = component "Registry REST Server" "Registry metadata listing via REST" "FastAPI, port 6572/6573"
            }
            cronJob = container "Materialization CronJob" "Periodically materializes features from offline to online store" "ose-cli container"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management, RBAC, and token reviews" "External"
        oidcProvider = softwareSystem "OIDC Provider" "External identity provider for JWT-based authentication" "External"
        redis = softwareSystem "Redis" "In-memory data store used as online feature store backend" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database used as online/offline/registry store backend" "External"
        bigquery = softwareSystem "BigQuery" "Google Cloud data warehouse used as offline store backend" "External"
        snowflake = softwareSystem "Snowflake" "Cloud data warehouse used as online/offline/registry store backend" "External"
        s3gcs = softwareSystem "S3 / GCS" "Object storage for registry file persistence" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys Feast operator" "Internal ODH"
        notebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook environment for data scientists" "Internal ODH"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring operator for ServiceMonitor-based metrics scraping" "External"
        serviceCerts = softwareSystem "OpenShift Service Serving Certs" "Automatic TLS certificate provisioning for Services" "External"

        # Relationships - Users
        dataScientist -> feast "Creates FeatureStore CRs, defines features" "kubectl / YAML"
        mlApplication -> feast "Retrieves online features" "HTTPS/6567, Bearer Token"

        # Relationships - Feast internal
        feastOperator -> featureServer "Creates and manages" "Kubernetes Deployment"
        feastOperator -> cronJob "Creates and schedules" "Kubernetes CronJob"

        # Relationships - External dependencies
        feastOperator -> k8sAPI "CRD reconciliation, RBAC management, token reviews" "HTTPS/6443"
        featureServer -> redis "Read/write online features" "TCP/6379, TLS"
        featureServer -> postgresql "Read/write features" "TCP/5432, TLS verify-full"
        featureServer -> bigquery "Read historical features" "HTTPS/443"
        featureServer -> snowflake "Read/write features" "HTTPS/443"
        featureServer -> s3gcs "Registry persistence" "HTTPS/443"
        featureServer -> oidcProvider "Token validation, JWKS retrieval" "HTTPS/443"
        featureServer -> k8sAPI "TokenReview for K8s auth mode" "HTTPS/6443"
        cronJob -> featureServer "Trigger materialization" "HTTPS/6567, Intra-comm token"

        # Relationships - Internal platform
        rhodsOperator -> feast "Deploys feast-operator" "Kustomize overlays"
        feastOperator -> notebooks "Injects feast config into Notebook pods" "CRD Watch + ConfigMap"
        feast -> prometheusOperator "ServiceMonitor for metrics scraping" "CRD Create"
        feast -> serviceCerts "Automatic TLS cert provisioning" "Annotation-triggered"
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

        component feastOperator "FeastOperatorComponents" {
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
                background #85bbf0
                color #000000
            }
            element "Component" {
                background #c9e4fc
                color #000000
            }
        }
    }
}

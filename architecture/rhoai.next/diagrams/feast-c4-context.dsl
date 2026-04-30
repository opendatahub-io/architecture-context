workspace {
    model {
        datascientist = person "Data Scientist" "Creates FeatureStore CRs, retrieves features from notebooks and ML applications"
        mlapp = person "ML Application" "Consumes online features for inference predictions"
        platformadmin = person "Platform Admin" "Deploys and configures Feast operator via RHOAI/ODH"

        feast = softwareSystem "Feast" "Feature store platform for ML workloads - manages feature storage, retrieval, and materialization" {
            feastOperator = container "Feast Operator" "Manages FeatureStore CRD lifecycle, creates Deployments, Services, RBAC, CronJobs, and monitoring resources" "Go / controller-runtime"
            featureServer = container "Feature Server" "Serves online features via REST API, handles feature push and materialization" "Python / FastAPI / Gunicorn"
            registryGRPC = container "Registry gRPC Server" "Registry metadata CRUD operations via gRPC" "Python / gRPC"
            registryREST = container "Registry REST Server" "Registry metadata and permission queries via REST" "Python / FastAPI"
            securityManager = container "SecurityManager" "Enforces per-request RBAC via OIDC or Kubernetes token validation" "Python"
            notebookReconciler = container "NotebookConfigMap Reconciler" "Watches Notebook CRs and injects feature_store.yaml config" "Go / controller-runtime"
        }

        k8sapi = softwareSystem "Kubernetes API" "Cluster API server for CRD reconciliation and RBAC management" "External"
        rhodsOperator = softwareSystem "RHOAI Operator" "Platform operator that deploys Feast operator via kustomize overlays" "Internal Platform"
        notebookCRD = softwareSystem "Kubeflow Notebooks" "Notebook CRD providing Jupyter notebook instances" "Internal Platform"
        openshiftRoutes = softwareSystem "OpenShift Routes" "OpenShift route and service-serving certificate infrastructure" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring via ServiceMonitor CRDs" "External"
        caBundle = softwareSystem "ODH Trusted CA Bundle" "Platform CA trust bundle ConfigMap" "Internal Platform"

        redis = softwareSystem "Redis" "Online feature store backend" "External"
        postgresql = softwareSystem "PostgreSQL" "Online/offline/registry store backend" "External"
        bigquery = softwareSystem "BigQuery" "Offline feature store backend (Google Cloud)" "External"
        snowflake = softwareSystem "Snowflake" "Online/offline/registry store backend" "External"
        s3gcs = softwareSystem "S3 / GCS" "Registry file persistence backend" "External"
        oidcProvider = softwareSystem "OIDC Provider" "External identity provider for JWT token validation" "External"

        # Relationships - Users
        datascientist -> feast "Creates FeatureStore CRs, retrieves features" "kubectl, REST API"
        mlapp -> feast "Retrieves online features for inference" "REST HTTPS/6567"
        platformadmin -> rhodsOperator "Configures Feast deployment" "RHOAI Dashboard"

        # Relationships - Platform deployment
        rhodsOperator -> feast "Deploys feast-operator" "Kustomize overlays"

        # Relationships - Internal
        feastOperator -> k8sapi "Reconciles CRDs, manages resources, token reviews" "HTTPS/6443"
        feastOperator -> featureServer "Creates Deployment" "Kubernetes API"
        feastOperator -> registryREST "Fetches permission policies for auto-access RBAC" "HTTP/6572-6573"
        featureServer -> securityManager "Validates request tokens" "Python call"
        featureServer -> registryGRPC "Reads feature metadata" "gRPC/6570-6571"
        notebookReconciler -> notebookCRD "Watches Notebooks with feast-integration label" "Watch API"
        notebookReconciler -> k8sapi "Creates feast-config ConfigMaps" "HTTPS/6443"

        # Relationships - External stores
        featureServer -> redis "Reads/writes online features" "TCP/6379 TLS"
        featureServer -> postgresql "Reads/writes features" "TCP/5432 TLS"
        featureServer -> bigquery "Reads historical features" "HTTPS/443"
        featureServer -> snowflake "Reads/writes features" "HTTPS/443"
        featureServer -> s3gcs "Persists registry metadata" "HTTPS/443"
        securityManager -> oidcProvider "OIDC discovery, JWKS retrieval" "HTTPS/443"
        securityManager -> k8sapi "Kubernetes TokenReview" "HTTPS/6443"

        # Relationships - Platform infrastructure
        feastOperator -> openshiftRoutes "Creates Routes for UI" "OpenShift API"
        feastOperator -> prometheusOperator "Creates ServiceMonitors" "Kubernetes API"
        featureServer -> caBundle "Loads platform CA certificates" "Volume mount"
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
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        admin = person "Platform Admin" "Deploys and configures MLflow tracking server instances via MLflow CR"
        datascientist = person "Data Scientist" "Tracks experiments, logs models, and queries artifacts via MLflow API"
        nsowner = person "Namespace Owner" "Configures per-namespace artifact storage via MLflowConfig CR"

        mlflowOperator = softwareSystem "MLflow Operator" "Deploys and manages MLflow tracking server instances on OpenShift via cluster-scoped MLflow CRD" {
            controller = container "MLflow Operator Controller" "Watches MLflow CRD, renders embedded Helm chart, applies manifests via Server-Side Apply, manages HTTPRoute and ConsoleLink" "Go (controller-runtime)"
            helmRenderer = container "HelmRenderer" "Loads embedded Helm chart from charts/mlflow/, translates CR spec to Helm values, renders templates" "helm.sh/helm/v3"
            mlflowServer = container "MLflow Tracking Server" "Serves MLflow REST API with Kubernetes-native auth, experiment tracking, model registry, artifact management" "Python (uvicorn)"
            caBundleWatcher = container "CA Bundle Watcher" "Sidecar that polls for CA ConfigMap changes every 30s and regenerates combined CA bundle" "Shell script"
            dbMigration = container "DB Migration Init" "Runs mlflow db fix-migration-gap for Alembic schema migration between RHOAI versions" "Python (mlflow CLI)"
            combineCaBundles = container "Combine CA Bundles Init" "Creates initial combined CA bundle from system, platform, and custom certificates" "Shell script"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for resource management, RBAC, and SelfSubjectAccessReview" "External"
        dataScienceGateway = softwareSystem "Data Science Gateway" "Gateway API ingress for RHOAI services, provides external HTTPS access" "Internal RHOAI"
        openshiftServiceCA = softwareSystem "OpenShift Service-CA" "Auto-generates and rotates TLS certificates for Services via annotation" "Internal OpenShift"
        openshiftConsole = softwareSystem "OpenShift Console" "Web console with application menu, extended via ConsoleLink CRD" "Internal OpenShift"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor CRD scraping" "Internal OpenShift"
        odhTrustedCABundle = softwareSystem "odh-trusted-ca-bundle" "Platform ConfigMap containing custom CA certificates for TLS verification" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Relational database for MLflow backend and registry metadata store" "External"
        mysql = softwareSystem "MySQL" "Alternative relational database for MLflow backend store" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for MLflow artifacts (MinIO, SeaweedFS, AWS S3)" "External"

        # Admin interactions
        admin -> mlflowOperator "Creates/updates MLflow CR (mlflow.opendatahub.io/v1)" "kubectl/API"
        nsowner -> mlflowOperator "Creates MLflowConfig CR (mlflow.kubeflow.org/v1)" "kubectl/API"

        # Client interactions
        datascientist -> dataScienceGateway "MLflow REST API calls" "HTTPS/443, Bearer Token"
        dataScienceGateway -> mlflowOperator "Forwards to MLflow via HTTPRoute" "HTTPS/8443, TLS (service-CA)"

        # Internal component flows
        controller -> helmRenderer "Renders Helm chart templates" "In-process"
        controller -> k8sApi "Watches CRDs, SSA apply, manages HTTPRoute/ConsoleLink" "HTTPS/6443, SA token"
        combineCaBundles -> mlflowServer "Provides initial combined CA bundle" "Filesystem (emptyDir)"
        dbMigration -> postgresql "Runs schema migration" "PostgreSQL/5432, TLS"
        caBundleWatcher -> mlflowServer "Updates combined CA bundle" "Filesystem (emptyDir, polling 30s)"

        # MLflow server dependencies
        mlflowServer -> k8sApi "SelfSubjectAccessReview for auth" "HTTPS/6443, Delegated Bearer Token"
        mlflowServer -> postgresql "Stores experiment/model metadata" "PostgreSQL/5432, TLS verify-full"
        mlflowServer -> mysql "Alternative metadata store" "MySQL/3306, TLS"
        mlflowServer -> s3Storage "Stores/retrieves model artifacts" "HTTPS/443 or 9000, AWS credentials"

        # Platform integrations
        mlflowOperator -> dataScienceGateway "Creates HTTPRoute (parent ref)" "Gateway API"
        mlflowOperator -> openshiftConsole "Creates ConsoleLink" "ConsoleLink CRD"
        openshiftServiceCA -> mlflowOperator "Provisions TLS certificate (mlflow-tls secret)" "Annotation-based"
        prometheus -> mlflowOperator "Scrapes /metrics endpoint" "HTTPS/8443, ServiceMonitor"
        odhTrustedCABundle -> mlflowOperator "Provides platform CA certificates" "ConfigMap volume mount"
    }

    views {
        systemContext mlflowOperator "SystemContext" {
            include *
            autoLayout
        }

        container mlflowOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal OpenShift" {
                background #9b59b6
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

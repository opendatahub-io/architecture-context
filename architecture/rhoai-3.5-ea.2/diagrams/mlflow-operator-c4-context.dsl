workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages ML experiments, models, and artifacts via MLflow tracking server"
        platformadmin = person "Platform Admin" "Deploys and configures MLflow via MLflow CR on OpenShift AI"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator managing MLflow tracking server lifecycle via Helm chart rendering and Server-Side Apply" {
            controller = container "mlflow-operator Controller" "Watches MLflow CR, renders embedded Helm chart, applies resources via SSA, orchestrates migrations" "Go (controller-runtime)"
            helmEngine = container "Helm Chart Engine" "Embedded Helm chart (charts/mlflow/) rendered in-process to produce Kubernetes manifests" "Helm SDK v3.19.2"
            mlflowServer = container "MLflow Tracking Server" "Serves MLflow UI and REST API with Kubernetes-native auth, workspace support, and TLS" "Python (uvicorn)"
            migrationJob = container "Migration Job" "Ephemeral Job running mlflow db upgrade (Alembic) when MLflow version changes" "Python"
            gcCronJob = container "GC CronJob" "Periodic garbage collection of MLflow experiments and artifacts" "Python"
        }

        k8sapi = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management, RBAC, and service discovery" "External"
        gatewayAPI = softwareSystem "data-science-gateway" "Platform ingress gateway (Gateway API / Envoy) providing external access at /mlflow path" "Internal RHOAI"
        serviceca = softwareSystem "OpenShift service-ca" "Automatic TLS certificate provisioning and rotation for Kubernetes Services" "External"
        console = softwareSystem "OpenShift Console" "OpenShift web console with application menu" "External"
        prometheus = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor CRDs" "External"
        caBundle = softwareSystem "odh-trusted-ca-bundle" "Platform-managed CA bundle ConfigMap for TLS verification" "Internal RHOAI"
        rhods = softwareSystem "RHOAI Operator" "Platform operator that creates the MLflow CR to trigger deployment" "Internal RHOAI"

        postgresql = softwareSystem "PostgreSQL" "Relational database for MLflow backend/registry metadata store" "External"
        mysql = softwareSystem "MySQL" "Alternative relational database for MLflow metadata store" "External"
        s3storage = softwareSystem "S3-compatible Storage" "Object storage for ML artifacts (models, plots, files) — MinIO, SeaweedFS, AWS S3, GCS, Azure Blob" "External"

        # User interactions
        datascientist -> mlflowOperator "Uses MLflow UI and REST API for experiment tracking" "HTTPS/8443 via Gateway"
        platformadmin -> k8sapi "Creates/updates MLflow CR" "kubectl / HTTPS"

        # Internal interactions
        controller -> helmEngine "Converts CR spec to Helm values and renders templates" "In-process"
        controller -> k8sapi "Watches CRs, applies resources via SSA, leader election" "HTTPS/443 TLS 1.2+"
        controller -> migrationJob "Creates migration Job on version change" "Kubernetes Job API"
        controller -> gcCronJob "Creates garbage collection CronJob" "Kubernetes CronJob API"

        # MLflow server interactions
        mlflowServer -> k8sapi "SelfSubjectAccessReview for Kubernetes-native auth" "HTTPS/443 TLS 1.2+"
        mlflowServer -> postgresql "Query/store experiment metadata" "PostgreSQL/5432 TLS"
        mlflowServer -> mysql "Query/store experiment metadata (alternative)" "MySQL/3306 TLS"
        mlflowServer -> s3storage "Store/retrieve ML artifacts" "HTTPS/443,9000 TLS 1.2+"

        # Migration Job
        migrationJob -> postgresql "Alembic database schema migration" "PostgreSQL/5432 TLS"
        migrationJob -> mysql "Alembic database schema migration (alternative)" "MySQL/3306 TLS"

        # Platform integrations
        gatewayAPI -> mlflowOperator "Routes external traffic to MLflow Service" "HTTPS/8443 TLS passthrough"
        serviceca -> mlflowOperator "Provisions TLS certificates (mlflow-tls Secret)" "Service annotation"
        mlflowOperator -> console "Creates ConsoleLink for application menu entry" "ConsoleLink CR"
        prometheus -> mlflowOperator "Scrapes metrics from operator and MLflow server" "ServiceMonitor CR"
        caBundle -> mlflowOperator "Provides platform CA bundle for TLS verification" "Volume mount"
        rhods -> mlflowOperator "Creates MLflow CR to trigger deployment" "Kubernetes CR"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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
        }
    }
}

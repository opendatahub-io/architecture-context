workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML experiments, logs models and artifacts via MLflow tracking API"
        admin = person "Platform Admin" "Creates MLflow CR to deploy and configure MLflow tracking server instances"
        nsOwner = person "Namespace Owner" "Creates MLflowConfig CR to override artifact storage for their namespace"

        mlflowOperator = softwareSystem "MLflow Operator" "Manages lifecycle of MLflow tracking server deployments on Kubernetes/OpenShift via CRD reconciliation with embedded Helm chart rendering" {
            controller = container "MLflow Controller" "Reconciles MLflow CRs into Kubernetes resources via embedded Helm chart rendering and Server-Side Apply" "Go (controller-runtime)"
            helmRenderer = container "Helm Renderer" "Translates MLflow CR spec fields into Helm values and renders the embedded charts/mlflow/ chart into unstructured Kubernetes objects" "Go (Helm v3 library)"
            migrationManager = container "Migration Manager" "Orchestrates zero-downtime database migrations: scales down deployment, runs migration Job, monitors completion, restores replicas" "Go"
            routingManager = container "Routing Manager" "Conditionally creates HTTPRoute (Gateway API) and ConsoleLink (OpenShift) resources based on cluster CRD availability" "Go"
            metricsServer = container "Metrics/Health Server" "Exposes /healthz (8081/TCP), /readyz (8081/TCP), /metrics (8443/TCP HTTPS)" "Go (controller-runtime)"
        }

        mlflowServer = softwareSystem "MLflow Tracking Server" "MLflow tracking server deployed and managed by the operator; provides experiment tracking, model registry, and artifact storage APIs" {
            trackingAPI = container "Tracking API" "REST API for experiments, runs, models, artifacts with Kubernetes-native authentication via SelfSubjectAccessReview" "Python (MLflow v3.13.0)"
            caAggregator = container "CA Bundle Aggregator" "Init container + sidecar that combines platform and custom CA certificates for TLS verification" "Shell scripts"
        }

        migrationJob = softwareSystem "Migration Job" "Kubernetes Job that runs 'mlflow db upgrade' before deployment scaling, with structured exit codes for error handling" "Ephemeral"
        gcCronJob = softwareSystem "GC CronJob" "Scheduled CronJob that permanently deletes soft-deleted MLflow resources (metadata via direct DB, artifacts via MLflow API)" "Optional"

        gateway = softwareSystem "data-science-gateway" "RHOAI platform Gateway API gateway in openshift-ingress namespace that routes external HTTPS traffic to backend services" "External - Gateway API"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for CRD watches, resource CRUD, RBAC, and SelfSubjectAccessReview authentication" "External - Platform"
        serviceCA = softwareSystem "OpenShift service-ca" "Controller that automatically provisions and rotates TLS certificates for annotated Services" "External - Platform"
        prometheus = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor CRD; scrapes MLflow server /metrics endpoint" "External - Platform"
        console = softwareSystem "OpenShift Console" "Web console that displays ConsoleLink entries in application menu" "External - Platform"

        postgresql = softwareSystem "PostgreSQL" "Relational database for MLflow backend/registry metadata store" "External"
        mysql = softwareSystem "MySQL" "Alternative relational database for MLflow metadata store" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for MLflow artifacts (MinIO, SeaweedFS, AWS S3, GCS, Azure Blob)" "External"

        # Relationships - Admin/User
        admin -> mlflowOperator "Creates MLflow CR via kubectl" "HTTPS/6443"
        nsOwner -> mlflowServer "Creates MLflowConfig CR for namespace storage overrides" "HTTPS/6443"
        dataScientist -> gateway "Accesses MLflow tracking API" "HTTPS/443"

        # Relationships - Ingress
        gateway -> mlflowServer "Routes /mlflow/* requests via HTTPRoute" "HTTPS/8443 TLS"

        # Relationships - Operator
        mlflowOperator -> k8sAPI "Watches CRDs, manages resources via SSA" "HTTPS/6443"
        mlflowOperator -> mlflowServer "Deploys and manages lifecycle" "Kubernetes API"
        mlflowOperator -> migrationJob "Creates for DB upgrades" "Kubernetes API"
        mlflowOperator -> gcCronJob "Creates for scheduled cleanup" "Kubernetes API"
        mlflowOperator -> gateway "Creates HTTPRoute (conditional)" "Kubernetes API"
        mlflowOperator -> console "Creates ConsoleLink (conditional)" "Kubernetes API"
        mlflowOperator -> prometheus "Creates ServiceMonitor (conditional)" "Kubernetes API"

        # Relationships - MLflow Server
        mlflowServer -> k8sAPI "SelfSubjectAccessReview for auth decisions" "HTTPS/6443"
        mlflowServer -> postgresql "Stores/queries experiment and model metadata" "TCP/5432 TLS"
        mlflowServer -> mysql "Alternative metadata store" "TCP/3306 TLS"
        mlflowServer -> s3 "Stores/retrieves ML artifacts" "HTTPS/443"

        # Relationships - Jobs
        migrationJob -> postgresql "Runs mlflow db upgrade" "TCP/5432 TLS"
        gcCronJob -> postgresql "Deletes soft-deleted metadata" "TCP/5432 TLS"
        gcCronJob -> mlflowServer "Deletes artifacts via API" "HTTPS/8443"

        # Relationships - Platform
        serviceCA -> mlflowServer "Provisions mlflow-tls Secret" "Auto"
        prometheus -> mlflowServer "Scrapes /metrics" "HTTPS/8443"

        # Internal container relationships
        controller -> helmRenderer "Passes CR spec as Helm values"
        controller -> migrationManager "Triggers on version/spec changes"
        controller -> routingManager "Delegates HTTPRoute/ConsoleLink creation"
    }

    views {
        systemContext mlflowOperator "SystemContext" {
            include *
            autoLayout
        }

        container mlflowOperator "OperatorContainers" {
            include *
            autoLayout
        }

        container mlflowServer "ServerContainers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External - Platform" {
                background #6c8ebf
                color #ffffff
            }
            element "External - Gateway API" {
                background #d79b00
                color #ffffff
            }
            element "Ephemeral" {
                background #9673a6
                color #ffffff
            }
            element "Optional" {
                background #b85450
                color #ffffff
            }
            element "Person" {
                shape Person
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

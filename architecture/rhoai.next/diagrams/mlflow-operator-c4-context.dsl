workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and tracks ML experiments, registers models, manages artifacts"
        admin = person "Platform Admin" "Deploys and configures MLflow via MLflow CR"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator managing MLflow server lifecycle via Helm-in-operator pattern" {
            controller = container "MLflow Controller" "Reconciles MLflow CR into deployment resources using embedded Helm chart rendering and Server-Side Apply" "Go (controller-runtime)"
            helmEngine = container "Embedded Helm Engine" "Renders charts/mlflow/ templates into Kubernetes manifests with dynamic values from MLflow CR spec" "helm.sh/helm/v3"
            mlflowServer = container "MLflow Server" "Experiment tracking, model registry, artifact serving, AI Gateway with Kubernetes-native RBAC authorization" "Python (uvicorn)"
            caBundleSidecar = container "CA Bundle Sidecar" "Watches CA ConfigMap changes and regenerates combined CA bundle every 30s without pod restarts" "Shell"
        }

        dataScienceGateway = softwareSystem "Data Science Gateway" "Platform ingress gateway for external traffic routing via Gateway API" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management and SelfSubjectAccessReview authorization" "Platform"
        serviceCA = softwareSystem "OpenShift service-ca" "Automatic TLS certificate provisioning for services" "Platform"
        openShiftConsole = softwareSystem "OpenShift Console" "Web console with application menu integration via ConsoleLink" "Platform"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection via ServiceMonitor CRD" "Platform"

        postgresql = softwareSystem "PostgreSQL" "Backend/registry store for experiment metadata and model registry" "External"
        mysql = softwareSystem "MySQL" "Alternative backend/registry store database" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Artifact storage for models, plots, and files (MinIO, SeaweedFS, AWS S3)" "External"

        # User interactions
        dataScientist -> mlflowOperator "Tracks experiments, registers models via REST API" "HTTPS/8443"
        admin -> mlflowOperator "Creates/manages MLflow CR via kubectl" "kubectl"

        # Internal interactions
        controller -> helmEngine "Renders Helm chart with CR-derived values"
        helmEngine -> mlflowServer "Deploys via Server-Side Apply"
        mlflowServer -> caBundleSidecar "Shares CA bundle volume mount"

        # Platform integrations
        mlflowOperator -> dataScienceGateway "Creates HTTPRoute for external access" "Gateway API"
        mlflowOperator -> k8sAPI "SelfSubjectAccessReview for RBAC authorization, resource management" "HTTPS/6443"
        mlflowOperator -> serviceCA "TLS certificate provisioning via service annotation" "Service annotation"
        mlflowOperator -> openShiftConsole "Creates ConsoleLink for console menu integration" "ConsoleLink CRD"
        mlflowOperator -> prometheus "Exposes metrics via ServiceMonitor" "HTTPS/8443"

        # External service dependencies
        mlflowOperator -> postgresql "Stores experiment metadata and model registry" "PostgreSQL/5432 TLS optional"
        mlflowOperator -> mysql "Alternative metadata store" "MySQL/3306 TLS optional"
        mlflowOperator -> s3Storage "Stores model artifacts, plots, files" "HTTPS/443,9000"
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
            element "Platform" {
                background #4a90e2
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

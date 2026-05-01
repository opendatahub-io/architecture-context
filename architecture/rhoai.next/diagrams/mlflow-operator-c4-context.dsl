workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML experiments, models, and artifacts"
        platformAdmin = person "Platform Admin" "Deploys and configures the MLflow CR"
        namespaceOwner = person "Namespace Owner" "Configures per-namespace artifact storage via MLflowConfig"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator that manages MLflow server deployments for experiment tracking, model registry, and AI Gateway" {
            controller = container "MLflow Controller" "Reconciles MLflow CR into server deployments using embedded Helm chart rendering and Server-Side Apply" "Go (controller-runtime)"
            helmRenderer = container "Helm Chart Renderer" "Renders embedded Helm chart (charts/mlflow/) into Kubernetes manifests" "helm.sh/helm/v3"
            routingManager = container "Routing Manager" "Creates HTTPRoute and ConsoleLink resources for gateway integration" "Go"
            mlflowServer = container "MLflow Server" "Experiment tracking, model registry, artifact serving, and AI Gateway" "Python/uvicorn 8443/TCP HTTPS"
            caSidecar = container "CA Bundle Sidecar" "Watches CA ConfigMap changes and regenerates combined CA bundle every 30s" "Shell"
        }

        dataScienceGateway = softwareSystem "data-science-gateway" "Platform ingress gateway for external traffic routing via Gateway API" "External RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for RBAC authorization (SelfSubjectAccessReview) and resource management" "External"
        serviceCA = softwareSystem "OpenShift service-ca" "Automatic TLS certificate provisioning for Services" "External OpenShift"
        openshiftConsole = softwareSystem "OpenShift Console" "Web console with application menu integration via ConsoleLink" "External OpenShift"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection via ServiceMonitor CRD" "External"
        postgresql = softwareSystem "PostgreSQL" "Backend/registry store for experiment metadata and model registry" "External"
        mysql = softwareSystem "MySQL" "Alternative backend/registry store" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Artifact storage for models, plots, and files (AWS S3, MinIO, SeaweedFS)" "External"
        caBundle = softwareSystem "odh-trusted-ca-bundle" "Platform CA certificates for custom TLS chains" "Internal RHOAI"

        platformAdmin -> mlflowOperator "Creates MLflow CR (cluster-scoped)" "kubectl"
        namespaceOwner -> mlflowOperator "Creates MLflowConfig CR (namespace-scoped)" "kubectl"
        dataScientist -> mlflowOperator "Tracks experiments, registers models, uploads artifacts" "HTTPS/8443"

        controller -> helmRenderer "Converts MLflow CR spec into Helm values and renders templates"
        controller -> routingManager "Creates HTTPRoute and ConsoleLink resources"
        mlflowServer -> k8sAPI "SelfSubjectAccessReview for authorization" "HTTPS/6443"
        mlflowServer -> postgresql "Stores experiment metadata" "TCP/5432 TLS optional"
        mlflowServer -> mysql "Alternative metadata store" "TCP/3306 TLS optional"
        mlflowServer -> s3Storage "Stores/retrieves artifacts" "HTTPS/443,9000"
        caSidecar -> caBundle "Watches for CA changes" "ConfigMap volume"

        mlflowOperator -> dataScienceGateway "HTTPRoute parent reference for external routing" "Gateway API"
        mlflowOperator -> serviceCA "TLS cert provisioning via service annotation" "Service annotation"
        mlflowOperator -> openshiftConsole "ConsoleLink for console menu" "CRD"
        mlflowOperator -> k8sAPI "Reconcile loop, RBAC management" "HTTPS/6443"
        prometheus -> mlflowOperator "Scrapes metrics" "HTTPS/8443"
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
            element "External RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External OpenShift" {
                background #cc0000
                color #ffffff
            }
            element "Internal RHOAI" {
                background #50a14f
                color #ffffff
            }
            element "Person" {
                shape person
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

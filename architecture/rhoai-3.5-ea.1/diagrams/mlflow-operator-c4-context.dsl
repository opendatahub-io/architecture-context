workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML experiments, logs models and artifacts"
        admin = person "Platform Admin" "Manages MLflow CR and cluster configuration"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator that manages MLflow tracking server deployments using Helm-based reconciliation" {
            controller = container "MLflow Controller" "Watches MLflow CR, renders Helm chart, applies resources via SSA" "Go (controller-runtime)"
            helmRenderer = container "Helm Renderer" "Embedded Helm chart engine for generating Kubernetes manifests" "helm/v3"
            routingManager = container "Routing Manager" "Creates HTTPRoutes and ConsoleLinks for platform integration" "Go"
            caBundleManager = container "CA Bundle Manager" "Watches CA ConfigMaps and triggers re-reconciliation" "Go"
        }

        mlflowServer = softwareSystem "MLflow Tracking Server" "MLflow server deployed by the operator via Helm chart rendering" {
            trackingAPI = container "Tracking API" "REST API for experiment tracking, model registry, artifact management" "Python/Uvicorn 8443/TCP"
            kubernetesAuth = container "Kubernetes Auth" "Authorization middleware using SelfSubjectAccessReview" "Python"
            caBundleWatcher = container "CA Bundle Watcher" "Sidecar that watches CA ConfigMap updates and regenerates combined bundle" "Sidecar Container"
        }

        # External dependencies
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management and RBAC" "External"
        gateway = softwareSystem "data-science-gateway" "RHOAI platform Envoy gateway for unified ingress" "Internal RHOAI"
        serviceCA = softwareSystem "OpenShift service-ca" "Auto-provisions TLS certificates for Services" "External"
        console = softwareSystem "OpenShift Console" "OpenShift web console with application menu" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "External"
        caBundle = softwareSystem "odh-trusted-ca-bundle" "Platform-wide CA certificate bundle ConfigMap" "Internal RHOAI"

        # Backend services
        postgresql = softwareSystem "PostgreSQL" "Metadata storage for experiments, runs, and model registry" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Artifact storage (MinIO, SeaweedFS, AWS S3)" "External"

        # Relationships - User interactions
        user -> mlflowServer "Logs experiments, registers models, stores artifacts" "HTTPS/443 via gateway"
        admin -> mlflowOperator "Creates/updates MLflow CR" "kubectl"

        # Operator internal flows
        controller -> helmRenderer "Renders Helm chart with CR spec values"
        controller -> routingManager "Creates HTTPRoutes and ConsoleLinks"
        controller -> caBundleManager "Watches CA ConfigMap changes"

        # Operator → external
        mlflowOperator -> k8sAPI "Watches MLflow CR, SSA patches resources" "HTTPS/6443"
        mlflowOperator -> mlflowServer "Deploys and manages via Helm-rendered manifests" "Server-Side Apply"

        # Server internal flows
        trackingAPI -> kubernetesAuth "Validates requests via SelfSubjectAccessReview"

        # Server → external
        mlflowServer -> k8sAPI "SelfSubjectAccessReview for authorization" "HTTPS/6443"
        mlflowServer -> postgresql "Stores experiment metadata" "PostgreSQL/5432 TLS verify-full"
        mlflowServer -> s3Storage "Stores/retrieves model artifacts" "HTTPS/443,9000"

        # Platform integrations
        gateway -> mlflowServer "Routes /mlflow/* traffic" "HTTPS/8443"
        serviceCA -> mlflowServer "Provisions mlflow-tls certificate" "Auto"
        caBundle -> mlflowServer "Provides CA certificates" "Volume mount"
        prometheus -> mlflowServer "Scrapes /metrics" "HTTPS/8443"
        prometheus -> mlflowOperator "Scrapes /metrics" "HTTPS/8443"
        mlflowOperator -> console "Creates ConsoleLink" "CR"
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
            element "Internal RHOAI" {
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
        }
    }
}

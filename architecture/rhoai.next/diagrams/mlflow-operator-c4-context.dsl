workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML experiments, runs, and model versions via MLflow"
        platformAdmin = person "Platform Admin" "Deploys and configures MLflow via the MLflow CR"
        workspaceOwner = person "Workspace Owner" "Configures per-namespace artifact storage via MLflowConfig CR"

        mlflowSystem = softwareSystem "MLflow Operator" "Kubernetes operator that manages MLflow tracking server deployments with Helm-based rendering, Gateway API routing, and Kubernetes-native auth" {
            operator = container "MLflow Operator" "Reconciles MLflow CRs into complete MLflow deployment stack using embedded Helm chart and Server-Side Apply" "Go Operator (controller-runtime)"
            helmRenderer = container "Helm Renderer" "Embedded Helm chart rendering engine for templating Kubernetes manifests (Deployment, Service, RBAC, NetworkPolicy, PVC, ServiceMonitor)" "Go (helm.sh/helm/v3)"
            mlflowServer = container "MLflow Tracking Server" "REST API for experiment tracking, model registry, and artifact management with Kubernetes-native RBAC authorization" "Python (Uvicorn) 8443/TCP HTTPS"
            caBundleWatcher = container "CA Bundle Watcher" "Sidecar that watches for CA ConfigMap changes and regenerates combined CA PEM file (30s checksum interval)" "Shell sidecar"
            combineCaBundles = container "Combine CA Bundles" "Init container that creates initial combined CA bundle from system + platform + custom CA sources" "Shell init container"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster API server for resource management, RBAC authorization, and SelfSubjectAccessReview" "External"
        dataScienceGateway = softwareSystem "data-science-gateway" "Platform ingress gateway (Envoy) providing shared hostname with path-prefix-based routing for RHOAI components" "Internal RHOAI"
        openshiftServiceCA = softwareSystem "OpenShift service-ca" "Automatic TLS certificate provisioning for Kubernetes services via serving-cert annotation" "Internal OpenShift"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring stack that scrapes metrics via ServiceMonitor CRs" "Internal OpenShift"
        openshiftConsole = softwareSystem "OpenShift Console" "Web console with application menu integration via ConsoleLink CRs" "Internal OpenShift"
        odhCABundle = softwareSystem "odh-trusted-ca-bundle" "Platform-injected CA certificate ConfigMap for TLS verification with internal services" "Internal RHOAI"

        postgresql = softwareSystem "PostgreSQL" "Relational database for MLflow backend/registry metadata store (experiments, runs, models)" "External"
        mysql = softwareSystem "MySQL" "Alternative relational database for MLflow backend/registry metadata store" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for ML model artifacts, plots, and files (AWS S3, MinIO, SeaweedFS)" "External"

        # Relationships
        platformAdmin -> mlflowSystem "Creates MLflow CR via kubectl" "HTTPS/6443"
        workspaceOwner -> mlflowSystem "Creates MLflowConfig CR for per-namespace artifact storage" "HTTPS/6443"
        dataScientist -> dataScienceGateway "Accesses MLflow API" "HTTPS/443"
        dataScienceGateway -> mlflowServer "Routes /mlflow/* traffic (re-encrypted)" "HTTPS/8443"

        operator -> helmRenderer "Renders Kubernetes manifests" "In-process"
        operator -> k8sApiServer "Watches CRs, Server-Side Apply resources" "HTTPS/6443"
        combineCaBundles -> mlflowServer "Creates initial combined CA bundle" "Shared volume"
        caBundleWatcher -> mlflowServer "Regenerates combined CA on ConfigMap change" "Shared volume"

        mlflowServer -> k8sApiServer "SelfSubjectAccessReview, namespace listing, secret reads" "HTTPS/6443"
        mlflowServer -> postgresql "Stores experiment/run/model metadata" "PostgreSQL/5432 TLS optional"
        mlflowServer -> mysql "Alternative metadata store" "MySQL/3306 TLS optional"
        mlflowServer -> s3Storage "Stores/retrieves model artifacts" "HTTPS/443,9000"

        mlflowSystem -> dataScienceGateway "Creates HTTPRoute for ingress routing" "Gateway API"
        mlflowSystem -> openshiftServiceCA "Requests TLS certificates via service annotation" "Annotation"
        mlflowSystem -> prometheusOperator "Creates ServiceMonitor for metrics scraping" "ServiceMonitor CR"
        mlflowSystem -> openshiftConsole "Creates ConsoleLink for console integration" "ConsoleLink CR"
        mlflowSystem -> odhCABundle "Mounts platform CA certificates for TLS verification" "Volume mount"
    }

    views {
        systemContext mlflowSystem "SystemContext" {
            include *
            autoLayout
        }

        container mlflowSystem "Containers" {
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
                background #ee0000
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
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

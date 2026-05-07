workspace {
    model {
        user = person "Data Scientist" "Creates and deploys MLflow experiments, logs runs and models"
        admin = person "Platform Admin" "Deploys and configures MLflow via the MLflow CR"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator that manages MLflow tracking server deployments on OpenShift/Kubernetes" {
            controller = container "MLflow Operator Controller" "Reconciles MLflow CRs into fully configured MLflow deployments using embedded Helm chart rendering and Server-Side Apply" "Go (controller-runtime)"
            helmRenderer = container "HelmRenderer" "Embedded Helm chart engine that renders Kubernetes manifests (Deployment, Service, RBAC, NetworkPolicy, PVC, ServiceMonitor)" "Go (helm/v3)"
            mlflowServer = container "MLflow Tracking Server" "ML experiment tracking, model registry, and artifact management with Kubernetes-native auth" "Python (uvicorn)"
            caBundleWatcher = container "CA Bundle Watcher" "Sidecar that watches for CA bundle ConfigMap changes and regenerates combined CA PEM file via checksum-based polling" "Shell script"
            caBundleInit = container "CA Bundle Init" "Init container that creates initial combined CA bundle from system, platform, and custom CA sources" "Shell script"
        }

        # Platform dependencies
        gateway = softwareSystem "data-science-gateway" "RHOAI platform ingress gateway (Envoy) for external traffic routing via Gateway API" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource management, RBAC authorization (SelfSubjectAccessReview), and CRD watches" "Platform"
        serviceCA = softwareSystem "OpenShift service-ca" "Automatic TLS certificate provisioning for Kubernetes services via serving-cert annotations" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor CRDs for both operator and MLflow server" "Platform"
        console = softwareSystem "OpenShift Console" "Web console with ConsoleLink integration for MLflow access" "Platform"
        caBundle = softwareSystem "odh-trusted-ca-bundle" "Platform-provided CA certificates ConfigMap for TLS verification with internal services" "Internal RHOAI"

        # External services
        postgresql = softwareSystem "PostgreSQL" "Backend metadata store for MLflow experiments, runs, and model registry" "External"
        mysql = softwareSystem "MySQL" "Alternative backend metadata store for MLflow" "External"
        s3 = softwareSystem "S3-compatible Storage" "Artifact storage for models, plots, and files (S3, MinIO, SeaweedFS)" "External"

        # User interactions
        admin -> mlflowOperator "Creates/updates MLflow CR via kubectl" "HTTPS/6443"
        user -> gateway "Accesses MLflow API" "HTTPS/443"

        # Internal flows
        gateway -> mlflowServer "Routes traffic (HTTPRoute with URL rewriting)" "HTTPS/8443"
        controller -> helmRenderer "Renders Kubernetes manifests" "In-process"
        controller -> k8sAPI "Watches CRs, Server-Side Apply" "HTTPS/6443"
        mlflowServer -> k8sAPI "SelfSubjectAccessReview, namespace listing, secret access" "HTTPS/6443"
        caBundleInit -> mlflowServer "Provides combined CA bundle" "Shared volume"
        caBundleWatcher -> mlflowServer "Updates combined CA bundle on changes" "Shared volume"

        # External service flows
        mlflowServer -> postgresql "Stores experiment/run metadata" "PostgreSQL/5432 TLS optional"
        mlflowServer -> mysql "Stores experiment/run metadata (alternative)" "MySQL/3306 TLS optional"
        mlflowServer -> s3 "Stores model artifacts" "HTTPS/443, HTTP/9000"

        # Platform integrations
        controller -> gateway "Creates HTTPRoute CRs" "Gateway API"
        controller -> console "Creates ConsoleLink CR" "Kubernetes API"
        serviceCA -> mlflowServer "Provisions TLS certificates" "Annotation-based"
        prometheus -> mlflowServer "Scrapes metrics" "HTTPS/8443"
        prometheus -> controller "Scrapes operator metrics" "HTTPS/8443"
        caBundle -> caBundleInit "Provides platform CA certificates" "Volume mount"
        caBundle -> caBundleWatcher "Watched for changes" "Volume mount"
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
                background #08427b
                color #ffffff
                shape person
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

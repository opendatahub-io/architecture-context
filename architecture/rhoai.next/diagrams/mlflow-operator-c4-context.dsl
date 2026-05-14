workspace {
    model {
        datascientist = person "Data Scientist" "Creates and tracks ML experiments, registers models, manages artifacts"
        platformadmin = person "Platform Admin" "Deploys and configures MLflow via MLflow CR"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator managing MLflow tracking server lifecycle, networking, TLS, CA bundles, and platform gateway integration" {
            controller = container "MLflow Operator Controller" "Reconciles MLflow CRs into complete MLflow deployment stack using embedded Helm chart rendering and Server-Side Apply" "Go 1.24.6, controller-runtime v0.22.4"
            helmRenderer = container "HelmRenderer" "In-process Helm chart rendering engine for templating Kubernetes manifests (Deployment, Service, PVC, NetworkPolicy, RBAC)" "helm.sh/helm/v3 v3.19.2"
            mlflowServer = container "MLflow Tracking Server" "MLflow tracking server with Kubernetes-native auth, workspace support, TLS-enabled REST API, and multi-backend support" "Python, uvicorn"
            caBundleInit = container "CA Bundle Init Container" "Creates initial combined CA bundle from system, platform, and custom CA sources" "Shell script"
            caBundleWatcher = container "CA Bundle Watcher Sidecar" "Watches for CA bundle ConfigMap changes and regenerates combined CA PEM file (30s checksum polling)" "Shell script"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster API for resource management, authentication, and authorization" "Infrastructure"
        dataScienceGateway = softwareSystem "Data Science Gateway" "RHOAI platform ingress gateway (Envoy-based) for external traffic routing via Gateway API" "Internal RHOAI"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Automatic TLS certificate provisioning for Kubernetes services via serving-cert annotations" "Infrastructure"
        openshiftConsole = softwareSystem "OpenShift Console" "OpenShift web console with application menu integration via ConsoleLink CRs" "Infrastructure"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection and monitoring via ServiceMonitor CRs" "Infrastructure"
        odhTrustedCA = softwareSystem "ODH Trusted CA Bundle" "Platform-injected CA certificates (ConfigMap) for TLS verification with internal services" "Internal RHOAI"

        postgresql = softwareSystem "PostgreSQL" "Relational database for MLflow experiment/run/model metadata storage" "External"
        mysql = softwareSystem "MySQL" "Alternative relational database for MLflow metadata storage" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for ML model artifacts, plots, and files (AWS S3, MinIO, SeaweedFS)" "External"

        # User interactions
        datascientist -> mlflowOperator "Creates experiments, logs runs, registers models" "HTTPS/8443 via Gateway"
        platformadmin -> mlflowOperator "Creates/updates MLflow CR via kubectl" "kubectl / HTTPS/6443"

        # Internal component interactions
        controller -> helmRenderer "Renders Kubernetes manifests" "In-process"
        controller -> k8sApiServer "Server-Side Apply resources, watch CRDs" "HTTPS/6443, Bearer Token"
        mlflowServer -> k8sApiServer "SelfSubjectAccessReview, namespace list, secret read, MLflowConfig watch" "HTTPS/6443, Bearer Token"
        caBundleInit -> mlflowServer "Creates initial combined CA bundle" "Shared volume"
        caBundleWatcher -> mlflowServer "Regenerates CA bundle on change" "Shared volume"

        # Platform integration
        controller -> dataScienceGateway "Creates HTTPRoute (path-prefix routing: /mlflow/*)" "Gateway API"
        controller -> openshiftConsole "Creates ConsoleLink for application menu" "ConsoleLink CR"
        controller -> prometheusOperator "Creates ServiceMonitor for metrics scraping" "ServiceMonitor CR"
        mlflowServer -> openshiftServiceCA "TLS certificate provisioned via annotation" "service-ca"
        caBundleWatcher -> odhTrustedCA "Watches for platform CA bundle changes" "ConfigMap volume"

        # External service connections
        mlflowServer -> postgresql "Stores experiment/run/model metadata" "PostgreSQL/5432, TLS optional"
        mlflowServer -> mysql "Alternative metadata storage" "MySQL/3306, TLS optional"
        mlflowServer -> s3Storage "Stores model artifacts, plots, files" "HTTPS/443, AWS IAM"

        # Gateway routing
        dataScienceGateway -> mlflowServer "Forwards requests with URL rewrite" "HTTPS/8443, re-encrypted TLS"
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
            element "External" {
                background #999999
            }
            element "Infrastructure" {
                background #666666
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
        }
    }
}

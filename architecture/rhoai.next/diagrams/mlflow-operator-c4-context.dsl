workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML experiments, models, and artifacts via MLflow"
        platformAdmin = person "Platform Admin" "Deploys and configures MLflow instances via MLflow CR"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator that manages the lifecycle of MLflow tracking server deployments on RHOAI/ODH" {
            controller = container "mlflow-operator" "Watches MLflow CRs, renders embedded Helm chart, reconciles resources via server-side apply" "Go (controller-runtime)" "operator"
            helmRenderer = container "Helm Renderer" "Embedded Helm chart engine that converts CR spec into Kubernetes manifests" "helm.sh/helm/v3" "library"
            mlflowServer = container "MLflow Tracking Server" "ML experiment tracking, model registry, artifact serving with Kubernetes RBAC auth" "Python (uvicorn)" "service"
            caBundleWatcher = container "CA Bundle Watcher" "Sidecar that watches CA bundle ConfigMap changes and regenerates combined trust bundle" "Shell script" "sidecar"
            combineCaBundles = container "Combine CA Bundles" "Init container that concatenates system, platform, and custom CA certificates" "Shell script" "init"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management and RBAC" "External"
        gateway = softwareSystem "Data Science Gateway" "Gateway API ingress (Envoy) for centralized external traffic routing" "Internal RHOAI"
        serviceCA = softwareSystem "OpenShift Service CA" "Automatic TLS certificate provisioning for cluster services" "Internal OpenShift"
        prometheus = softwareSystem "Prometheus Operator" "Metrics collection and monitoring via ServiceMonitor resources" "Internal OpenShift"
        console = softwareSystem "OpenShift Console" "Web console with application menu integration via ConsoleLink CR" "Internal OpenShift"
        caBundleCM = softwareSystem "odh-trusted-ca-bundle" "Platform CA certificate bundle ConfigMap for trust chain management" "Internal RHOAI"

        s3 = softwareSystem "S3-compatible Storage" "Artifact storage (AWS S3, MinIO, SeaweedFS)" "External"
        postgresql = softwareSystem "PostgreSQL" "Backend/registry metadata store" "External"
        mysql = softwareSystem "MySQL" "Backend/registry metadata store (alternative)" "External"

        # Relationships
        platformAdmin -> mlflowOperator "Creates/updates MLflow CR" "kubectl/oc"
        dataScientist -> mlflowOperator "Logs experiments, registers models" "HTTPS/443 via Gateway"

        controller -> helmRenderer "Renders chart with CR spec values" "In-process"
        controller -> k8sAPI "Watches CRs, server-side apply, discovery API" "HTTPS/6443"
        controller -> gateway "Creates HTTPRoute with parentRef" "Kubernetes API"
        controller -> serviceCA "Service annotation triggers cert provisioning" "Kubernetes API"
        controller -> console "Creates ConsoleLink for app menu" "Kubernetes API"
        controller -> prometheus "Creates ServiceMonitor for metrics scraping" "Kubernetes API"

        mlflowServer -> k8sAPI "SelfSubjectAccessReview for auth, namespace listing" "HTTPS/6443"
        mlflowServer -> s3 "Stores/retrieves ML artifacts" "HTTPS/443, HTTP/9000"
        mlflowServer -> postgresql "Reads/writes experiment and model metadata" "PostgreSQL/5432 TLS"
        mlflowServer -> mysql "Reads/writes experiment and model metadata (alt)" "MySQL/3306 TLS"

        gateway -> mlflowServer "Routes external traffic" "HTTPS/8443"
        prometheus -> mlflowServer "Scrapes /metrics endpoint" "HTTPS/8443"
        caBundleCM -> mlflowServer "Provides CA certificates" "Volume mount"

        combineCaBundles -> mlflowServer "Creates initial CA bundle" "Shared volume"
        caBundleWatcher -> mlflowServer "Regenerates CA bundle on changes" "Shared volume"
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
                background #4a90e2
                color #ffffff
            }
            element "operator" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "service" {
                background #7ed321
                color #ffffff
                shape RoundedBox
            }
            element "sidecar" {
                background #6baed6
                color #ffffff
                shape Circle
            }
            element "init" {
                background #6baed6
                color #ffffff
                shape Circle
            }
            element "library" {
                background #d5e8d4
                shape Component
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

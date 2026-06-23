workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML experiments, models, and artifacts via MLflow"
        platformAdmin = person "Platform Admin" "Manages MLflow CR and cluster configuration"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator managing MLflow tracking server lifecycle via Helm chart rendering and Gateway API integration" {
            controller = container "MLflow Controller" "Reconciles MLflow CRs, performs capability detection, manages migrations" "Go (controller-runtime)"
            helmRenderer = container "Helm Chart Renderer" "Renders embedded Helm chart (charts/mlflow) with CRD spec → Helm values" "Go (helm/v3 library)"
            migrationManager = container "Migration Manager" "Orchestrates zero-downtime DB migrations on version upgrades (scale→migrate→restore)" "Go"
            mlflowServer = container "MLflow Tracking Server" "Serves MLflow API with Kubernetes-native auth, workspaces, artifact serving" "Python (uvicorn, 8443/TCP HTTPS)"
            gcCronJob = container "GC CronJob" "Garbage collection for expired artifacts and experiments" "Python"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management and RBAC" "Infrastructure"
        gateway = softwareSystem "data-science-gateway" "Platform Gateway CR for external ingress routing (openshift-ingress namespace)" "Internal RHOAI"
        serviceCa = softwareSystem "OpenShift service-ca" "Auto-provisions and rotates TLS certificates for Services" "Internal OpenShift"
        caBundle = softwareSystem "odh-trusted-ca-bundle" "Platform CA bundle ConfigMap for TLS verification" "Internal RHOAI"
        console = softwareSystem "OpenShift Console" "Web console with application menu (ConsoleLink integration)" "Internal OpenShift"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor CRs" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Backend/registry metadata store for MLflow experiments and models" "External"
        mysql = softwareSystem "MySQL" "Alternative backend/registry metadata store" "External"
        s3 = softwareSystem "S3-compatible Storage" "Artifact storage (MinIO, SeaweedFS, AWS S3, GCS, Azure Blob)" "External"

        # User interactions
        dataScientist -> mlflowOperator "Creates experiments, logs runs, registers models" "HTTPS/443 via Gateway"
        platformAdmin -> mlflowOperator "Creates/updates MLflow CR" "kubectl, HTTPS/6443"

        # Internal container flows
        controller -> helmRenderer "Renders chart with CRD values"
        controller -> migrationManager "Triggers migration on version change"
        helmRenderer -> k8sApi "Server-Side Apply rendered objects" "HTTPS/6443"
        migrationManager -> k8sApi "Scale deployment, create/monitor migration Job" "HTTPS/6443"

        # External dependencies
        controller -> k8sApi "Watch CRs, Discovery API, SSA" "HTTPS/6443, TLS 1.2+"
        mlflowServer -> k8sApi "SelfSubjectAccessReview (auth)" "HTTPS/6443, TLS 1.2+"
        mlflowServer -> postgresql "Store/query experiment metadata" "TCP/5432, TLS optional"
        mlflowServer -> mysql "Store/query experiment metadata (alt)" "TCP/3306, TLS optional"
        mlflowServer -> s3 "Store/retrieve model artifacts" "HTTPS/443, AWS credentials"

        # Platform integrations
        gateway -> mlflowServer "Route traffic via HTTPRoute" "HTTPS/8443, TLS (service-ca)"
        serviceCa -> mlflowServer "Provision TLS certificates" "annotation-driven"
        caBundle -> mlflowServer "CA bundle volume mount" "ConfigMap"
        prometheus -> mlflowServer "Scrape metrics" "HTTPS/8443"
        prometheus -> controller "Scrape metrics" "HTTPS/8443"
        controller -> console "Create ConsoleLink CR" "HTTPS/6443"
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
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal OpenShift" {
                background #85bbf0
                color #ffffff
            }
            element "External" {
                background #f5a623
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

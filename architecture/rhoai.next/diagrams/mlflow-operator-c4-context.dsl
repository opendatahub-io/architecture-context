workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and tracks ML experiments, registers models"
        platformAdmin = person "Platform Admin" "Configures MLflow operator and manages platform"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator managing MLflow tracking server lifecycle via Helm chart rendering and Server-Side Apply" {
            mlflowReconciler = container "MLflowReconciler" "Primary controller: reconciles MLflow CRs into MLflow server deployments" "Go (controller-runtime)"
            mlflowOperatorReconciler = container "MLflowOperatorReconciler" "Module handoff controller: manages MLflowOperator CR for platform integration" "Go (controller-runtime)"
            namespaceRBACReconciler = container "NamespaceRBACReconciler" "Workspace RBAC controller: manages per-namespace RoleBindings from Auth CR groups" "Go (controller-runtime)"
            helmRenderer = container "HelmRenderer" "Renders embedded Helm chart (charts/mlflow) with CR-derived values" "Go (helm.sh/helm/v3)"
            securityProfileWatcher = container "SecurityProfileWatcher" "Watches OpenShift APIServer TLS profile changes" "Go"
        }

        mlflowServer = softwareSystem "MLflow Tracking Server" "MLflow server deployed as operand, provides experiment tracking and model registry" "Operand"

        # Platform Dependencies
        platformOperator = softwareSystem "opendatahub-operator / rhods-operator" "Platform operator that creates MLflowOperator module CR" "Internal RHOAI"
        dataScienceGateway = softwareSystem "data-science-gateway" "Gateway API (Envoy) for external ingress routing" "Internal RHOAI"
        openshiftConsole = softwareSystem "OpenShift Console" "Web console with ConsoleLink integration" "Internal OpenShift"
        authCR = softwareSystem "Auth CR" "Platform authentication configuration (allowedGroups, adminGroups)" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "Internal OpenShift"

        # External Dependencies
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "External"
        postgresql = softwareSystem "PostgreSQL" "Backend/registry store for MLflow metadata" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Artifact storage (MinIO, SeaweedFS, AWS S3, GCS)" "External"

        # Relationships - Users
        dataScientist -> mlflowServer "Tracks experiments, registers models" "HTTPS/8443"
        dataScientist -> dataScienceGateway "Accesses MLflow via gateway" "HTTPS/443"
        platformAdmin -> mlflowOperator "Creates/updates MLflow CR" "kubectl/HTTPS"

        # Relationships - Operator
        mlflowReconciler -> helmRenderer "Renders Helm chart" "In-process"
        mlflowReconciler -> kubernetesAPI "Server-Side Apply manifests, create HTTPRoute, ConsoleLink" "HTTPS/6443"
        mlflowOperatorReconciler -> kubernetesAPI "Watches MLflowOperator CR, updates status" "HTTPS/6443"
        namespaceRBACReconciler -> kubernetesAPI "Creates per-namespace RoleBindings" "HTTPS/6443"
        securityProfileWatcher -> kubernetesAPI "Watches APIServer TLS profile" "HTTPS/6443"

        # Relationships - Platform
        platformOperator -> mlflowOperator "Creates MLflowOperator module CR with gateway config"
        mlflowOperator -> dataScienceGateway "Creates HTTPRoute referencing gateway" "Gateway API"
        mlflowOperator -> openshiftConsole "Creates ConsoleLink for app menu" "ConsoleLink CRD"
        mlflowOperator -> authCR "Reads allowedGroups/adminGroups for workspace RBAC" "Watch"
        mlflowOperator -> prometheus "Creates ServiceMonitor for metrics scraping" "ServiceMonitor CRD"

        # Relationships - External
        dataScienceGateway -> mlflowServer "Routes traffic via HTTPRoute" "HTTPS/8443"
        mlflowServer -> postgresql "Stores experiment metadata" "PostgreSQL/5432 TLS"
        mlflowServer -> s3Storage "Stores/retrieves model artifacts" "HTTPS/443,9000"

        # Relationships - Operator to Operand
        mlflowOperator -> mlflowServer "Deploys and manages lifecycle" "Server-Side Apply"
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
                background #438DD5
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
            element "Internal OpenShift" {
                background #f5a623
                color #ffffff
            }
            element "Operand" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

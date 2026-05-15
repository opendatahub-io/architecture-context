workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages model registries for ML models"
        platformadmin = person "Platform Admin" "Manages RHOAI platform components and configuration"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator managing ModelRegistry and ModelCatalog lifecycle" {
            controller = container "ModelRegistry Controller" "Watches ModelRegistry CRs and reconciles Deployments, Services, Routes, NetworkPolicies, RBAC" "Go (controller-runtime)"
            catalogController = container "ModelCatalog Controller" "Manages singleton model catalog with PostgreSQL, kube-rbac-proxy, and catalog source discovery" "Go (controller-runtime)"
            migrationManager = container "Storage Migration Manager" "Performs CRD storage version migration v1alpha1 to v1beta1" "Go (background goroutine)"
            webhooks = container "Admission Webhooks" "Defaulting, validation, and conversion webhooks for ModelRegistry CRD" "Go (controller-runtime)"
        }

        modelRegistryREST = softwareSystem "Model Registry REST API" "REST API server for model metadata management" "Managed Container"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization sidecar using SubjectAccessReview" "Sidecar Container"

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management and auth delegation" "Infrastructure"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for external HTTPS/HTTP access" "Infrastructure"
        openshiftConfig = softwareSystem "OpenShift Config API" "Cluster configuration including ingress domain" "Infrastructure"

        postgresql = softwareSystem "PostgreSQL" "Relational database for model registry metadata storage" "Database"
        mysql = softwareSystem "MySQL" "Alternative relational database for model registry metadata" "Database"

        platformOperator = softwareSystem "ODH/RHOAI Platform Operator" "Deploys and configures this operator with image overrides via params.env" "Internal Platform"
        platformModelRegistry = softwareSystem "Platform ModelRegistry CR" "components.platform.opendatahub.io/ModelRegistry - owner reference for catalog" "Internal Platform"
        platformAuth = softwareSystem "Platform Auth CR" "services.platform.opendatahub.io/Auth - provides admin groups for catalog RBAC" "Internal Platform"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI consuming routing annotations for external URLs" "Internal Platform"

        certManager = softwareSystem "cert-manager" "Optional TLS certificate provisioning" "External"

        # Relationships
        datascientist -> openshiftRouter "Creates/queries model registries" "HTTPS/443"
        platformadmin -> modelRegistryOperator "Creates ModelRegistry CRs" "kubectl / HTTPS"

        openshiftRouter -> kubeRBACProxy "Forwards requests (reencrypt)" "HTTPS/8443"
        kubeRBACProxy -> kubernetesAPI "TokenReview + SubjectAccessReview" "HTTPS/6443"
        kubeRBACProxy -> modelRegistryREST "Pre-authorized upstream" "HTTP/8080"
        modelRegistryREST -> postgresql "Stores/retrieves model metadata" "PostgreSQL/5432"
        modelRegistryREST -> mysql "Alternative metadata storage" "MySQL/3306"

        controller -> kubernetesAPI "CRUD on Deployments, Services, Routes, RBAC, NetworkPolicies" "HTTPS/6443"
        controller -> openshiftConfig "Reads cluster ingress domain" "HTTPS/6443"
        catalogController -> kubernetesAPI "Manages catalog resources" "HTTPS/6443"
        catalogController -> platformModelRegistry "Owner reference lookup" "HTTPS/6443"
        catalogController -> platformAuth "Reads admin groups" "HTTPS/6443"
        migrationManager -> kubernetesAPI "Creates StorageVersionMigration or manual re-read/write" "HTTPS/6443"
        webhooks -> kubernetesAPI "Called by API server for admission" "HTTPS/9443"

        platformOperator -> modelRegistryOperator "Deploys operator, provides params.env" "Kustomize"
        odhDashboard -> modelRegistryREST "Reads routing annotations for external URL" "Annotation"
        certManager -> modelRegistryOperator "Provisions TLS certs (optional)" "Certificate CR"
    }

    views {
        systemContext modelRegistryOperator "SystemContext" {
            include *
            autoLayout
        }

        container modelRegistryOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #d0021b
                color #ffffff
            }
            element "Database" {
                background #f5a623
                color #ffffff
                shape Cylinder
            }
            element "Managed Container" {
                background #4a90e2
                color #ffffff
            }
            element "Sidecar Container" {
                background #50e3c2
                color #333333
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

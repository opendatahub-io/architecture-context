workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML model registries and accesses model metadata"
        platformAdmin = person "Platform Admin" "Deploys and configures RHOAI platform components"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator managing Model Registry and Model Catalog lifecycle" {
            mrReconciler = container "ModelRegistryReconciler" "Reconciles individual ModelRegistry CRs with full lifecycle management" "Go Controller (controller-runtime)"
            mcReconciler = container "ModelCatalogReconciler" "Manages singleton Model Catalog service with catalog source discovery" "Go Controller (controller-runtime)"
            webhookServer = container "Webhook Server" "Defaulting, validating, and conversion webhooks for ModelRegistry CRs" "Go Admission Webhook"
            migrationManager = container "StorageMigrationManager" "Handles CRD storage version migration from v1alpha1 to v1beta1" "Go Background Goroutine"
        }

        modelRegistryAPI = softwareSystem "Model Registry REST API" "REST API service for model metadata management" {
            restContainer = container "REST API Container" "Serves Model Registry REST API" "Go HTTP Server"
            kubeRBACProxy = container "kube-rbac-proxy" "Authentication/authorization sidecar proxy" "Go HTTPS Proxy"
        }

        modelCatalogAPI = softwareSystem "Model Catalog Service" "Catalog service for discovering ML models" {
            catalogContainer = container "Catalog REST API" "Serves Model Catalog API with seed data" "Go HTTP Server"
            catalogProxy = container "kube-rbac-proxy (Catalog)" "Auth sidecar for catalog" "Go HTTPS Proxy"
        }

        postgresql = softwareSystem "PostgreSQL" "Relational database for model metadata storage" "Database"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for external HTTPS access" "External"
        openshiftConfig = softwareSystem "OpenShift Config API" "Cluster configuration (ingress domain)" "External"
        platformAuth = softwareSystem "Platform Auth CR" "RHOAI platform authentication and admin group configuration" "Internal RHOAI"
        platformMRComponent = softwareSystem "Platform ModelRegistry CR" "RHOAI platform component for model registry" "Internal RHOAI"
        rhodsOperator = softwareSystem "RHODS / ODH Operator" "Platform operator that deploys model-registry-operator" "Internal RHOAI"
        storageVersionMigrationAPI = softwareSystem "StorageVersionMigration API" "Kubernetes API for CRD version migration" "External"

        # Relationships
        dataScientist -> openshiftRouter "Accesses Model Registry via HTTPS Route" "HTTPS/443"
        dataScientist -> openshiftRouter "Accesses Model Catalog via HTTPS Route" "HTTPS/443"
        platformAdmin -> modelRegistryOperator "Creates ModelRegistry CRs via kubectl" "HTTPS/443"

        rhodsOperator -> modelRegistryOperator "Deploys via kustomize manifests"

        openshiftRouter -> kubeRBACProxy "TLS reencrypt" "HTTPS/8443"
        kubeRBACProxy -> kubernetesAPI "TokenReview + SubjectAccessReview" "HTTPS/443"
        kubeRBACProxy -> restContainer "Proxied requests" "HTTP/8080"

        openshiftRouter -> catalogProxy "TLS reencrypt" "HTTPS/8443"
        catalogProxy -> kubernetesAPI "TokenReview + SubjectAccessReview" "HTTPS/443"
        catalogProxy -> catalogContainer "Proxied requests" "HTTP/8080"

        mrReconciler -> kubernetesAPI "CRUD on managed resources" "HTTPS/443"
        mrReconciler -> openshiftConfig "Read cluster ingress domain" "HTTPS/443"
        mcReconciler -> kubernetesAPI "CRUD on managed resources" "HTTPS/443"
        mcReconciler -> platformAuth "Read admin groups for catalog RBAC" "HTTPS/443"
        mcReconciler -> platformMRComponent "Owner reference for cascading deletion" "HTTPS/443"
        migrationManager -> storageVersionMigrationAPI "Create migration resources" "HTTPS/443"
        migrationManager -> kubernetesAPI "Fallback manual migration" "HTTPS/443"

        restContainer -> postgresql "Query/persist model metadata" "PostgreSQL/5432"
        catalogContainer -> postgresql "Query/persist catalog data" "PostgreSQL/5432"

        webhookServer -> kubernetesAPI "Admission webhook registration" "HTTPS/443"
    }

    views {
        systemContext modelRegistryOperator "SystemContext" {
            include *
            autoLayout
        }

        container modelRegistryOperator "OperatorContainers" {
            include *
            autoLayout
        }

        container modelRegistryAPI "RegistryContainers" {
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
                color #000000
            }
            element "Database" {
                background #438dd5
                color #ffffff
                shape Cylinder
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
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

workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates ModelRegistry instances and accesses model metadata"
        admin = person "Platform Admin" "Deploys and configures the model-registry-operator"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Manages lifecycle of ModelRegistry, Catalog, and AIHub custom resources" {
            controllerManager = container "Controller Manager" "Reconciles ModelRegistry and Catalog CRDs, manages resource lifecycle" "Go / controller-runtime"
            webhookServer = container "Webhook Server" "Validates, mutates, and converts ModelRegistry CRDs" "Go / controller-runtime"
            mrReconciler = component "ModelRegistryReconciler" "Reconciles ModelRegistry CRs" "Go"
            mcReconciler = component "ModelCatalogReconciler" "Reconciles Catalog CRs" "Go"
        }

        managedRegistry = softwareSystem "Model Registry Instance" "REST API serving model metadata backed by PostgreSQL" {
            restContainer = container "rest-container" "Model registry REST API server" "Go / :8080 HTTP"
            kubeRbacProxy = container "kube-rbac-proxy" "TLS-terminating auth proxy with SubjectAccessReview" "Go / :8443 HTTPS"
            postgresDB = container "PostgreSQL" "Persistent storage for model metadata" "PostgreSQL / :5432"
        }

        managedCatalog = softwareSystem "Model Catalog Instance" "Centralized catalog service with PostgreSQL backend" {
            catalogService = container "catalog" "Catalog REST API" "Go / :8080 HTTP"
            catalogProxy = container "kube-rbac-proxy (catalog)" "TLS-terminating auth proxy" "Go / :8443 HTTPS"
            catalogPostgres = container "PostgreSQL (catalog)" "Catalog data storage" "PostgreSQL / :5432"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for ingress routing" "External"
        dataScienceGateway = softwareSystem "data-science-gateway" "Platform-level API Gateway" "Internal RHOAI"
        openshiftRoutes = softwareSystem "OpenShift Routes" "OpenShift-native ingress for backward compatibility" "External"
        istioClientGo = softwareSystem "Istio" "Service mesh client libraries" "External"
        certManager = softwareSystem "cert-manager" "Certificate management (TLS for webhooks)" "External"
        openshiftConfig = softwareSystem "OpenShift Config API" "Cluster configuration (ingress domain, TLS profile)" "External"
        platformAuth = softwareSystem "Platform Auth Service" "RHOAI platform authentication configuration" "Internal RHOAI"

        # Relationships
        admin -> modelRegistryOperator "Deploys operator, creates CRDs"
        user -> managedRegistry "Accesses model metadata via REST API" "HTTPS/8443"
        user -> managedCatalog "Browses model catalog" "HTTPS/8443"

        modelRegistryOperator -> kubernetesAPI "Watches CRs, manages resources" "HTTPS/6443"
        modelRegistryOperator -> managedRegistry "Creates and manages" "Kubernetes API"
        modelRegistryOperator -> managedCatalog "Creates and manages" "Kubernetes API"
        modelRegistryOperator -> gatewayAPI "Creates HTTPRoutes" "Kubernetes API"
        modelRegistryOperator -> openshiftRoutes "Creates Routes (fallback)" "Kubernetes API"
        modelRegistryOperator -> openshiftConfig "Reads cluster domain, TLS profile" "Kubernetes API"
        modelRegistryOperator -> platformAuth "Reads auth configuration" "Kubernetes API"

        kubeRbacProxy -> kubernetesAPI "SubjectAccessReview authorization" "HTTPS/6443"
        restContainer -> postgresDB "SQL queries" "PostgreSQL/5432"
        catalogService -> catalogPostgres "SQL queries" "PostgreSQL/5432"

        dataScienceGateway -> managedRegistry "Routes traffic via HTTPRoute" "HTTPS"
        openshiftRoutes -> managedRegistry "Routes traffic via Route" "HTTPS"
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

        container managedRegistry "RegistryContainers" {
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
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

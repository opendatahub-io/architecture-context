workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages model registries, registers ML models"
        platformAdmin = person "Platform Admin" "Deploys and configures the Model Registry Operator"
        apiClient = person "API Client" "Accesses model registry and catalog REST APIs"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Manages ModelRegistry and ModelCatalog custom resources, provisioning all necessary Kubernetes resources for model metadata storage and discovery" {
            mrReconciler = container "ModelRegistryReconciler" "Reconciles individual ModelRegistry CRs, creates per-registry resources" "Go Controller (controller-runtime)"
            mcReconciler = container "ModelCatalogReconciler" "Reconciles a singleton model catalog instance with its own Deployment, Service, PostgreSQL, and RBAC" "Go Controller (controller-runtime)"
            svmManager = container "StorageMigrationManager" "Handles CRD storage version migration (v1alpha1 to v1beta1) via SVM API or manual strategy" "Go"
            mutatingWebhook = container "Mutating Webhook" "Defaults ModelRegistry fields (database config, kube-rbac-proxy, OAuth to KRBP migration)" "Go Webhook Server"
            validatingWebhook = container "Validating Webhook" "Validates ModelRegistry spec (namespace, database config, unique names)" "Go Webhook Server"
        }

        perRegistryStack = softwareSystem "Per-Registry Stack" "Provisioned resources for each ModelRegistry CR" {
            restContainer = container "rest-container" "Model registry REST API server" "Go/Python Service"
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication sidecar using SubjectAccessReview" "Sidecar Proxy"
            registryPostgres = container "PostgreSQL" "Model registry metadata storage (auto-provisioned or external)" "PostgreSQL 16"
        }

        modelCatalogStack = softwareSystem "Model Catalog Stack" "Singleton catalog service for model discovery" {
            catalogContainer = container "Catalog Container" "Model catalog REST API server" "Go/Python Service"
            catalogProxy = container "kube-rbac-proxy (catalog)" "Authentication sidecar for catalog" "Sidecar Proxy"
            catalogPostgres = container "model-catalog-postgres" "Catalog metadata storage" "PostgreSQL 16"
            catalogDataInit = container "catalog-data-init" "Provides default model metadata" "Init Container"
        }

        # External systems
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management, RBAC, and admission control" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller providing external HTTPS access via Routes" "External"
        openshiftPlatform = softwareSystem "OpenShift Platform" "Provides serving certificates, User API, Config API" "External"
        odhPlatform = softwareSystem "ODH/RHOAI Platform" "Platform CRDs (components.platform, services.platform)" "Internal ODH"
        externalDB = softwareSystem "External Database" "External PostgreSQL or MySQL instance for model registry storage" "External"

        # Relationships - Users
        platformAdmin -> modelRegistryOperator "Deploys operator, creates ModelRegistry CRs via kubectl" "HTTPS/443"
        dataScientist -> openshiftRouter "Accesses model registry REST API" "HTTPS/443"
        apiClient -> openshiftRouter "Accesses model catalog REST API" "HTTPS/443"

        # Relationships - Operator internals
        mrReconciler -> k8sAPI "CRUD on Deployments, Services, Routes, RBAC, NetworkPolicies" "HTTPS/443"
        mcReconciler -> k8sAPI "CRUD on catalog Deployment, Service, Route, RBAC" "HTTPS/443"
        svmManager -> k8sAPI "Creates StorageVersionMigration resources" "HTTPS/443"
        k8sAPI -> mutatingWebhook "Sends admission requests for ModelRegistry CRs" "HTTPS/9443"
        k8sAPI -> validatingWebhook "Sends validation requests for ModelRegistry CRs" "HTTPS/9443"

        # Relationships - Operator to platform
        mcReconciler -> odhPlatform "Reads ModelRegistry platform CR and Auth CR" "HTTPS/443"
        mrReconciler -> openshiftPlatform "Reads cluster Ingress domain, creates Routes and Groups" "HTTPS/443"

        # Relationships - Runtime
        openshiftRouter -> kubeRbacProxy "Forwards requests with TLS reencrypt" "HTTPS/8443"
        kubeRbacProxy -> restContainer "Proxies authenticated requests" "HTTP/8080"
        kubeRbacProxy -> k8sAPI "SubjectAccessReview authorization" "HTTPS/443"
        restContainer -> registryPostgres "Queries model metadata" "PostgreSQL/5432"
        restContainer -> externalDB "Queries model metadata (if external DB)" "PostgreSQL/5432 or MySQL/3306"

        openshiftRouter -> catalogProxy "Forwards catalog requests with TLS reencrypt" "HTTPS/8443"
        catalogProxy -> catalogContainer "Proxies authenticated requests" "HTTP/8080"
        catalogProxy -> k8sAPI "SubjectAccessReview authorization" "HTTPS/443"
        catalogContainer -> catalogPostgres "Queries catalog metadata" "PostgreSQL/5432"
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

        container perRegistryStack "RegistryContainers" {
            include *
            autoLayout
        }

        container modelCatalogStack "CatalogContainers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

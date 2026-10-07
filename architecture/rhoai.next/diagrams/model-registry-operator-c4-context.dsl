workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages ML model registries and model metadata"
        platformadmin = person "Platform Admin" "Configures AIHub, Catalog, and operator settings"

        mro = softwareSystem "Model Registry Operator" "Manages lifecycle of Model Registry instances, Model Catalog, and AIHub platform component" {
            controllerManager = container "Controller Manager" "Hosts all controllers and admission webhooks" "Go (kubebuilder)"
            aiHubReconciler = container "AIHubReconciler" "Manages cluster-scoped AIHub resource, orchestrates Catalog lifecycle" "Go Controller"
            catalogReconciler = container "CatalogReconciler" "Deploys shared Model Catalog service with PostgreSQL and kube-rbac-proxy" "Go Controller"
            mrReconciler = container "ModelRegistryReconciler" "Reconciles ModelRegistry CRs into deployment stacks" "Go Controller"
            webhookServer = container "Webhook Server" "Mutating, validating, and CRD conversion webhooks for ModelRegistry" "Go Admission Webhook"
        }

        modelRegistry = softwareSystem "Model Registry Instance" "REST API for ML model metadata management, deployed per ModelRegistry CR" {
            registryServer = container "model-registry REST" "REST API serving model metadata" "External Container" "8080/TCP"
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication sidecar performing TokenReview and SubjectAccessReview" "Sidecar" "8443/TCP"
            postgresDB = container "PostgreSQL 16" "Per-registry metadata storage" "Database" "5432/TCP"
        }

        modelCatalog = softwareSystem "Model Catalog" "Shared platform catalog for model metadata discovery" {
            catalogService = container "model-catalog" "Catalog REST API aggregating catalog sources" "External Container" "8080/TCP"
            catalogProxy = container "kube-rbac-proxy" "Authentication sidecar" "Sidecar" "8443/TCP"
            catalogPostgres = container "PostgreSQL 16" "Catalog metadata storage" "Database" "5432/TCP"
        }

        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource management and auth delegation" "External"
        openshiftApi = softwareSystem "OpenShift API" "Platform configuration: TLS profiles, ingress domain, proxy settings" "External"
        gatewayApi = softwareSystem "Gateway API" "Platform ingress via data-science-gateway" "External"
        openshiftRoutes = softwareSystem "OpenShift Routes" "Legacy ingress for registry and catalog endpoints" "External"
        odhOperator = softwareSystem "ODH/RHOAI Operator" "Parent operator that deploys model-registry-operator" "Internal Platform"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Shared Go library for platform detection and manifest rendering" "Internal Platform"

        // Relationships
        platformadmin -> mro "Configures AIHub and ModelRegistry CRs via kubectl"
        datascientist -> modelRegistry "Accesses model metadata REST API" "HTTPS/443"
        datascientist -> modelCatalog "Discovers models in shared catalog" "HTTPS/443"

        mro -> k8sApi "Reconciliation, RBAC, discovery, auth delegation" "HTTPS/6443"
        mro -> openshiftApi "Reads TLS profile, ingress domain, proxy config" "HTTPS/6443"
        mro -> gatewayApi "Creates HTTPRoutes for registry and catalog ingress"
        mro -> openshiftRoutes "Creates Routes for registry and catalog ingress"

        odhOperator -> mro "Deploys operator via Kustomize overlay" "Kustomize"

        controllerManager -> aiHubReconciler "Hosts"
        controllerManager -> catalogReconciler "Hosts"
        controllerManager -> mrReconciler "Hosts"
        controllerManager -> webhookServer "Hosts"

        mrReconciler -> modelRegistry "Creates and manages per-CR deployment stack"
        catalogReconciler -> modelCatalog "Creates and manages shared catalog deployment"
        aiHubReconciler -> catalogReconciler "Orchestrates Catalog CR lifecycle"

        kubeRbacProxy -> k8sApi "TokenReview + SubjectAccessReview" "HTTPS/6443"
        catalogProxy -> k8sApi "TokenReview + SubjectAccessReview" "HTTPS/6443"
        registryServer -> postgresDB "Model metadata queries" "PostgreSQL/5432"
        catalogService -> catalogPostgres "Catalog metadata queries" "PostgreSQL/5432"
    }

    views {
        systemContext mro "SystemContext" {
            include *
            autoLayout
        }

        container mro "OperatorContainers" {
            include *
            autoLayout
        }

        container modelRegistry "RegistryContainers" {
            include *
            autoLayout
        }

        container modelCatalog "CatalogContainers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
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
            element "Database" {
                shape cylinder
                background #438dd5
                color #ffffff
            }
        }
    }
}

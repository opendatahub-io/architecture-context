workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages model registry instances for ML model metadata"
        platformAdmin = person "Platform Admin" "Deploys and configures the model-registry-operator on RHOAI"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator managing ModelRegistry and ModelCatalog lifecycle on RHOAI" {
            controllerManager = container "Controller Manager" "Dual-reconciler managing ModelRegistry and ModelCatalog CRs" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates, mutates, and converts ModelRegistry CRs" "Go (admission webhooks)"
            svmStrategy = container "SVM Strategy" "Orchestrates CRD version migration from v1alpha1 to v1beta1" "Go"
        }

        registryInstance = softwareSystem "Registry Instance" "Per-ModelRegistry deployment stack" {
            restContainer = container "REST API" "Model Registry REST API serving metadata" "Container (port 8080)"
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication sidecar enforcing SubjectAccessReview" "Container (port 8443)"
            postgresDB = container "PostgreSQL" "Metadata storage backend for registry data" "PostgreSQL (port 5432)"
        }

        modelCatalog = softwareSystem "Model Catalog" "Parallel deployment for model catalog functionality" {
            catalogContainer = container "Catalog API" "Model Catalog REST API" "Container (port 8080)"
            catalogProxy = container "kube-rbac-proxy" "Authentication sidecar for catalog" "Container (port 8443)"
            catalogPostgres = container "PostgreSQL" "Metadata storage for catalog" "PostgreSQL (port 5432)"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        openshiftIngress = softwareSystem "OpenShift Ingress Config" "Cluster ingress configuration (config.openshift.io/v1)" "External"
        gatewayAPI = softwareSystem "Gateway API (data-science-gateway)" "Platform ingress gateway for data science services" "Internal RHOAI"
        openshiftRoutes = softwareSystem "OpenShift Routes" "OpenShift Route-based ingress" "External"
        storageMigration = softwareSystem "StorageVersionMigration" "Kubernetes CRD version migration controller" "External"

        # Relationships - Operator
        platformAdmin -> modelRegistryOperator "Deploys operator and creates ModelRegistry CRs"
        dataScientist -> registryInstance "Accesses model metadata via REST API" "HTTPS/8443"

        controllerManager -> kubernetesAPI "CRUD operations, watches, SubjectAccessReview" "HTTPS/6443"
        controllerManager -> openshiftIngress "Reads cluster domain for Route hostnames" "HTTPS"
        controllerManager -> registryInstance "Creates and manages per-instance deployments"
        controllerManager -> modelCatalog "Creates and manages catalog deployments"
        webhookServer -> kubernetesAPI "Receives admission requests" "HTTPS"
        svmStrategy -> storageMigration "Creates StorageVersionMigration resources" "HTTPS"

        # Relationships - Registry Instance
        kubeRbacProxy -> kubernetesAPI "SubjectAccessReview authorization" "HTTPS/6443"
        kubeRbacProxy -> restContainer "Proxies authorized requests" "HTTP/8080"
        restContainer -> postgresDB "Stores and retrieves model metadata" "PostgreSQL/5432"

        # Relationships - Model Catalog
        catalogProxy -> kubernetesAPI "SubjectAccessReview authorization" "HTTPS/6443"
        catalogProxy -> catalogContainer "Proxies authorized requests" "HTTP/8080"
        catalogContainer -> catalogPostgres "Stores and retrieves catalog data" "PostgreSQL/5432"

        # Relationships - Ingress
        controllerManager -> openshiftRoutes "Creates TLS Routes for registry instances" "HTTPS"
        controllerManager -> gatewayAPI "Creates HTTPRoutes for gateway ingress" "HTTPS"
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

        container registryInstance "RegistryContainers" {
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
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
        }
    }
}

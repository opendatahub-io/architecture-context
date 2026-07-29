workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML model registries and catalog entries"
        platformAdmin = person "Platform Admin" "Configures model registry instances and platform settings"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator managing ModelRegistry CRs, provisioning registry services, databases, RBAC, and network policies" {
            controllerManager = container "Controller Manager" "Runs ModelRegistryReconciler and ModelCatalogReconciler controllers" "Go controller-runtime Operator"
            webhookServer = container "Webhook Server" "Conversion, mutating, and validating admission webhooks for ModelRegistry CRs" "Go controller-runtime :9443"
            metricsServer = container "Metrics Server" "Operator metrics with TokenReview+SAR authentication" "controller-runtime :8443"
            svmManager = container "StorageMigrationManager" "Handles CRD storage version migration v1alpha1 → v1beta1" "Go"
            securityWatcher = container "SecurityProfileWatcher" "Watches OpenShift TLS security profile changes and triggers pod restart" "Go"
        }

        registryInstance = softwareSystem "Model Registry Instance" "Per-registry deployment with REST API, kube-rbac-proxy, and PostgreSQL" {
            kubeRBACProxy = container "kube-rbac-proxy" "HTTPS proxy performing TokenReview and SubjectAccessReview" "kube-rbac-proxy :8443"
            restContainer = container "REST Container" "Model registry REST API serving model metadata" "Go/Python :8080"
            registryPostgres = container "PostgreSQL" "Per-registry metadata database" "PostgreSQL :5432"
        }

        modelCatalog = softwareSystem "Model Catalog" "Centralized model catalog with kube-rbac-proxy and PostgreSQL" {
            catalogProxy = container "kube-rbac-proxy" "HTTPS proxy for catalog API authentication" "kube-rbac-proxy :8443"
            catalogContainer = container "Catalog Container" "Model catalog REST API" "Go/Python :8080"
            catalogPostgres = container "PostgreSQL" "Catalog metadata database" "PostgreSQL :5432"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management, RBAC, and admission" "External"
        openShiftAPI = softwareSystem "OpenShift API" "OpenShift-specific APIs for Routes, Users, Groups, TLS profiles" "External"
        gatewayAPI = softwareSystem "Gateway API (data-science-gateway)" "Platform ingress via HTTPRoute resources" "External"
        openShiftRoutes = softwareSystem "OpenShift Routes" "Direct HTTPS exposure for registry and catalog endpoints" "External"

        # Relationships - Users
        dataScientist -> registryInstance "Creates/queries model metadata" "HTTPS/8443 via Route or HTTPRoute"
        dataScientist -> modelCatalog "Browses model catalog" "HTTPS/8443 via Route or HTTPRoute"
        platformAdmin -> modelRegistryOperator "Creates ModelRegistry CRs" "kubectl / HTTPS"

        # Relationships - Operator to managed resources
        controllerManager -> kubernetesAPI "CRUD Deployments, Services, Secrets, RBAC, NetworkPolicies" "HTTPS/6443 TLS 1.2+"
        controllerManager -> openShiftAPI "CRUD Routes, Users, Groups; fetch TLS profiles" "HTTPS/6443 TLS 1.2+"
        controllerManager -> registryInstance "Creates and reconciles per-registry deployments" "Kubernetes API"
        controllerManager -> modelCatalog "Creates and reconciles catalog deployment" "Kubernetes API"
        controllerManager -> gatewayAPI "Creates HTTPRoute resources" "Kubernetes API"
        controllerManager -> openShiftRoutes "Creates Route resources" "Kubernetes API"

        # Relationships - Internal
        webhookServer -> controllerManager "Mutated/validated CRs trigger reconciliation"
        securityWatcher -> openShiftAPI "Watches TLS security profile changes" "HTTPS"

        # Relationships - Auth delegation
        kubeRBACProxy -> kubernetesAPI "TokenReview + SubjectAccessReview" "HTTPS/6443"
        catalogProxy -> kubernetesAPI "TokenReview + SubjectAccessReview" "HTTPS/6443"

        # Relationships - Data
        kubeRBACProxy -> restContainer "Forwards authenticated requests" "HTTP/8080 localhost"
        restContainer -> registryPostgres "Stores/retrieves model metadata" "PostgreSQL/5432"
        catalogProxy -> catalogContainer "Forwards authenticated requests" "HTTP/8080 localhost"
        catalogContainer -> catalogPostgres "Stores/retrieves catalog data" "PostgreSQL/5432"
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

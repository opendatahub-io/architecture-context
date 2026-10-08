workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages ML model registries and model metadata"
        platformadmin = person "Platform Admin" "Deploys and configures the RHOAI platform"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Deploys and manages Model Registry instances, Model Catalog, and AI Hub for the RHOAI platform" {
            mrReconciler = container "ModelRegistryReconciler" "Reconciles ModelRegistry CRs into registry deployments with kube-rbac-proxy sidecars" "Go Controller"
            catalogReconciler = container "CatalogReconciler" "Deploys shared Model Catalog service with PostgreSQL and kube-rbac-proxy" "Go Controller"
            aihubReconciler = container "AIHubReconciler" "Manages Catalog CR lifecycle and platform-level webhook/RBAC infrastructure" "Go Controller"
            webhookServer = container "Admission Webhooks" "Validates, defaults, and converts ModelRegistry CRs (v1alpha1 ↔ v1beta1)" "Go Webhook Server"
            templateApplier = container "TemplateApplier" "Renders embedded YAML templates with ModelRegistryParams/CatalogParams" "Go Library"
        }

        registryInstance = softwareSystem "Model Registry Instance" "Per-CR deployment serving Model Registry REST API backed by PostgreSQL/MySQL" {
            registryServer = container "Model Registry Server" "REST API for ML model metadata (artifacts, versions, endpoints)" "Go Service"
            kubeRbacProxy = container "kube-rbac-proxy" "Token-based auth proxy performing TokenReview and SubjectAccessReview" "Go Sidecar"
            registryDB = container "PostgreSQL/MySQL" "Metadata storage backend for a single registry" "Database"
        }

        catalogInstance = softwareSystem "Model Catalog" "Shared catalog service aggregating model metadata across registries" {
            catalogServer = container "Model Catalog Server" "Aggregated model metadata API" "Go Service"
            catalogProxy = container "kube-rbac-proxy (Catalog)" "Auth proxy for catalog API" "Go Sidecar"
            catalogDB = container "Catalog PostgreSQL" "Shared catalog metadata database" "PostgreSQL 16"
        }

        odhOperator = softwareSystem "opendatahub-operator" "Platform operator that deploys RHOAI components" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management and auth" "External"
        openshiftRoutes = softwareSystem "OpenShift Routes" "External HTTPS ingress for OpenShift clusters" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes-native ingress via data-science-gateway" "External"
        openshiftUsers = softwareSystem "OpenShift Users/Groups API" "User and group management for access control" "External"
        platformAuth = softwareSystem "Platform Auth Service" "services.platform.opendatahub.io/Auth CR for authentication config" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Relational database for model metadata storage" "External"
        mysql = softwareSystem "MySQL" "Alternative relational database backend" "External"

        # Relationships
        platformadmin -> odhOperator "Deploys RHOAI platform"
        odhOperator -> modelRegistryOperator "Creates AIHub CR to orchestrate" "HTTPS/6443"
        datascientist -> registryInstance "Creates/queries model metadata" "HTTPS/443 via Route"
        datascientist -> catalogInstance "Browses shared model catalog" "HTTPS/443 via Route"

        modelRegistryOperator -> k8sAPI "Reconciles CRs, manages resources" "HTTPS/6443"
        modelRegistryOperator -> openshiftRoutes "Creates Routes for external access" "HTTPS/6443"
        modelRegistryOperator -> gatewayAPI "Creates HTTPRoutes for ingress" "HTTPS/6443"
        modelRegistryOperator -> openshiftUsers "Manages per-registry Groups" "HTTPS/6443"
        modelRegistryOperator -> platformAuth "Reads Auth CR for catalog config" "HTTPS/6443"

        mrReconciler -> templateApplier "Renders deployment templates"
        aihubReconciler -> catalogReconciler "Creates/manages Catalog CR"

        registryServer -> registryDB "Queries metadata" "TCP/5432 or TCP/3306"
        kubeRbacProxy -> k8sAPI "TokenReview + SubjectAccessReview" "HTTPS/6443"
        kubeRbacProxy -> registryServer "Forwards authorized requests" "HTTP/8080"

        catalogServer -> catalogDB "Queries catalog metadata" "TCP/5432"
        catalogProxy -> k8sAPI "TokenReview + SubjectAccessReview" "HTTPS/6443"
        catalogProxy -> catalogServer "Forwards authorized requests" "HTTP/8080"
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

        container catalogInstance "CatalogContainers" {
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

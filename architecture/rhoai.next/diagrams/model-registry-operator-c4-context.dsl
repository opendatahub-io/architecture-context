workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Model Registry instances, registers ML models"
        platformAdmin = person "Platform Admin" "Deploys and configures the operator via RHOAI/ODH platform"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator managing ModelRegistry and ModelCatalog instances" {
            mrReconciler = container "ModelRegistryReconciler" "Reconciles individual ModelRegistry CRs with full lifecycle management" "Go Controller"
            mcReconciler = container "ModelCatalogReconciler" "Reconciles singleton Model Catalog service with catalog source discovery" "Go Controller"
            webhookServer = container "Webhook Server" "Defaulting, Validating, and Conversion webhooks for ModelRegistry CRDs" "Go Admission Webhook"
            migrationManager = container "StorageMigrationManager" "Handles CRD storage version migration v1alpha1 to v1beta1" "Go Background Worker"
        }

        modelRegistryInstance = softwareSystem "Model Registry Instance" "Deployed REST API for model metadata management" {
            restAPI = container "Model Registry REST API" "REST API for model metadata CRUD operations" "Go/Python Service" "8080/TCP"
            kubeRBACProxy = container "kube-rbac-proxy" "Authentication/authorization sidecar proxy" "Go Proxy" "8443/TCP"
            postgresDB = container "PostgreSQL" "Database backend for model metadata storage" "PostgreSQL 16" "5432/TCP"
        }

        modelCatalogInstance = softwareSystem "Model Catalog" "Singleton catalog service for curated model discovery" {
            catalogAPI = container "Catalog REST API" "REST API for model catalog browsing" "Go/Python Service" "8080/TCP"
            catalogProxy = container "kube-rbac-proxy (Catalog)" "Authentication/authorization sidecar" "Go Proxy" "8443/TCP"
            catalogDB = container "PostgreSQL (Catalog)" "Database backend for catalog data" "PostgreSQL 16" "5432/TCP"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource management" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for external HTTPS access" "External"
        openshiftPlatform = softwareSystem "OpenShift Platform APIs" "config.openshift.io, route.openshift.io, user.openshift.io" "External"
        rhoaiPlatform = softwareSystem "RHOAI Platform" "Platform operator deploying and managing ODH/RHOAI components" "Internal ODH" {
            platformAuthCR = container "Auth CR" "Admin group configuration for catalog authorization" "services.platform.opendatahub.io/Auth"
            platformMRCR = container "ModelRegistry CR" "Platform component enabling model registry" "components.platform.opendatahub.io/ModelRegistry"
        }
        externalPostgres = softwareSystem "External PostgreSQL" "User-provided external database backend" "External"

        // User interactions
        dataScientist -> openshiftRouter "Accesses Model Registry via HTTPS Route" "HTTPS/443 + Bearer Token"
        platformAdmin -> kubernetesAPI "Creates ModelRegistry CRs via kubectl" "HTTPS/443"

        // Operator interactions
        modelRegistryOperator -> kubernetesAPI "CRUD on managed resources, RBAC delegation, webhook registration" "HTTPS/443 TLS + SA Token"
        modelRegistryOperator -> openshiftPlatform "Read ingress domain, manage Routes and Groups" "HTTPS/443 TLS"
        modelRegistryOperator -> rhoaiPlatform "Read Auth CR admin groups, discover default model registry" "HTTPS/443 TLS"

        // Operator creates instances
        mrReconciler -> modelRegistryInstance "Creates and manages" "Kubernetes Resources"
        mcReconciler -> modelCatalogInstance "Creates and manages" "Kubernetes Resources"

        // Instance data flows
        openshiftRouter -> kubeRBACProxy "Forwards with TLS reencrypt" "HTTPS/8443"
        kubeRBACProxy -> kubernetesAPI "TokenReview + SubjectAccessReview" "HTTPS/443"
        kubeRBACProxy -> restAPI "Proxies validated requests" "HTTP/8080"
        restAPI -> postgresDB "Model metadata CRUD" "PostgreSQL/5432"
        restAPI -> externalPostgres "Alternative: external DB" "PostgreSQL/5432 Configurable TLS"

        // Catalog data flows
        openshiftRouter -> catalogProxy "Forwards with TLS reencrypt" "HTTPS/8443"
        catalogProxy -> kubernetesAPI "TokenReview + SubjectAccessReview" "HTTPS/443"
        catalogProxy -> catalogAPI "Proxies validated requests" "HTTP/8080"
        catalogAPI -> catalogDB "Catalog data CRUD" "PostgreSQL/5432"

        // Webhook interactions
        kubernetesAPI -> webhookServer "Admission reviews" "HTTPS/9443"
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

        container modelRegistryInstance "RegistryContainers" {
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
            element "Person" {
                background #08427b
                color #ffffff
                shape person
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

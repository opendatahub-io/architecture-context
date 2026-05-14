workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML model registries, deploys models"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and model registry instances"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator managing Model Registry and Model Catalog instance lifecycle on RHOAI" {
            controller = container "ModelRegistryReconciler" "Reconciles ModelRegistry CRs to deploy registry instances with database, auth proxy, routing, and RBAC" "Go (controller-runtime)"
            catalogController = container "ModelCatalogReconciler" "Manages centralized Model Catalog deployment with init containers and admin RBAC" "Go (controller-runtime)"
            webhook = container "Admission Webhooks" "Validates, mutates, and converts ModelRegistry CRs (v1alpha1 ↔ v1beta1)" "Go (controller-runtime)"
            migrationManager = container "Storage Version Migration" "Manages CRD storage version migration from v1alpha1 to v1beta1" "Go"
        }

        registryInstance = softwareSystem "Model Registry Instance" "REST API service for storing and retrieving ML model metadata" {
            registryREST = container "Model Registry REST" "REST API for model metadata CRUD operations" "Go Service, 8080/TCP"
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication enforcement sidecar using SubjectAccessReview" "Go Sidecar, 8443/TCP HTTPS"
            postgresDB = container "PostgreSQL" "Backing store for model registry metadata" "PostgreSQL 16, 5432/TCP"
        }

        catalogInstance = softwareSystem "Model Catalog" "Centralized catalog of available ML models with metadata" {
            catalogService = container "Catalog Service" "REST API for model catalog data" "Go Service, 8080/TCP"
            catalogProxy = container "kube-rbac-proxy (Catalog)" "Authentication enforcement sidecar for catalog" "Go Sidecar, 8443/TCP HTTPS"
            catalogDB = container "PostgreSQL (Catalog)" "Backing store for catalog data" "PostgreSQL 16, 5432/TCP"
        }

        # External systems
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for reconciliation, RBAC, and admission control" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhook server" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller providing external Route access" "External"
        servingCertSigner = softwareSystem "OpenShift Serving Cert Signer" "Automatic TLS certificate provisioning for Services" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "External"

        # Internal ODH/RHOAI systems
        platformOperator = softwareSystem "RHOAI Platform Operator" "Deploys and manages RHOAI components via kustomize" "Internal RHOAI"
        platformModelRegistry = softwareSystem "Platform ModelRegistry CR" "components.platform.opendatahub.io ModelRegistry for catalog owner ref" "Internal RHOAI"
        platformAuth = softwareSystem "Platform Auth CR" "services.platform.opendatahub.io Auth for admin group resolution" "Internal RHOAI"

        # Optional external databases
        externalPostgres = softwareSystem "External PostgreSQL" "User-provided PostgreSQL for production workloads" "External"
        externalMySQL = softwareSystem "External MySQL" "Alternative user-provided database backend" "External"

        # Relationships
        platformAdmin -> modelRegistryOperator "Creates ModelRegistry CRs via kubectl" "HTTPS/443"
        dataScientist -> registryInstance "Stores and retrieves model metadata" "HTTPS/443 via Route"
        dataScientist -> catalogInstance "Browses available models" "HTTPS/443 via Route"

        platformOperator -> modelRegistryOperator "Deploys operator via kustomize overlay" "K8s API"

        modelRegistryOperator -> k8sAPI "Reconciles resources (Deployments, Services, Routes, RBAC)" "HTTPS/443, SA Token"
        modelRegistryOperator -> registryInstance "Creates and manages registry instances"
        modelRegistryOperator -> catalogInstance "Creates and manages catalog instance"

        controller -> platformModelRegistry "Reads default-modelregistry CR for catalog owner ref" "K8s API Watch"
        catalogController -> platformAuth "Reads admin groups for catalog RBAC" "K8s API Watch"

        registryInstance -> k8sAPI "SubjectAccessReview for auth" "HTTPS/443"
        catalogInstance -> k8sAPI "SubjectAccessReview for auth" "HTTPS/443"

        openshiftRouter -> registryInstance "Routes traffic to registry" "HTTPS/8443 reencrypt"
        openshiftRouter -> catalogInstance "Routes traffic to catalog" "HTTPS/8443 reencrypt"

        registryInstance -> postgresDB "Stores metadata" "TCP/5432"
        registryInstance -> externalPostgres "Optional external storage" "TCP/5432, SSL configurable"
        registryInstance -> externalMySQL "Optional alternative storage" "TCP/3306, SSL configurable"
        catalogInstance -> catalogDB "Stores catalog data" "TCP/5432"

        webhook -> certManager "TLS certificates for webhook" "K8s API"
        registryInstance -> servingCertSigner "TLS certificates for kube-rbac-proxy" "Annotation-driven"
        catalogInstance -> servingCertSigner "TLS certificates for kube-rbac-proxy" "Annotation-driven"

        prometheus -> modelRegistryOperator "Scrapes operator metrics" "HTTPS/8443"
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

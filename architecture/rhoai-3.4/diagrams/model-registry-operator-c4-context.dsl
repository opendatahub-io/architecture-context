workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML model registries and catalogs"
        platformAdmin = person "Platform Admin" "Deploys and configures the RHOAI platform"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator managing ModelRegistry instances and the Model Catalog service" {
            controller = container "ModelRegistry Controller" "Reconciles ModelRegistry CRs; provisions REST API, PostgreSQL, auth proxy, routes, RBAC per instance" "Go Reconciler (controller-runtime v0.23.3)"
            catalogController = container "ModelCatalog Controller" "Manages centralized model catalog with PostgreSQL, kube-rbac-proxy, admin RBAC, multi-source config" "Go Reconciler"
            webhookServer = container "Webhook Server" "Mutating/validating admission webhooks and CRD conversion webhook (v1alpha1↔v1beta1)" "Go HTTPS Server (9443/TCP)"
            migrationManager = container "Storage Migration Manager" "Migrates CRD storage from v1alpha1 to v1beta1 via SVM API or manual re-read/re-write" "Background Task"
        }

        # Per-Instance Resources
        registryInstance = softwareSystem "Model Registry Instance" "Per-CR stack: REST API deployment + kube-rbac-proxy sidecar + PostgreSQL + Routes + RBAC" {
            restAPI = container "Registry REST API" "Model metadata REST API" "Go Service (8080/TCP HTTP)"
            kubeRBACProxy = container "kube-rbac-proxy" "Authentication/authorization sidecar (TokenReview + SAR)" "Sidecar (8443/TCP HTTPS)"
            postgresDB = container "PostgreSQL" "Metadata storage (auto-provisioned or user-provided)" "PostgreSQL 16 (5432/TCP)"
        }

        # Model Catalog
        modelCatalog = softwareSystem "Model Catalog" "Centralized catalog aggregating model metadata from multiple sources" {
            catalogAPI = container "Catalog REST API" "Catalog metadata REST API" "Go Service (8080/TCP HTTP)"
            catalogProxy = container "Catalog kube-rbac-proxy" "Auth sidecar for catalog" "Sidecar (8443/TCP HTTPS)"
            catalogDB = container "Catalog PostgreSQL" "Catalog metadata storage" "PostgreSQL 16 (5432/TCP)"
        }

        # External Dependencies
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for external access via Routes" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning (self-signed)" "External"
        servingCertSigner = softwareSystem "OpenShift serving-cert-signer" "Annotation-driven TLS certificate provisioning" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "External"

        # Platform Dependencies
        authCR = softwareSystem "ODH Auth CR" "Platform authentication configuration with admin groups" "Internal RHOAI"
        platformModelRegistry = softwareSystem "Platform ModelRegistry CR" "Platform-level ModelRegistry component CR for ownership" "Internal RHOAI"
        openshiftIngress = softwareSystem "OpenShift Ingress Config" "Cluster ingress domain configuration" "External"
        storageVersionMigration = softwareSystem "StorageVersionMigration API" "Kubernetes-native CRD storage version migration" "External"

        # External Services
        externalPostgres = softwareSystem "External PostgreSQL" "User-provided PostgreSQL database" "External"

        # Relationships
        dataScientist -> registryInstance "Creates ModelRegistry CRs and queries REST API" "kubectl / HTTPS"
        platformAdmin -> modelRegistryOperator "Deploys operator and configures platform" "kubectl"

        modelRegistryOperator -> kubernetesAPI "Manages resources (CRUD, Watch, Discovery)" "HTTPS/443"
        controller -> registryInstance "Provisions per-instance resource stack"
        catalogController -> modelCatalog "Provisions catalog subsystem"
        webhookServer -> kubernetesAPI "Receives admission/conversion requests" "HTTPS/9443"
        migrationManager -> storageVersionMigration "Creates SVM CRs for migration" "HTTPS/443"
        migrationManager -> kubernetesAPI "Manual re-read/re-write fallback" "HTTPS/443"

        controller -> openshiftRouter "Creates Routes for registry access"
        controller -> openshiftIngress "Discovers cluster ingress domain" "HTTPS/443"
        catalogController -> authCR "Reads admin groups for RBAC" "HTTPS/443"
        catalogController -> platformModelRegistry "Reads default-modelregistry for owner ref" "HTTPS/443"

        kubeRBACProxy -> kubernetesAPI "TokenReview + SubjectAccessReview" "HTTPS/443"
        restAPI -> postgresDB "Queries metadata" "PostgreSQL/5432"
        restAPI -> externalPostgres "Queries metadata (user-provided DB)" "PostgreSQL/5432"
        catalogAPI -> catalogDB "Queries catalog metadata" "PostgreSQL/5432"
        catalogProxy -> kubernetesAPI "TokenReview + SubjectAccessReview" "HTTPS/443"

        openshiftRouter -> kubeRBACProxy "Routes external traffic" "HTTPS/8443 Reencrypt"
        openshiftRouter -> catalogProxy "Routes catalog traffic" "HTTPS/8443 Reencrypt"
        prometheus -> modelRegistryOperator "Scrapes operator metrics" "HTTPS/8443"
        certManager -> modelRegistryOperator "Provisions webhook TLS cert"
        servingCertSigner -> modelRegistryOperator "Provisions serving TLS certs"
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

        container registryInstance "RegistryInstanceContainers" {
            include *
            autoLayout
        }

        container modelCatalog "ModelCatalogContainers" {
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

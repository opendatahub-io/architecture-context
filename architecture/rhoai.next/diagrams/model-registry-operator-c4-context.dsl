workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates model registries and manages ML model metadata"
        platformAdmin = person "Platform Admin" "Deploys and configures the Model Registry Operator via RHOAI platform"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator that manages Model Registry and Model Catalog instances on Red Hat OpenShift AI" {
            controller = container "ModelRegistryReconciler" "Reconciles ModelRegistry CRs to deploy registry instances with database, auth, and networking" "Go (controller-runtime)"
            catalogController = container "ModelCatalogReconciler" "Manages centralized model catalog with metadata from ConfigMaps and init containers" "Go (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates and mutates ModelRegistry CRs; handles v1alpha1→v1beta1 migration" "Go (9443/TCP HTTPS)"
            migrationManager = container "Storage Version Migration" "Manages CRD storage version migration from v1alpha1 to v1beta1" "Go"
        }

        registryInstance = softwareSystem "Model Registry Instance" "Deployed data plane: REST API with kube-rbac-proxy auth and PostgreSQL/MySQL backing store" {
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication sidecar enforcing SubjectAccessReview-based authorization" "Go (8443/TCP HTTPS)"
            restAPI = container "Model Registry REST API" "Serves model metadata CRUD operations" "Go/Python (8080/TCP HTTP)"
            database = container "PostgreSQL / MySQL" "Backing store for model registry metadata" "PostgreSQL 16 / MySQL (5432/TCP or 3306/TCP)"
        }

        catalogInstance = softwareSystem "Model Catalog" "Centralized catalog of ML models with curated metadata" {
            catalogProxy = container "kube-rbac-proxy (Catalog)" "Authentication sidecar for catalog access" "Go (8443/TCP HTTPS)"
            catalogAPI = container "Model Catalog REST API" "Serves catalog model metadata" "Go/Python (8080/TCP HTTP)"
            catalogDB = container "Catalog PostgreSQL" "Backing store for catalog data" "PostgreSQL 16 (5432/TCP)"
        }

        # External systems
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management and RBAC" "External"
        certManager = softwareSystem "cert-manager" "X.509 certificate management for webhook TLS" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller providing Route-based external access" "External"
        servingCertSigner = softwareSystem "OpenShift serving-cert-signer" "Provisions TLS certificates for kube-rbac-proxy via service annotations" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Internal ODH/RHOAI systems
        platformOperator = softwareSystem "RHOAI Platform Operator" "Deploys and manages the Model Registry Operator via kustomize overlays" "Internal RHOAI"
        platformCRDs = softwareSystem "Platform CRDs" "ModelRegistry Component CR and Auth CR for cross-component integration" "Internal RHOAI"

        # Relationships
        user -> openshiftRouter "Accesses model registries and catalog via HTTPS/443"
        platformAdmin -> k8sAPI "Creates ModelRegistry CRs via kubectl"
        platformOperator -> modelRegistryOperator "Deploys operator via kustomize overlays"

        modelRegistryOperator -> k8sAPI "Reconciles resources, watches CRDs" "HTTPS/443 SA Token"
        modelRegistryOperator -> registryInstance "Creates and manages" "K8s API"
        modelRegistryOperator -> catalogInstance "Creates and manages" "K8s API"

        controller -> webhookServer "Validated by"
        controller -> migrationManager "Triggers storage migration"
        catalogController -> platformCRDs "Watches ModelRegistry Component CR and Auth CR" "K8s API"

        openshiftRouter -> kubeRbacProxy "Routes traffic" "HTTPS/8443 TLS reencrypt"
        kubeRbacProxy -> k8sAPI "SubjectAccessReview" "HTTPS/443"
        kubeRbacProxy -> restAPI "Forwards authorized requests" "HTTP/8080 localhost"
        restAPI -> database "Reads/writes metadata" "TCP/5432 or 3306"

        openshiftRouter -> catalogProxy "Routes catalog traffic" "HTTPS/8443 TLS reencrypt"
        catalogProxy -> k8sAPI "SubjectAccessReview" "HTTPS/443"
        catalogProxy -> catalogAPI "Forwards authorized requests" "HTTP/8080 localhost"
        catalogAPI -> catalogDB "Reads/writes catalog data" "TCP/5432"

        certManager -> modelRegistryOperator "Provisions webhook TLS cert"
        servingCertSigner -> registryInstance "Provisions kube-rbac-proxy TLS certs"
        servingCertSigner -> catalogInstance "Provisions catalog kube-rbac-proxy TLS cert"
        prometheus -> modelRegistryOperator "Scrapes metrics" "HTTPS/8443 Bearer Token"
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

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML model registries and model metadata"
        platformAdmin = person "Platform Admin" "Configures RHOAI platform and manages operator deployment"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Manages lifecycle of Model Registry and Model Catalog instances on Kubernetes/OpenShift" {
            mrReconciler = container "ModelRegistryReconciler" "Reconciles per-instance model registry deployments (Deployment, Service, Route, HTTPRoute, RBAC, NetworkPolicy)" "Go controller-runtime"
            mcReconciler = container "ModelCatalogReconciler" "Manages singleton model catalog with PostgreSQL backend, catalog data ConfigMaps, admin RBAC" "Go controller-runtime"
            spWatcher = container "SecurityProfileWatcher" "Watches OpenShift TLS security profile and triggers restart on change" "Go controller-runtime"
            svmManager = container "StorageMigrationManager" "Automated v1alpha1→v1beta1 CRD storage version migration" "Go background process"
            webhooks = container "Admission Webhooks" "Mutating (defaults), validating (constraints), conversion (v1alpha1↔v1beta1)" "Go webhook server, port 9443"
        }

        modelRegistryService = softwareSystem "Model Registry REST Service" "REST API for ML model metadata CRUD operations" {
            restContainer = container "REST Container" "Model registry REST API serving model metadata" "Go/Python, port 8080"
            kubeRBACProxy = container "kube-rbac-proxy" "Authentication/authorization sidecar using SubjectAccessReview" "Go, port 8443"
        }

        modelCatalog = softwareSystem "Model Catalog" "Shared catalog of curated ML models with admin-controlled access" {
            catalogREST = container "Catalog REST Container" "Model catalog REST API" "Go/Python, port 8080"
            catalogProxy = container "Catalog kube-rbac-proxy" "Authentication sidecar for catalog" "Go, port 8443"
            catalogPostgres = container "Catalog PostgreSQL" "Catalog metadata storage" "PostgreSQL 16, port 5432"
        }

        # External systems
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource CRUD and webhook registration" "External"
        dataScienceGateway = softwareSystem "Data Science Gateway" "Shared Envoy-based gateway for RHOAI external traffic routing" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "HAProxy-based ingress for OpenShift Route objects" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for model registry metadata (user-provided or auto-provisioned)" "External"
        mysql = softwareSystem "MySQL" "Alternative relational database for model registry metadata (user-provided)" "External"
        serviceCA = softwareSystem "OpenShift service-ca Operator" "Auto-provisions TLS certificates for cluster services" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator that manages RHOAI component lifecycle" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management for webhook TLS" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Relationships - Users
        dataScientist -> modelRegistryService "Creates/queries model metadata via REST API" "HTTPS/443"
        dataScientist -> modelCatalog "Browses curated model catalog" "HTTPS/443"
        platformAdmin -> modelRegistryOperator "Creates ModelRegistry CRs via kubectl" "HTTPS/6443"

        # Relationships - Operator internals
        mrReconciler -> k8sAPI "CRUD Deployments, Services, Routes, HTTPRoutes, RBAC, NetworkPolicies" "HTTPS/6443"
        mcReconciler -> k8sAPI "CRUD catalog Deployments, PostgreSQL, ConfigMaps, admin RBAC" "HTTPS/6443"
        svmManager -> k8sAPI "Creates StorageVersionMigration resources" "HTTPS/6443"
        spWatcher -> k8sAPI "Watches config.openshift.io/APIServer TLS profile" "HTTPS/6443"

        # Relationships - Operator to deployed services
        mrReconciler -> modelRegistryService "Deploys and configures per-instance" "Kubernetes API"
        mcReconciler -> modelCatalog "Deploys singleton instance" "Kubernetes API"

        # Relationships - Traffic flow
        dataScienceGateway -> modelRegistryService "Routes external traffic via HTTPRoute" "HTTPS/8443"
        dataScienceGateway -> modelCatalog "Routes catalog traffic via HTTPRoute" "HTTPS/8443"
        openshiftRouter -> modelRegistryService "Routes via OpenShift Route (reencrypt)" "HTTPS/8443"
        openshiftRouter -> modelCatalog "Routes catalog via Route (reencrypt)" "HTTPS/8443"

        # Relationships - Data
        modelRegistryService -> postgresql "Stores model metadata" "PostgreSQL/5432"
        modelRegistryService -> mysql "Alternative metadata storage" "MySQL/3306"
        modelCatalog -> catalogPostgres "Stores catalog metadata" "PostgreSQL/5432"

        # Relationships - Platform
        serviceCA -> modelRegistryService "Provisions TLS certificates for kube-rbac-proxy" "Annotation-based"
        rhoaiOperator -> modelRegistryOperator "Manages operator lifecycle, provides Auth CR" "Kubernetes API"
        certManager -> modelRegistryOperator "Provisions webhook TLS certificates" "Certificate CR"
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

        container modelRegistryService "ServiceContainers" {
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
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}

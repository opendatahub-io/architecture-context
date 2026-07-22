workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages model registries to store ML model metadata"
        platformadmin = person "Platform Admin" "Deploys and configures the Model Registry Operator via RHOAI"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Manages the lifecycle of Model Registry and Model Catalog instances on OpenShift AI" {
            mrReconciler = container "ModelRegistryReconciler" "Reconciles ModelRegistry CRs: creates Deployments, Services, Routes, HTTPRoutes, NetworkPolicies, RBAC, kube-rbac-proxy sidecars" "Go Controller (controller-runtime)"
            mcReconciler = container "ModelCatalogReconciler" "Manages centralized model catalog service with PostgreSQL, kube-rbac-proxy, and Gateway API" "Go Controller (controller-runtime)"
            migrationMgr = container "StorageMigrationManager" "Handles CRD storage version migration from v1alpha1 to v1beta1" "Go Controller"
            webhooks = container "Admission Webhooks" "Defaulting (image cleanup, proxy migration) and Validation (name uniqueness, namespace constraint, DB config)" "Go Webhook Server"
            templateEngine = container "Template Engine" "30+ Go templates for declarative resource generation" "Go Templates"
        }

        modelRegistryInstance = softwareSystem "Model Registry Instance" "Deployed registry with REST API, kube-rbac-proxy auth, and database backend" {
            restService = container "REST API Service" "Serves model metadata CRUD operations" "Model Registry REST Container" "8080/TCP"
            kubeRBACProxy = container "kube-rbac-proxy" "Authentication and authorization sidecar using TokenReview and SubjectAccessReview" "Sidecar Container" "8443/TCP"
            postgresql = container "PostgreSQL" "Model registry metadata storage backend (auto-provisioned)" "PostgreSQL 16" "5432/TCP"
        }

        modelCatalogInstance = softwareSystem "Model Catalog Instance" "Centralized catalog for discovering and browsing model metadata" {
            catalogService = container "Catalog REST API" "Serves catalog metadata with init containers for data loading" "Catalog Container" "8080/TCP"
            catalogProxy = container "kube-rbac-proxy (catalog)" "Authentication sidecar for catalog" "Sidecar Container" "8443/TCP"
            catalogPostgres = container "Catalog PostgreSQL" "Catalog metadata storage (auto-provisioned, Recreate strategy)" "PostgreSQL 16" "5432/TCP"
        }

        # External Systems
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource CRUD and RBAC checks" "External"
        openshiftAPI = softwareSystem "OpenShift API Server" "OpenShift-specific APIs: Routes, Groups, Ingress, Config" "External"
        openshiftServiceCA = softwareSystem "OpenShift service-ca Operator" "Auto-generates TLS serving certificates via annotations" "External"
        dataScienceGateway = softwareSystem "Data Science Gateway" "Envoy-based gateway for platform ingress (Gateway API)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "External"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate provisioning for webhooks" "External"

        # Internal Platform Systems
        rhodsOperator = softwareSystem "RHOAI Operator" "Platform operator that manages component CRs" "Internal RHOAI"
        platformAuth = softwareSystem "Platform Auth Service" "Provides admin group configuration for catalog RBAC" "Internal RHOAI"
        svmAPI = softwareSystem "StorageVersionMigration API" "Kubernetes API for automated CRD storage version migration" "External"

        # Relationships - Users
        datascientist -> modelRegistryInstance "Creates/queries model metadata via REST API" "HTTPS/443 Bearer Token"
        platformadmin -> modelRegistryOperator "Deploys ModelRegistry CRs via kubectl/RHOAI Dashboard"

        # Relationships - Operator to K8s
        modelRegistryOperator -> kubernetesAPI "CRUD Deployments, Services, ConfigMaps, Secrets, PVCs, NetworkPolicies, RBAC" "HTTPS/6443 SA Token"
        modelRegistryOperator -> openshiftAPI "Create Routes, Groups; read Ingress domain, TLS profile" "HTTPS/6443 SA Token"
        modelRegistryOperator -> openshiftServiceCA "Annotation-based TLS cert generation"
        modelRegistryOperator -> dataScienceGateway "Creates HTTPRoutes and ReferenceGrants" "HTTPS/6443 SA Token"
        modelRegistryOperator -> svmAPI "Automated CRD migration v1alpha1 to v1beta1" "HTTPS/6443 SA Token"

        # Relationships - Platform Integration
        rhodsOperator -> modelRegistryOperator "Reads component CR for default registry config" "CRD Watch"
        platformAuth -> modelRegistryOperator "Provides admin groups for catalog RBAC" "CRD Watch"

        # Relationships - Operator creates instances
        modelRegistryOperator -> modelRegistryInstance "Creates and manages per-registry deployments"
        modelRegistryOperator -> modelCatalogInstance "Creates and manages catalog singleton"

        # Relationships - Instance internals
        kubeRBACProxy -> kubernetesAPI "TokenReview + SubjectAccessReview" "HTTPS/6443"
        kubeRBACProxy -> restService "Proxies authorized requests" "HTTP/8080 loopback"
        restService -> postgresql "Stores/retrieves model metadata" "TCP/5432 Optional SSL"
        catalogProxy -> kubernetesAPI "TokenReview + SubjectAccessReview" "HTTPS/6443"
        catalogProxy -> catalogService "Proxies authorized requests" "HTTP/8080 loopback"
        catalogService -> catalogPostgres "Stores/retrieves catalog metadata" "TCP/5432"

        # Relationships - Monitoring
        prometheus -> modelRegistryOperator "Scrapes operator metrics" "HTTPS/8443 Bearer Token"

        # Optional
        certManager -> modelRegistryOperator "Optional webhook TLS cert provisioning"
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

        container modelCatalogInstance "CatalogContainers" {
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

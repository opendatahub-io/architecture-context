workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages model registries and catalog entries"
        platformAdmin = person "Platform Operator" "Deploys and configures the RHOAI platform"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Manages lifecycle of Model Registry and Model Catalog instances on OpenShift/Kubernetes" {
            mrReconciler = container "ModelRegistryReconciler" "Reconciles ModelRegistry CRs — creates Deployments, Services, Routes, HTTPRoutes, RBAC, NetworkPolicies, kube-rbac-proxy sidecars" "Go Controller (controller-runtime)"
            mcReconciler = container "ModelCatalogReconciler" "Manages singleton model catalog instance with its own deployment, database, RBAC, and catalog sources" "Go Controller (controller-runtime)"
            webhook = container "Admission Webhook" "Defaults and validates ModelRegistry CRs, enforces namespace constraints and database config requirements" "Mutating + Validating Webhook"
            migrationManager = container "StorageMigrationManager" "Handles CRD storage version migration from v1alpha1 to v1beta1" "Background Process"
        }

        modelRegistryApp = softwareSystem "Model Registry Instance" "REST API server for model metadata, deployed per ModelRegistry CR" {
            restServer = container "model-registry REST" "Model metadata REST API" "Go Service, port 8080"
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication and authorization sidecar via SubjectAccessReview" "Go Proxy, port 8443"
        }

        # External systems
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        openshiftAPI = softwareSystem "OpenShift API Server" "OpenShift-specific APIs (Routes, Groups, Config)" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for external HTTPS access via Routes" "External"
        dsgGateway = softwareSystem "Data Science Gateway" "Envoy-based gateway for path-based routing via Gateway API" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Relational database for model registry/catalog metadata" "External"
        mysql = softwareSystem "MySQL" "Alternative relational database backend" "External"

        # Platform dependencies
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys model-registry-operator" "Internal RHOAI"
        authCR = softwareSystem "Auth CR (services.platform.opendatahub.io)" "Platform authentication configuration with admin groups" "Internal RHOAI"
        platformMR = softwareSystem "Platform ModelRegistry CR (components.platform.opendatahub.io)" "Platform-level model registry component definition" "Internal RHOAI"
        certManager = softwareSystem "OpenShift Serving Cert Controller" "Manages TLS certificates for services" "External"

        # Relationships - User interactions
        user -> modelRegistryApp "Queries model metadata via REST API" "HTTPS/443"
        platformAdmin -> modelRegistryOperator "Creates ModelRegistry CRs" "kubectl/HTTPS"

        # Operator → Kubernetes
        modelRegistryOperator -> k8sAPI "Creates/manages Deployments, Services, RBAC, NetworkPolicies, HTTPRoutes" "HTTPS/6443"
        modelRegistryOperator -> openshiftAPI "Creates/manages Routes, Groups, reads Ingress/APIServer config" "HTTPS/6443"

        # Operator → Platform
        modelRegistryOperator -> authCR "Reads admin groups for catalog RBAC" "HTTPS/6443"
        modelRegistryOperator -> platformMR "Reads default-modelregistry for owner references" "HTTPS/6443"

        # App → Infrastructure
        kubeRbacProxy -> k8sAPI "SubjectAccessReview for authorization" "HTTPS/6443"
        restServer -> postgresql "Stores/retrieves model metadata" "PostgreSQL/5432"
        restServer -> mysql "Alternative metadata storage" "MySQL/3306"

        # Ingress paths
        openshiftRouter -> kubeRbacProxy "Forwards requests (TLS reencrypt)" "HTTPS/8443"
        dsgGateway -> kubeRbacProxy "Forwards requests (HTTPRoute)" "HTTPS/8443"
        kubeRbacProxy -> restServer "Authorized requests" "HTTP/8080"

        # Platform relationships
        rhodsOperator -> modelRegistryOperator "Deploys operator, sets env vars (images, domains)" "Deployment"
        certManager -> modelRegistryApp "Provisions TLS serving certificates" "Secret injection"

        # Internal container relationships
        mrReconciler -> webhook "Validates CRs before reconciliation"
        migrationManager -> mrReconciler "Triggers re-reconciliation after migration"
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

        container modelRegistryApp "AppContainers" {
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

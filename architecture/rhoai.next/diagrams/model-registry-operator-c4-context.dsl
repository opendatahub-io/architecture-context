workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML model registries, registers models and artifacts"
        platformAdmin = person "Platform Admin" "Deploys and configures Model Registry instances via CRs"
        securityTeam = person "Security Team" "Reviews RBAC, network policies, and TLS configuration"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator managing ModelRegistry CR lifecycle, deploying REST API pods with kube-rbac-proxy, database backends, and dual-mode ingress" {
            mrReconciler = container "ModelRegistryReconciler" "Reconciles ModelRegistry CRs, creates Deployments, Services, RBAC, Routes, HTTPRoutes" "Go Controller"
            mcReconciler = container "ModelCatalogReconciler" "Manages singleton model-catalog service with PostgreSQL, RBAC, admin groups" "Go Controller"
            migrationManager = container "StorageMigrationManager" "Monitors CRD storage versions, migrates v1alpha1 to v1beta1" "Go Background Process"
            webhooks = container "Admission Webhooks" "Mutating (defaulting), validating (uniqueness, spec validation), conversion (v1alpha1 to v1beta1)" "Go Webhook Server"
        }

        modelRegistryAPI = softwareSystem "Model Registry REST API" "REST API server for model metadata, artifacts, and model versions" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar enforcing SubjectAccessReview" "Internal RHOAI"
        modelCatalog = softwareSystem "Model Catalog" "Singleton catalog service for browsable model discovery" "Internal RHOAI"

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CR watches, resource CRUD, leader election, discovery" "External"
        dataScienceGateway = softwareSystem "Data Science Gateway" "Platform-level Gateway API gateway (Envoy) for HTTPRoute-based ingress" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "OpenShift Route-based ingress with TLS reencrypt" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for model registry data (auto-provisioned or external)" "External"
        mysql = softwareSystem "MySQL" "Alternative relational database for model registry data (external only)" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks" "External"
        openshiftServiceCA = softwareSystem "OpenShift service-ca" "Automatic TLS serving certificate provisioning for services" "External"
        openshiftConfig = softwareSystem "OpenShift Config API" "Cluster ingress domain and TLS security profile configuration" "External"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys the model-registry-operator" "Internal RHOAI"
        authCR = softwareSystem "Auth CR" "Cluster-scoped Auth CR providing admin group configuration" "Internal RHOAI"

        # Relationships
        platformAdmin -> modelRegistryOperator "Creates ModelRegistry CRs via kubectl/oc"
        dataScientist -> modelRegistryAPI "Registers models, creates artifacts via REST API" "HTTPS/443"
        dataScientist -> modelCatalog "Browses model catalog" "HTTPS/443"

        modelRegistryOperator -> k8sAPI "Watches CRs, CRUD resources, leader election" "HTTPS/6443"
        modelRegistryOperator -> openshiftConfig "Fetches ingress domain and TLS profile" "HTTPS/6443"

        mrReconciler -> modelRegistryAPI "Deploys as container in managed Deployment" "Container Image"
        mrReconciler -> kubeRBACProxy "Injects as sidecar in managed Deployment" "Container Image"
        mrReconciler -> postgresql "Provisions auto-provisioned PostgreSQL or connects to external" "PostgreSQL/5432"
        mrReconciler -> mysql "Connects to external MySQL (alternative)" "MySQL/3306"
        mrReconciler -> dataScienceGateway "Creates HTTPRoutes referencing as parentRef" "Gateway API"
        mrReconciler -> openshiftRouter "Creates OpenShift Routes (reencrypt TLS)" "Route API"

        mcReconciler -> modelCatalog "Manages singleton catalog deployment" "Container Image"
        mcReconciler -> authCR "Reads admin groups for catalog RBAC" "Watch"

        rhodsOperator -> modelRegistryOperator "Deploys and manages operator lifecycle" "OLM"
        openshiftServiceCA -> kubeRBACProxy "Provisions TLS serving certificates" "Annotation"
        certManager -> webhooks "Provisions webhook TLS certificates" "Certificate CR"
    }

    views {
        systemContext modelRegistryOperator "SystemContext" {
            include *
            autoLayout
        }

        container modelRegistryOperator "Containers" {
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
                shape roundedBox
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

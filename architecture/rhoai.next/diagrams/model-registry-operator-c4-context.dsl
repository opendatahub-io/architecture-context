workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages model registry instances, registers ML models"
        platformAdmin = person "Platform Admin" "Deploys and configures Model Registry Operator via RHOAI"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Manages lifecycle of Model Registry and Model Catalog instances on OpenShift AI" {
            mrReconciler = container "ModelRegistryReconciler" "Reconciles per-instance ModelRegistry CRs, creating deployments, services, routes, RBAC" "Go Controller"
            mcReconciler = container "ModelCatalogReconciler" "Manages singleton model-catalog deployment with PostgreSQL, kube-rbac-proxy, ConfigMap sources" "Go Controller"
            webhooks = container "Admission Webhooks" "Mutating (defaults, auth migration), Validating (DB config, uniqueness), Conversion (v1alpha1↔v1beta1)" "Go Webhook Server"
            migrationMgr = container "StorageMigrationManager" "Handles CRD storage version migration v1alpha1 → v1beta1 via SVM API or manual strategy" "Go Component"
            tlsWatcher = container "TLS Profile Watcher" "Watches OpenShift APIServer TLS profile changes and triggers pod restarts" "Go Controller"
        }

        modelRegistryService = softwareSystem "Model Registry REST Service" "REST API for ML model metadata storage and retrieval" "Internal ODH"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Sidecar providing authentication via TokenReview and authorization via SubjectAccessReview" "Internal"
        postgreSQL = softwareSystem "PostgreSQL 16" "Relational database for model metadata storage" "Database"
        modelCatalog = softwareSystem "Model Catalog" "Aggregated catalog of model metadata from multiple sources" "Internal ODH"

        k8sAPI = softwareSystem "Kubernetes / OpenShift API" "Cluster control plane for resource management, RBAC, discovery" "Infrastructure"
        openShiftRouter = softwareSystem "OpenShift Router" "Ingress controller for OpenShift Routes" "Infrastructure"
        dataScienceGateway = softwareSystem "Data Science Gateway" "Gateway API (Envoy) for path-based routing to RHOAI services" "Internal ODH"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management for webhook TLS" "Infrastructure"

        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator that deploys and manages Model Registry Operator" "Internal ODH"
        authCR = softwareSystem "Auth CR" "Platform authentication configuration for admin group RBAC" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science projects and model registries" "Internal ODH"

        externalDB = softwareSystem "External Database" "User-provided PostgreSQL or MySQL database" "External"

        # Relationships
        platformAdmin -> modelRegistryOperator "Deploys via RHOAI Operator"
        dataScientist -> modelRegistryOperator "Creates ModelRegistry CRs via kubectl/Dashboard"
        dataScientist -> modelRegistryService "Registers and queries ML models" "HTTPS/8443 via Route or Gateway"

        modelRegistryOperator -> k8sAPI "CRUD resources, watches CRDs, TokenReview, SAR" "HTTPS/6443"
        modelRegistryOperator -> modelRegistryService "Deploys as container in managed Deployments" "Container Image"
        modelRegistryOperator -> kubeRBACProxy "Deploys as sidecar for auth enforcement" "Container Image"
        modelRegistryOperator -> postgreSQL "Auto-provisions per-instance databases" "Container Image + Deployment"
        modelRegistryOperator -> openShiftRouter "Creates Routes for external access" "Route API"
        modelRegistryOperator -> dataScienceGateway "Creates HTTPRoutes for path-based routing" "Gateway API"
        modelRegistryOperator -> certManager "Uses for webhook certificate management" "Certificate CRs"
        modelRegistryOperator -> authCR "Reads admin groups for catalog RBAC" "Watch API"

        rhoaiOperator -> modelRegistryOperator "Deploys and provides owner reference" "CRD"

        kubeRBACProxy -> k8sAPI "TokenReview + SubjectAccessReview" "HTTPS/6443"
        modelRegistryService -> postgreSQL "Stores model metadata" "PostgreSQL/5432"
        modelRegistryService -> externalDB "Connects to user-provided database" "PostgreSQL/5432 or MySQL/3306"

        dashboard -> modelRegistryOperator "Creates ModelRegistry CRs" "Kubernetes API"
        dashboard -> modelRegistryService "Queries model registry REST API" "HTTPS/8443"

        mrReconciler -> k8sAPI "Creates Deployments, Services, Routes, HTTPRoutes, RBAC, NetworkPolicies" "HTTPS/6443"
        mcReconciler -> k8sAPI "Creates catalog Deployment, Service, Routes, PostgreSQL" "HTTPS/6443"
        webhooks -> k8sAPI "Receives admission requests from API server" "HTTPS/9443"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Database" {
                background #f5a623
                color #ffffff
                shape Cylinder
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        }
    }
}

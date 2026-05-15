workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML model registries, registers models"
        platformAdmin = person "Platform Admin" "Deploys and configures Model Registry instances"
        catalogAdmin = person "Catalog Admin" "Manages model catalog content and sources"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Manages lifecycle of Model Registry and Model Catalog custom resources on Kubernetes/OpenShift" {
            operatorController = container "Operator Controller" "Reconciles ModelRegistry and ModelCatalog CRs; manages deployments, services, RBAC, networking" "Go (controller-runtime)"
            admissionWebhooks = container "Admission Webhooks" "Defaults and validates ModelRegistry CRs; handles v1alpha1↔v1beta1 conversion" "Go (controller-runtime webhook)"
            storageMigration = container "Storage Migration Manager" "Monitors CRD versions and migrates v1alpha1→v1beta1 via SVM or manual strategy" "Go"
        }

        modelRegistryService = softwareSystem "Model Registry REST Service" "REST API for ML model metadata management (deployed per ModelRegistry CR)" {
            restAPI = container "REST API Server" "Serves model registry REST endpoints" "Go"
            kubeRBACProxy = container "kube-rbac-proxy" "Authentication and authorization sidecar using TokenReview and SubjectAccessReview" "Go sidecar"
        }

        modelCatalogService = softwareSystem "Model Catalog Service" "Curated model metadata catalog with multiple data sources" {
            catalogAPI = container "Catalog API Server" "Serves catalog REST endpoints" "Go"
            catalogProxy = container "kube-rbac-proxy" "Authentication and authorization sidecar" "Go sidecar"
        }

        postgresql = softwareSystem "PostgreSQL" "Relational database for model metadata storage (auto-provisioned or external)" "Database"
        mysql = softwareSystem "MySQL/MariaDB" "Alternative relational database backend (external only)" "Database"

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane API" "Infrastructure"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller providing external Route access" "Infrastructure"
        openshiftPlatform = softwareSystem "OpenShift Platform APIs" "config.openshift.io, user.openshift.io, route.openshift.io" "Infrastructure"

        odhPlatform = softwareSystem "ODH/RHOAI Platform" "Platform-level components and auth configuration" "Internal Platform" {
            platformModelRegistry = container "Platform ModelRegistry Component" "components.platform.opendatahub.io ModelRegistry CR for capability detection" "Platform CRD"
            authCR = container "Auth CR" "services.platform.opendatahub.io Auth for admin groups configuration" "Platform CRD"
        }

        s3Storage = softwareSystem "S3 Storage" "Object storage for model artifacts (async upload jobs)" "External Service"
        ociRegistry = softwareSystem "OCI Registry" "Container image registry for ModelCar format (async upload jobs)" "External Service"

        # Relationships
        platformAdmin -> modelRegistryOperator "Creates ModelRegistry CRs via kubectl" "HTTPS/6443"
        dataScientist -> modelRegistryService "Registers and queries models" "HTTPS/443 via Route"
        dataScientist -> modelCatalogService "Browses curated model catalog" "HTTPS/443 via Route"
        catalogAdmin -> modelCatalogService "Manages catalog data sources" "HTTPS/443 via Route"

        modelRegistryOperator -> kubernetesAPI "Watches CRs, creates resources (Deployments, Services, RBAC, Routes)" "HTTPS/6443"
        modelRegistryOperator -> openshiftPlatform "Reads cluster config (ingress domain), manages Routes and Groups" "HTTPS/6443"
        modelRegistryOperator -> odhPlatform "Reads platform capabilities and admin group config" "Kubernetes API"

        kubeRBACProxy -> kubernetesAPI "TokenReview + SubjectAccessReview" "HTTPS/6443"
        catalogProxy -> kubernetesAPI "TokenReview + SubjectAccessReview" "HTTPS/6443"

        openshiftRouter -> modelRegistryService "Routes external traffic (TLS reencrypt)" "HTTPS/8443"
        openshiftRouter -> modelCatalogService "Routes external traffic (TLS reencrypt)" "HTTPS/8443"

        modelRegistryService -> postgresql "Stores model metadata" "TCP/5432"
        modelRegistryService -> mysql "Alternative metadata storage" "TCP/3306"
        modelCatalogService -> postgresql "Stores catalog data" "TCP/5432"

        modelRegistryOperator -> modelRegistryService "Deploys and configures per ModelRegistry CR" "Kubernetes resources"
        modelRegistryOperator -> modelCatalogService "Deploys and configures catalog infrastructure" "Kubernetes resources"
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

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Database" {
                background #999999
                color #ffffff
                shape Cylinder
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
        }
    }
}

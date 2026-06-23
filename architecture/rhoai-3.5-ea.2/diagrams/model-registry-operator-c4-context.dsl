workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Model Registry instances and catalogs ML models"
        platformAdmin = person "Platform Admin" "Deploys and configures the RHOAI platform"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Manages lifecycle of Model Registry and Model Catalog instances on OpenShift/Kubernetes" {
            mrReconciler = container "ModelRegistryReconciler" "Reconciles ModelRegistry CRs, deploys REST services, databases, auth proxies, and ingress resources" "Go Controller"
            mcReconciler = container "ModelCatalogReconciler" "Manages a single shared Model Catalog deployment with configurable sources and PostgreSQL" "Go Controller"
            migrationMgr = container "StorageMigrationManager" "Handles CRD storage version migration from v1alpha1 to v1beta1" "Go Component"
            webhookMgr = container "Webhook Manager" "Mutating and validating webhooks for ModelRegistry CR defaulting, validation, and version conversion" "Go Webhook Server"
        }

        modelRegistryService = softwareSystem "Model Registry REST Service" "REST API for ML model metadata management" "Deployed by Operator"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar performing SubjectAccessReview authorization" "Deployed by Operator"
        postgresql = softwareSystem "PostgreSQL" "Relational database backend for model metadata storage" "Deployed by Operator or User-Provided"

        dataScienceGateway = softwareSystem "Data Science Gateway" "Gateway API Envoy-based ingress for RHOAI platform" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "OpenShift Route-based ingress (HAProxy)" "OpenShift Platform"
        rhoaiOperator = softwareSystem "rhods-operator" "Platform operator that deploys component operators via Kustomize manifests" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource management and RBAC enforcement" "Kubernetes Platform"
        openshiftConfig = softwareSystem "OpenShift Config APIs" "Cluster ingress domain and TLS security profile configuration" "OpenShift Platform"
        openshiftUserAPI = softwareSystem "OpenShift User API" "User and Group management (traditional OpenShift only)" "OpenShift Platform"
        certController = softwareSystem "OpenShift Serving Cert Controller" "Auto-provisions TLS certificates for annotated Services" "OpenShift Platform"

        # Relationships - Users
        dataScientist -> modelRegistryService "Creates/queries model metadata via" "HTTPS/443"
        dataScientist -> modelRegistryOperator "Creates ModelRegistry CRs via" "kubectl/HTTPS"
        platformAdmin -> rhoaiOperator "Configures RHOAI platform via" "kubectl/HTTPS"

        # Relationships - Operator internals
        mrReconciler -> modelRegistryService "Deploys and manages" "Kubernetes API"
        mrReconciler -> kubeRbacProxy "Deploys as sidecar" "Kubernetes API"
        mrReconciler -> postgresql "Deploys (optional) or connects to" "Kubernetes API"
        mcReconciler -> modelRegistryService "Deploys catalog instance" "Kubernetes API"
        mcReconciler -> kubeRbacProxy "Deploys as sidecar" "Kubernetes API"
        mcReconciler -> postgresql "Deploys catalog database" "Kubernetes API"

        # Relationships - External
        rhoaiOperator -> modelRegistryOperator "Deploys via Kustomize manifests" "Kubernetes API"
        modelRegistryOperator -> kubernetesAPI "Watches CRDs, manages resources" "HTTPS/443"
        modelRegistryOperator -> openshiftConfig "Reads ingress domain and TLS profile" "HTTPS/443"
        modelRegistryOperator -> openshiftUserAPI "Manages Groups (traditional OCP)" "HTTPS/443"
        modelRegistryOperator -> dataScienceGateway "Creates HTTPRoutes referencing" "Gateway API"
        modelRegistryOperator -> openshiftRouter "Creates Routes for" "OpenShift Route API"
        certController -> kubeRbacProxy "Provisions TLS certificates for" "Annotation-driven"
        kubeRbacProxy -> kubernetesAPI "SubjectAccessReview authorization" "HTTPS/443"
        modelRegistryService -> postgresql "Reads/writes model metadata" "PostgreSQL/5432"
        dataScienceGateway -> kubeRbacProxy "Routes external traffic to" "HTTPS/8443"
        openshiftRouter -> kubeRbacProxy "Routes external traffic to" "HTTPS/8443"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Deployed by Operator" {
                background #7ed321
                color #ffffff
            }
            element "Internal RHOAI" {
                background #85bbf0
                color #ffffff
            }
            element "Kubernetes Platform" {
                background #999999
                color #ffffff
            }
            element "OpenShift Platform" {
                background #ee0000
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

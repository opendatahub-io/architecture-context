workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML model registries and accesses model catalog"
        platformAdmin = person "Platform Admin" "Deploys and configures the Model Registry Operator via RHOAI platform"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator that manages the lifecycle of Model Registry and Model Catalog instances on RHOAI" {
            mrReconciler = container "ModelRegistry Reconciler" "Watches ModelRegistry CRs and deploys registry instances with REST API, database, auth proxy, RBAC, and networking" "Go (controller-runtime)"
            mcReconciler = container "ModelCatalog Reconciler" "Deploys centralized model catalog with metadata from ConfigMaps and init containers" "Go (controller-runtime)"
            webhook = container "Admission Webhook" "Validates and mutates ModelRegistry CRs; handles v1alpha1→v1beta1 migration" "Go (9443/TCP HTTPS)"
            storageMigration = container "Storage Migration" "Manages CRD storage version migration from v1alpha1 to v1beta1" "Go"
        }

        registryInstance = softwareSystem "Model Registry Instance" "Deployed REST API service for ML model metadata storage" {
            restContainer = container "Model Registry REST" "REST API for model metadata operations" "Go (8080/TCP HTTP)"
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication enforcement sidecar using SubjectAccessReview" "Go (8443/TCP HTTPS)"
        }

        catalogInstance = softwareSystem "Model Catalog Instance" "Centralized catalog of available ML models with metadata" {
            catalogContainer = container "Model Catalog" "Catalog API with init containers for model metadata" "Go (8080/TCP HTTP)"
            catalogProxy = container "kube-rbac-proxy (Catalog)" "Authentication enforcement sidecar for catalog" "Go (8443/TCP HTTPS)"
        }

        postgresql = softwareSystem "PostgreSQL" "Backing store for model registry and catalog metadata" "Database"
        mysql = softwareSystem "MySQL" "Alternative backing store for model registry metadata" "Database"

        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller exposing Routes for external access" "Infrastructure"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhook server" "Infrastructure"
        servingCertSigner = softwareSystem "OpenShift serving-cert-signer" "TLS certificate provisioning for kube-rbac-proxy services" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "Monitoring"

        rhoaiPlatformOperator = softwareSystem "RHOAI Platform Operator" "Deploys Model Registry Operator via kustomize overlays" "Internal RHOAI"
        platformModelRegistryCR = softwareSystem "Platform ModelRegistry CR" "components.platform.opendatahub.io/ModelRegistry for catalog owner reference" "Internal RHOAI"
        platformAuthCR = softwareSystem "Platform Auth CR" "services.platform.opendatahub.io/Auth for admin group configuration" "Internal RHOAI"
        openshiftIngressConfig = softwareSystem "OpenShift Ingress Config" "config.openshift.io/Ingress for cluster domain discovery" "Infrastructure"

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management and auth delegation" "Infrastructure"

        # Relationships
        dataScientist -> openshiftRouter "Creates ModelRegistry CRs, queries model registry and catalog APIs" "HTTPS/443"
        platformAdmin -> rhoaiPlatformOperator "Configures RHOAI platform" "HTTPS"

        rhoaiPlatformOperator -> modelRegistryOperator "Deploys via kustomize overlay" "Kubernetes API"

        mrReconciler -> k8sAPI "Creates Deployments, Services, Routes, RBAC, NetworkPolicies" "HTTPS/443 SA Token"
        mcReconciler -> k8sAPI "Creates catalog Deployment, Service, Route, RBAC" "HTTPS/443 SA Token"
        mcReconciler -> platformModelRegistryCR "Watches for catalog owner reference" "K8s API Watch"
        mcReconciler -> platformAuthCR "Reads admin groups for catalog RBAC" "K8s API Watch"
        mrReconciler -> openshiftIngressConfig "Reads cluster domain for Route hostnames" "K8s API"
        webhook -> k8sAPI "Webhook admission, OAuth→kube-rbac-proxy migration" "HTTPS/9443"

        storageMigration -> k8sAPI "Creates StorageVersionMigration CRs" "HTTPS/443"

        openshiftRouter -> kubeRbacProxy "Forwards requests (TLS reencrypt)" "HTTPS/8443"
        openshiftRouter -> catalogProxy "Forwards catalog requests (TLS reencrypt)" "HTTPS/8443"

        kubeRbacProxy -> k8sAPI "SubjectAccessReview for auth" "HTTPS/443"
        kubeRbacProxy -> restContainer "Forwards authenticated requests" "HTTP/8080 localhost"
        catalogProxy -> k8sAPI "SubjectAccessReview for auth" "HTTPS/443"
        catalogProxy -> catalogContainer "Forwards authenticated requests" "HTTP/8080 localhost"

        restContainer -> postgresql "Stores/retrieves model metadata" "TCP/5432 Password"
        restContainer -> mysql "Alternative metadata storage" "TCP/3306 Password"
        catalogContainer -> postgresql "Stores/retrieves catalog data" "TCP/5432 Password"

        certManager -> modelRegistryOperator "Provisions webhook TLS certificates" "Self-signed"
        servingCertSigner -> registryInstance "Provisions kube-rbac-proxy TLS certificates" "Annotation-driven"
        servingCertSigner -> catalogInstance "Provisions catalog proxy TLS certificates" "Annotation-driven"

        prometheus -> modelRegistryOperator "Scrapes operator metrics" "HTTPS/8443 Bearer Token"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Database" {
                background #bd10e0
                color #ffffff
                shape Cylinder
            }
            element "Monitoring" {
                background #f5a623
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
        }
    }
}

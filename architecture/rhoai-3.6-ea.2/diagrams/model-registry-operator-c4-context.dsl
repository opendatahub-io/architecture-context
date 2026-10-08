workspace {
    model {
        dataScientist = person "Data Scientist" "Registers and retrieves ML model artifacts"
        platformAdmin = person "Platform Admin" "Manages model registry instances and catalog configuration"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator managing Model Registry, Catalog, and AIHub resources" {
            controllerManager = container "Controller Manager" "Runs ModelRegistry, Catalog, and AIHub controllers in a single manager process" "Go Operator" "Operator"
            webhookServer = container "Webhook Server" "Validates, mutates, and converts ModelRegistry CRs" "Go Service" "Operator"
            registryDeployment = container "{registry-name}" "REST API server for ML model artifact registration with kube-rbac-proxy sidecar" "Go Service + kube-rbac-proxy" "Created Resource"
            registryPostgres = container "{registry-name}-postgres" "PostgreSQL database storing model registry metadata" "PostgreSQL 16" "Created Resource"
            catalogDeployment = container "model-catalog" "Shared catalog API for browsing model metadata with kube-rbac-proxy sidecar" "Go Service + kube-rbac-proxy" "Created Resource"
            catalogPostgres = container "model-catalog-postgres" "PostgreSQL database storing model catalog data" "PostgreSQL 16" "Created Resource"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management and RBAC enforcement" "External"
        gatewayAPI = softwareSystem "Gateway API (data-science-gateway)" "Platform ingress via HTTPRoute resources" "Internal Platform"
        openshiftRoutes = softwareSystem "OpenShift Routes" "Legacy ingress via OpenShift Route resources" "Internal Platform"
        openshiftConfig = softwareSystem "OpenShift Config API" "Cluster configuration including TLS profiles and ingress domain" "External"
        openshiftUsers = softwareSystem "OpenShift User/Group API" "User and group management for per-registry access control" "External"
        odhOperator = softwareSystem "ODH/RHOAI Operator" "Parent operator that deploys model-registry-operator" "Internal Platform"
        platformAuth = softwareSystem "Platform Auth Service" "services.platform.opendatahub.io Auth CR for catalog RBAC configuration" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "Internal Platform"

        # User interactions
        dataScientist -> registryDeployment "Registers/retrieves models" "HTTPS/8443"
        dataScientist -> catalogDeployment "Browses model catalog" "HTTPS/8443"
        platformAdmin -> controllerManager "Creates ModelRegistry/Catalog/AIHub CRs" "kubectl"

        # Internal flows
        controllerManager -> webhookServer "Admission requests" "HTTPS/9443"
        controllerManager -> kubernetesAPI "Reconciles resources, RBAC, events" "HTTPS/6443"
        controllerManager -> openshiftConfig "Reads TLS profile, ingress domain" "HTTPS/6443"
        controllerManager -> openshiftUsers "Manages per-registry groups" "HTTPS/6443"
        controllerManager -> platformAuth "Reads Auth CR for catalog RBAC" "HTTPS/6443"

        registryDeployment -> registryPostgres "Stores model metadata" "PostgreSQL/5432"
        catalogDeployment -> catalogPostgres "Stores catalog data" "PostgreSQL/5432"
        registryDeployment -> kubernetesAPI "kube-rbac-proxy TokenReview/SAR" "HTTPS/6443"
        catalogDeployment -> kubernetesAPI "kube-rbac-proxy TokenReview/SAR" "HTTPS/6443"

        # External interactions
        gatewayAPI -> registryDeployment "Routes traffic via HTTPRoute" "HTTPS/8443"
        gatewayAPI -> catalogDeployment "Routes traffic via HTTPRoute" "HTTPS/8443"
        openshiftRoutes -> registryDeployment "Routes traffic via Route" "HTTPS/8443"
        odhOperator -> controllerManager "Deploys via kustomize overlay" "Kubernetes"
        prometheus -> controllerManager "Scrapes metrics" "HTTPS/8443"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Created Resource" {
                background #50c878
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

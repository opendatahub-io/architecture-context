workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages ML model metadata registries"

        modelRegistryOp = softwareSystem "Model Registry Operator" "Manages lifecycle of Model Registry instances for ML model metadata storage and retrieval" {
            controller = container "controller-manager" "Reconciles ModelRegistry CRs and manages registry lifecycle" "Go Operator" {
                tags "Operator"
            }
            webhook = container "webhook-service" "Validates and mutates ModelRegistry custom resources" "Go Webhook Server" {
                tags "Operator"
            }
            registry = container "model-registry deployment" "REST API service for ML metadata storage and retrieval" "Python/FastAPI" {
                tags "Instance"
                restContainer = component "rest-container" "ML Metadata REST API (v1alpha3)" "Python"
                oauthProxy = component "oauth-proxy" "OpenShift OAuth authentication proxy" "Go"
            }
        }

        # External Dependencies
        postgresql = softwareSystem "PostgreSQL Database" "Backend storage for ML Metadata" "External Database"
        mysql = softwareSystem "MySQL Database" "Alternative backend storage for ML Metadata" "External Database"
        oauthServer = softwareSystem "OpenShift OAuth Server" "Authentication provider for OAuth proxy mode" "External OpenShift"
        ingressRouter = softwareSystem "OpenShift Ingress Router" "External route exposure for model registry services" "External OpenShift"
        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane" "External Platform"

        # Internal ODH/RHOAI Dependencies
        platform = softwareSystem "opendatahub-operator / rhods-operator" "Platform-level component management" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "Internal ODH"
        certManager = softwareSystem "cert-manager" "Automatic certificate management" "Internal ODH"
        serviceCA = softwareSystem "OpenShift Service CA" "Automatic TLS certificate generation" "External OpenShift"

        # Integration Points
        dashboard = softwareSystem "ODH Dashboard" "UI for managing OpenDataHub components" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "ML workflow orchestration" "Internal ODH"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal ODH"

        # User interactions
        user -> modelRegistryOp "Creates ModelRegistry CRs via kubectl/OpenShift Console"
        user -> registry "Queries/updates model metadata via REST API" "HTTPS/8443 (OAuth) or HTTP/8080 (internal)"

        # Operator interactions
        modelRegistryOp -> k8sAPI "Manages Kubernetes resources (Deployments, Services, Routes, RBAC)" "HTTPS/6443"
        modelRegistryOp -> platform "Watches platform-level ModelRegistry components" "components.platform.opendatahub.io CRD"
        modelRegistryOp -> prometheus "Exposes operator metrics" "HTTPS/8443"
        modelRegistryOp -> certManager "Uses for webhook certificate management (optional)" "Certificate CRD"
        modelRegistryOp -> serviceCA "Uses for automatic TLS certificate generation" "Service CA injection"

        # Registry instance interactions
        registry -> postgresql "Stores ML Metadata" "PostgreSQL/5432"
        registry -> mysql "Stores ML Metadata (alternative)" "MySQL/3306"
        registry -> oauthServer "Validates OAuth tokens" "HTTPS/443"
        registry -> ingressRouter "Receives external traffic via Routes" "HTTPS/443"

        # Integration points
        dashboard -> modelRegistryOp "Future: UI management of model registries"
        pipelines -> registry "Tracks model metadata during pipeline execution" "REST API"
        kserve -> registry "Fetches model metadata for inference services" "REST API"
    }

    views {
        systemContext modelRegistryOp "SystemContext" {
            include *
            autoLayout
        }

        container modelRegistryOp "Containers" {
            include *
            autoLayout
        }

        component registry "Components" {
            include *
            autoLayout
        }

        styles {
            element "External Database" {
                background #999999
                color #ffffff
            }
            element "External OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "External Platform" {
                background #326ce5
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Instance" {
                background #f5a623
                color #000000
            }
        }

        theme default
    }
}

workspace {
    model {
        user = person "Data Scientist" "Creates and manages model registry instances for ML model metadata"
        admin = person "Platform Administrator" "Deploys and configures the model registry operator"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator that deploys and manages Model Registry instances for ML model metadata storage and retrieval in RHOAI" {
            controller = container "Controller Manager" "Reconciles ModelRegistry CRs and manages lifecycle" "Go Operator" {
                reconciler = component "ModelRegistry Reconciler" "Watches and reconciles ModelRegistry CRs"
                resourceManager = component "Resource Manager" "Creates/updates Deployments, Services, Routes, NetworkPolicies"
            }
            webhook = container "Webhook Service" "Validates and defaults ModelRegistry CRs" "Go Service" {
                validator = component "Validating Webhook" "CR validation"
                mutator = component "Mutating Webhook" "CR defaulting"
            }
        }

        modelRegistryInstance = softwareSystem "Model Registry Instance" "REST API service for model metadata operations" {
            restAPI = container "REST API Service" "HTTP API for model metadata CRUD" "Go Service"
            rbacProxy = container "kube-rbac-proxy" "RBAC-based authentication proxy" "Sidecar"
        }

        # External Dependencies
        k8s = softwareSystem "Kubernetes API Server" "Cluster API server for resource management" "External"
        postgres = softwareSystem "PostgreSQL Database" "Persistent metadata storage" "External"
        mysql = softwareSystem "MySQL Database" "Alternative metadata storage backend" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning" "External"

        # OpenShift specific
        openshiftRouter = softwareSystem "OpenShift Router" "External ingress for Routes" "External OpenShift"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Automatic TLS certificate provisioning" "External OpenShift"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "User authentication (legacy proxy mode)" "External OpenShift"

        # Optional components
        istio = softwareSystem "Istio/Service Mesh" "Advanced networking and authorization" "External Optional"
        modelCatalog = softwareSystem "Model Catalog" "Curated model metadata collections" "Internal Optional"

        # Internal ODH components
        platformComponents = softwareSystem "Platform Components CRD" "Platform component integration" "Internal ODH"
        platformServices = softwareSystem "Platform Services CRD" "Authentication configuration discovery" "Internal ODH"

        # Relationships - User interactions
        user -> modelRegistryOperator "Creates ModelRegistry CR via kubectl/oc"
        admin -> modelRegistryOperator "Deploys and configures operator"
        user -> modelRegistryInstance "Queries model metadata via REST API"

        # Relationships - Operator
        modelRegistryOperator -> k8s "Watches CRs, creates/updates resources (Deployments, Services, Routes, NetworkPolicies)"
        modelRegistryOperator -> postgres "Provisions auto-managed PostgreSQL instances"
        modelRegistryOperator -> certManager "Requests TLS certificates for webhooks"
        modelRegistryOperator -> openshiftServiceCA "Auto-provisions TLS certs via annotations"
        modelRegistryOperator -> platformComponents "Watches for platform integration"
        modelRegistryOperator -> platformServices "Discovers authentication configuration"

        # Relationships - Model Registry Instance
        modelRegistryInstance -> postgres "Stores/retrieves model metadata" "PostgreSQL/5432"
        modelRegistryInstance -> mysql "Stores/retrieves model metadata (alternative)" "MySQL/3306"
        modelRegistryInstance -> k8s "Validates bearer tokens via SubjectAccessReview" "HTTPS/6443"

        # Relationships - Ingress
        openshiftRouter -> modelRegistryInstance "Routes external HTTPS traffic" "HTTPS/443 → 8443"
        istio -> modelRegistryInstance "Service mesh ingress (optional)" "HTTPS/443"

        # Relationships - Authentication
        modelRegistryInstance -> openshiftOAuth "User authentication (legacy OAuth proxy)" "HTTPS/443"

        # Relationships - Optional
        modelRegistryOperator -> modelCatalog "Provisions catalog instances (optional)"
    }

    views {
        systemContext modelRegistryOperator "SystemContext" {
            include *
            autoLayout tb
        }

        container modelRegistryOperator "OperatorContainers" {
            include *
            autoLayout tb
        }

        container modelRegistryInstance "InstanceContainers" {
            include *
            autoLayout tb
        }

        component controller "ControllerComponents" {
            include *
            autoLayout tb
        }

        component webhook "WebhookComponents" {
            include *
            autoLayout tb
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External OpenShift" {
                background #cc0000
                color #ffffff
            }
            element "External Optional" {
                background #d3d3d3
                color #000000
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Internal Optional" {
                background #a8d5a8
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6db3f2
                color #ffffff
            }
            element "Component" {
                background #85c5f7
                color #000000
            }
            element "Person" {
                background #f5a623
                color #ffffff
                shape Person
            }
        }
    }
}

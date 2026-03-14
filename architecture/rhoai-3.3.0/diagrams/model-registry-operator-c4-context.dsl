workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Manages ML model metadata and retrieval"
        admin = person "Platform Administrator" "Deploys and configures model registry instances"

        modelRegistryOp = softwareSystem "Model Registry Operator" "Manages lifecycle of Model Registry instances for ML model metadata storage and retrieval in RHOAI" {
            controller = container "controller-manager" "Reconciles ModelRegistry CRs and manages instance lifecycle" "Go Operator" {
                reconciler = component "ModelRegistry Reconciler" "Watches and reconciles ModelRegistry CRs"
                resourceManager = component "Resource Manager" "Creates and updates Deployments, Services, Routes, RBAC"
                databaseProvisioner = component "Database Provisioner" "Auto-provisions PostgreSQL if configured"
            }

            webhook = container "Webhook Service" "Validates and mutates ModelRegistry CRs" "Go Service" {
                validator = component "CR Validator" "Validates v1alpha1/v1beta1 CRs"
                mutator = component "CR Mutator" "Applies defaults to CRs"
            }
        }

        modelRegistryInstance = softwareSystem "Model Registry Instance" "Stores and serves ML model metadata" {
            restAPI = container "model-registry REST API" "HTTP REST API for model metadata operations" "Java Service"
            proxy = container "kube-rbac-proxy" "RBAC-based authentication proxy" "Go Proxy"
            database = container "PostgreSQL Database" "Persistent storage for model metadata" "PostgreSQL 16"
        }

        k8s = softwareSystem "Kubernetes API Server" "Kubernetes control plane" "External"
        postgres = softwareSystem "External PostgreSQL/MySQL" "External database service" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning" "External"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for advanced networking" "External"
        openshift = softwareSystem "OpenShift Platform" "OpenShift-specific services (Router, Service CA, OAuth)" "External"

        platformComponents = softwareSystem "ODH Platform Components" "Platform component integration CRDs" "Internal ODH"
        platformServices = softwareSystem "ODH Platform Services" "Authentication configuration discovery CRDs" "Internal ODH"

        modelCatalog = softwareSystem "Model Catalog" "Curated model metadata and benchmarks" "Optional Feature" {
            catalogService = container "Catalog Service" "Provides pre-registered model metadata"
        }

        %% User interactions
        admin -> modelRegistryOp "Creates and manages ModelRegistry CRs via kubectl"
        user -> modelRegistryInstance "Stores and retrieves model metadata via REST API"

        %% Operator interactions
        modelRegistryOp -> k8s "Manages CRs, creates Deployments, Services, Routes, RBAC"
        modelRegistryOp -> modelRegistryInstance "Creates and manages instance lifecycle"
        modelRegistryOp -> certManager "Requests TLS certificates for webhooks" "Optional"
        modelRegistryOp -> openshift "Creates Routes, uses Service CA" "OpenShift only"
        modelRegistryOp -> platformComponents "Watches components.platform.opendatahub.io CRDs"
        modelRegistryOp -> platformServices "Watches services.platform.opendatahub.io auths"
        modelRegistryOp -> modelCatalog "Deploys and manages catalog instances" "Optional"

        webhook -> k8s "Called by API server for admission control"

        %% Model Registry Instance interactions
        proxy -> k8s "Performs SubjectAccessReview for authorization" "HTTPS/6443"
        proxy -> restAPI "Forwards authenticated requests" "HTTP/8080"
        restAPI -> database "Stores and retrieves model metadata" "PostgreSQL/5432"
        restAPI -> postgres "Alternative external database" "PostgreSQL or MySQL" "Optional"

        %% External dependencies
        modelRegistryInstance -> istio "Service mesh integration via VirtualService" "Optional"
        openshift -> modelRegistryInstance "Routes external traffic to proxy" "HTTPS/443"

        k8s -> webhook "Validates and mutates ModelRegistry CRs" "HTTPS/9443"
    }

    views {
        systemContext modelRegistryOp "SystemContext" {
            include *
            autoLayout
        }

        container modelRegistryOp "OperatorContainers" {
            include *
            autoLayout
        }

        container modelRegistryInstance "ModelRegistryContainers" {
            include *
            autoLayout
        }

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        component webhook "WebhookComponents" {
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
                color #000000
            }
            element "Optional Feature" {
                background #f5a623
                color #000000
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

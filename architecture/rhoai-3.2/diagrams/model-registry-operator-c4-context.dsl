workspace {
    model {
        admin = person "Administrator" "Creates and manages ModelRegistry instances"
        dataScientist = person "Data Scientist" "Registers and retrieves ML models via REST API"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator that manages the lifecycle of Model Registry instances and their associated resources" {
            controller = container "Controller Manager" "Reconciles ModelRegistry CRs and manages lifecycle" "Go Operator" {
                reconciler = component "ModelRegistry Reconciler" "Watches ModelRegistry CRs and creates resources" "Go Controller"
                webhook = component "Conversion Webhook" "Converts v1alpha1 ↔ v1beta1" "Go Webhook"
            }

            webhookServer = container "Webhook Server" "Validates and mutates ModelRegistry CR operations" "Go Service" {
                validator = component "Validating Webhook" "Validates ModelRegistry CR fields" "Go Handler"
                mutator = component "Mutating Webhook" "Sets default values for ModelRegistry CR" "Go Handler"
            }

            metricsProxy = container "kube-rbac-proxy" "Secures operator metrics endpoint" "Go Proxy"
        }

        modelRegistry = softwareSystem "Model Registry Instance" "Provides REST API for model metadata storage and retrieval" {
            restAPI = container "REST API Service" "Model Registry REST API (v1alpha3)" "Python Service"
            oauthProxy = container "OAuth Proxy" "OpenShift OAuth authentication proxy" "Go Proxy"
            rbacProxy = container "kube-rbac-proxy" "Kubernetes RBAC authentication proxy" "Go Proxy"
            grpcAPI = container "gRPC API (deprecated)" "Legacy gRPC interface" "Go Service"
        }

        postgresql = softwareSystem "PostgreSQL" "Backend database for model registry metadata" "External"
        mysql = softwareSystem "MySQL" "Alternative backend database" "External"

        k8s = softwareSystem "Kubernetes API Server" "Kubernetes control plane" "Platform"
        openShiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift authentication service" "Platform"
        openShiftRouter = softwareSystem "OpenShift Router" "Exposes services externally" "Platform"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External Optional"

        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management" "External Optional"
        authorino = softwareSystem "Authorino" "Istio-based authentication service" "Internal ODH Optional"

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform"

        odhModelMetadata = softwareSystem "ODH Model Metadata Collection" "Provides catalog and benchmark data" "Internal ODH"

        # Relationships - Admin interactions
        admin -> k8s "Creates ModelRegistry CR via kubectl/oc"

        # Relationships - Data Scientist interactions
        dataScientist -> openShiftRouter "Calls REST API endpoints (HTTPS/443)"

        # Relationships - Operator to Platform
        k8s -> webhookServer "Calls validation/mutation webhooks (HTTPS/9443)"
        k8s -> controller "Notifies of ModelRegistry CR changes (Watch API)"
        controller -> k8s "Creates/updates Deployments, Services, Routes, RBAC (HTTPS/443)"
        prometheus -> metricsProxy "Scrapes metrics (HTTPS/8443)"
        metricsProxy -> k8s "Validates permissions (SubjectAccessReview)"

        # Relationships - Model Registry to Dependencies
        openShiftRouter -> oauthProxy "Routes traffic (HTTPS/8443)" "HTTPS"
        openShiftRouter -> rbacProxy "Routes traffic (HTTPS/8443)" "HTTPS"
        oauthProxy -> openShiftOAuth "Validates bearer tokens (HTTPS/443)" "OAuth 2.0"
        oauthProxy -> restAPI "Proxies requests (HTTP/8080)" "HTTP"
        rbacProxy -> k8s "Validates RBAC permissions (SubjectAccessReview)" "HTTPS"
        rbacProxy -> restAPI "Proxies requests (HTTP/8080)" "HTTP"

        restAPI -> postgresql "Stores/retrieves model metadata (5432/TCP)" "PostgreSQL Protocol"
        restAPI -> mysql "Stores/retrieves model metadata (3306/TCP)" "MySQL Protocol"

        # Relationships - Optional Dependencies
        controller -> certManager "Requests TLS certificates" "CRD"
        controller -> istio "Configures service mesh resources" "CRD"
        istio -> authorino "Delegates authentication (gRPC/50051)" "gRPC"

        # Relationships - Internal ODH
        restAPI -> odhModelMetadata "Uses catalog and benchmark data" "Image Reference"

        # Relationships - Database Provisioning
        controller -> postgresql "Optionally auto-provisions database" "Creates Deployment/Service"
    }

    views {
        systemContext modelRegistryOperator "SystemContext" {
            include *
            autoLayout
        }

        systemContext modelRegistry "ModelRegistryContext" {
            include *
            autoLayout
        }

        container modelRegistryOperator "OperatorContainers" {
            include *
            autoLayout
        }

        container modelRegistry "RegistryContainers" {
            include *
            autoLayout
        }

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        component webhookServer "WebhookComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #cccccc
                color #000000
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Internal ODH Optional" {
                background #b8e986
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

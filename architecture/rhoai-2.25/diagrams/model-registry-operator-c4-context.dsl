workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages model registry instances for ML model metadata tracking"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator that deploys and manages Model Registry instances for ML metadata storage and retrieval" {
            controller = container "Controller Manager" "Reconciles ModelRegistry CRs and manages lifecycle of registry instances" "Go Operator" {
                reconciler = component "ModelRegistry Reconciler" "Watches ModelRegistry CRs and creates/updates registry deployments" "Go Controller"
                webhookHandler = component "Webhook Handler" "Validates and mutates ModelRegistry CR changes" "Go Admission Webhook"
            }

            modelRegistryInstance = container "Model Registry Instance" "User-facing REST API service for ML metadata operations" "Python/gRPC" {
                restAPI = component "REST API Server" "Exposes /api/model_registry/v1alpha3/* endpoints" "Python Flask"
                oauthProxy = component "OAuth Proxy Sidecar" "Handles OpenShift OAuth authentication and authorization" "Go Service"
            }
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane API" "External Infrastructure"
        postgresDB = softwareSystem "PostgreSQL Database" "ML Metadata (MLMD) persistence backend" "External Database"
        mysqlDB = softwareSystem "MySQL Database" "Alternative ML Metadata persistence backend" "External Database"
        openShiftOAuth = softwareSystem "OpenShift OAuth Server" "User authentication provider" "External OpenShift"
        openShiftRouter = softwareSystem "OpenShift Ingress Router" "External route exposure for registry services" "External OpenShift"
        openShiftServiceCA = softwareSystem "OpenShift Service CA" "Automatic TLS certificate provisioning" "External OpenShift"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH/RHOAI"
        odhOperator = softwareSystem "ODH/RHODS Operator" "Platform-level operator for component management" "Internal ODH/RHOAI"

        # User interactions
        user -> modelRegistryOperator "Creates ModelRegistry CR via kubectl/oc"
        user -> modelRegistryInstance "Queries/updates model metadata via REST API" "HTTPS/8443 (OAuth) or HTTP/8080 (internal)"

        # Operator interactions
        reconciler -> kubernetesAPI "Watches ModelRegistry CRs, creates Deployments, Services, Routes, RBAC" "HTTPS/6443"
        kubernetesAPI -> webhookHandler "Validates/mutates ModelRegistry CR changes" "HTTPS/443"
        reconciler -> openShiftServiceCA "Requests TLS certificates for OAuth proxy" "Service CA Annotations"

        # Model Registry Instance interactions
        oauthProxy -> openShiftOAuth "Validates Bearer tokens and checks RBAC" "HTTPS/443"
        oauthProxy -> restAPI "Forwards authenticated requests" "HTTP/8080 (localhost)"
        restAPI -> postgresDB "Stores/retrieves ML Metadata" "PostgreSQL/5432 (TLS optional)"
        restAPI -> mysqlDB "Stores/retrieves ML Metadata (alternative)" "MySQL/3306 (TLS optional)"

        # External access
        user -> openShiftRouter "Accesses registry via external route" "HTTPS/443"
        openShiftRouter -> modelRegistryInstance "Routes to model registry service" "HTTPS/8443"

        # Monitoring
        prometheus -> controller "Scrapes operator metrics" "HTTPS/8443"

        # Platform integration
        odhOperator -> modelRegistryOperator "Platform-level registry management via components.platform.opendatahub.io CRD" "Watch"
    }

    views {
        systemContext modelRegistryOperator "SystemContext" {
            include *
            autoLayout lr
        }

        container modelRegistryOperator "Containers" {
            include *
            autoLayout tb
        }

        component controller "ControllerComponents" {
            include *
            autoLayout tb
        }

        component modelRegistryInstance "InstanceComponents" {
            include *
            autoLayout tb
        }

        styles {
            element "External Infrastructure" {
                background #999999
                color #ffffff
            }
            element "External OpenShift" {
                background #cc0000
                color #ffffff
            }
            element "External Database" {
                background #4a90e2
                color #ffffff
            }
            element "Internal ODH/RHOAI" {
                background #7ed321
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
                shape Person
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}

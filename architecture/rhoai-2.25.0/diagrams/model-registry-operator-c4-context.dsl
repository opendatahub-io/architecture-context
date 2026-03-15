workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages model registry instances for ML metadata tracking"
        admin = person "Platform Administrator" "Manages operator installation and platform-level configuration"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator that deploys and manages Model Registry instances for ML metadata storage" {
            controllerManager = container "Controller Manager" "Reconciles ModelRegistry CRs and manages lifecycle" "Go Operator" {
                tags "Operator"
            }
            webhookServer = container "Webhook Server" "Validates and mutates ModelRegistry custom resources" "Go Service" {
                tags "Operator"
            }
            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus metrics for operator health monitoring" "HTTP/8443" {
                tags "Operator"
            }
        }

        modelRegistryInstance = softwareSystem "Model Registry Instance" "REST API service for ML Metadata storage and retrieval (deployed per CR)" {
            restAPI = container "REST API Container" "Provides REST API for model metadata operations" "Python/gRPC" {
                tags "Instance"
            }
            oauthProxy = container "OAuth Proxy (Optional)" "Authenticates external users via OpenShift OAuth" "Go Proxy" {
                tags "Instance"
            }
        }

        # External Systems
        kubernetes = softwareSystem "Kubernetes API Server" "Provides cluster orchestration and CR management" "External"
        openshift = softwareSystem "OpenShift Components" "Provides OAuth, Routes, and Service CA" "External"
        postgres = softwareSystem "PostgreSQL Database" "Stores ML Metadata (MLMD) persistently" "External Database"
        mysql = softwareSystem "MySQL Database" "Alternative backend for ML Metadata storage" "External Database"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring platform" "External Monitoring"

        # Internal ODH/RHOAI Systems
        odhOperator = softwareSystem "ODH/RHOAI Operator" "Platform operator for component integration" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing ODH components" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving platform that may integrate with model registry" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "ML workflow orchestration that tracks models" "Internal ODH"

        # Relationships - User Interactions
        user -> modelRegistryOperator "Creates ModelRegistry CRs via kubectl/oc"
        admin -> modelRegistryOperator "Installs and configures operator"
        user -> modelRegistryInstance "Accesses ML metadata via REST API" "HTTPS/8443 (OAuth) or HTTP/8080"

        # Operator Relationships
        controllerManager -> kubernetes "Watches ModelRegistry CRs and manages resources" "HTTPS/6443"
        controllerManager -> openshift "Creates Routes and manages OAuth config" "HTTPS/6443"
        webhookServer -> kubernetes "Validates/mutates ModelRegistry CRs" "HTTPS/443"
        metricsEndpoint -> prometheus "Exposes metrics" "HTTPS/8443"

        # Model Registry Instance Relationships
        oauthProxy -> openshift "Validates OAuth tokens" "HTTPS/443"
        oauthProxy -> restAPI "Forwards authenticated requests" "HTTP/8080 localhost"
        restAPI -> postgres "Reads/writes ML Metadata" "PostgreSQL/5432"
        restAPI -> mysql "Alternative backend for MLMD" "MySQL/3306"

        # Operator to Instance
        controllerManager -> modelRegistryInstance "Creates and manages deployment"

        # Integration Points
        odhOperator -> modelRegistryOperator "Watches components.platform.opendatahub.io/modelregistries"
        odhDashboard -> modelRegistryInstance "UI for model registry management" "REST API"
        kserve -> modelRegistryInstance "Fetches model metadata for serving" "REST API"
        pipelines -> modelRegistryInstance "Registers models from ML pipelines" "REST API"

        # Certificate Management
        openshift -> modelRegistryOperator "Provides Service CA for TLS certificates"
        openshift -> modelRegistryInstance "Provides TLS certificates for OAuth proxy"
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

        container modelRegistryInstance "InstanceContainers" {
            include *
            autoLayout
        }

        systemContext modelRegistryInstance "InstanceSystemContext" {
            include *
            include user
            include admin
            include modelRegistryOperator
            autoLayout
        }

        dynamic modelRegistryOperator "CreateModelRegistry" "User creates a ModelRegistry CR" {
            user -> controllerManager "1. Creates ModelRegistry CR"
            controllerManager -> kubernetes "2. Watches CR events"
            kubernetes -> webhookServer "3. Validates CR"
            controllerManager -> kubernetes "4. Creates Deployment"
            controllerManager -> kubernetes "5. Creates Service"
            controllerManager -> openshift "6. Creates Route (if enabled)"
            controllerManager -> modelRegistryInstance "7. Model Registry instance running"
            autoLayout
        }

        dynamic modelRegistryInstance "ExternalAccess" "External user accesses Model Registry via OAuth" {
            user -> openshift "1. HTTPS request to Route"
            openshift -> oauthProxy "2. Forward to OAuth proxy"
            oauthProxy -> openshift "3. Validate OAuth token"
            oauthProxy -> restAPI "4. Forward to REST API"
            restAPI -> postgres "5. Query ML Metadata"
            postgres -> restAPI "6. Return data"
            restAPI -> oauthProxy "7. Return response"
            oauthProxy -> user "8. HTTPS response"
            autoLayout
        }

        styles {
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Instance" {
                background #7ed321
                color #000000
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Database" {
                background #f5a623
                color #000000
            }
            element "External Monitoring" {
                background #bd10e0
                color #ffffff
            }
            element "Internal ODH" {
                background #50e3c2
                color #000000
            }
            element "Person" {
                background #08b5e5
                color #ffffff
                shape person
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}

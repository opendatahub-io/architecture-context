workspace {
    name "MLflow Operator - C4 Architecture"
    description "C4 model for MLflow Operator component in RHOAI/ODH"

    model {
        # Actors
        dataScientist = person "Data Scientist" "Creates MLflow instances and tracks ML experiments via web UI and API"
        admin = person "Platform Administrator" "Deploys and manages MLflow Operator via kubectl/OpenShift Console"

        # Main System
        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator that automates deployment and lifecycle management of MLflow experiment tracking and model registry servers" {
            # Containers
            controller = container "MLflow Controller" "Manages MLflow CR lifecycle, renders Helm charts, creates Kubernetes resources" "Go Operator" {
                tags "Operator"
            }

            helmEngine = container "Embedded Helm Chart" "Templates Kubernetes manifests for MLflow deployments" "Helm v3" {
                tags "TemplateEngine"
            }

            httpRouteController = container "HTTPRoute Controller" "Creates Gateway API HTTPRoutes for external access" "Go Reconciler" {
                tags "Controller"
            }

            consoleLinkController = container "ConsoleLink Controller" "Creates OpenShift Console application menu links" "Go Reconciler" {
                tags "Controller"
            }

            metricsEndpoint = container "Metrics Endpoint" "Exposes operator health and performance metrics" "HTTPS/8443" {
                tags "Monitoring"
            }
        }

        # MLflow Server Instances (created by operator)
        mlflowServer = softwareSystem "MLflow Server Instance" "Provides experiment tracking, model registry, and artifact storage REST API" {
            tags "ManagedInstance"

            webUI = container "MLflow Web UI" "Interactive interface for experiment tracking and model management" "Python/Flask" {
                tags "WebUI"
            }

            restAPI = container "MLflow REST API" "RESTful API for MLflow operations (experiments, runs, models, artifacts)" "Python/Flask, Port 8443/HTTPS" {
                tags "API"
            }

            authModule = container "kubernetes-auth Module" "Validates Kubernetes Bearer tokens via self_subject_access_review" "Python" {
                tags "Security"
            }
        }

        # Internal ODH/RHOAI Systems
        gateway = softwareSystem "data-science-gateway" "Gateway API implementation for external traffic routing to ODH/RHOAI services" {
            tags "InternalODH"
        }

        console = softwareSystem "OpenShift Console" "Web-based administrative interface for OpenShift/Kubernetes clusters" {
            tags "InternalODH"
        }

        dashboard = softwareSystem "ODH/RHOAI Dashboard" "Centralized web interface for data science platform management" {
            tags "InternalODH"
        }

        prometheus = softwareSystem "Prometheus" "Monitoring and alerting system for Kubernetes clusters" {
            tags "InternalODH"
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes API Server" "Cluster orchestration and API server (v1.11.3+)" {
            tags "External"
        }

        serviceCa = softwareSystem "service-ca-operator" "Automatic TLS certificate provisioning for OpenShift services" {
            tags "External"
        }

        # Optional External Services
        postgresql = softwareSystem "PostgreSQL Database" "Relational database for MLflow metadata storage (backend/registry stores)" {
            tags "ExternalOptional"
        }

        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for MLflow artifact storage (models, plots, files)" {
            tags "ExternalOptional"
        }

        # Relationships - Users
        dataScientist -> mlflowOperator "Creates MLflow CRs via kubectl/oc CLI"
        dataScientist -> gateway "Accesses MLflow instances via HTTPS (Bearer Token)"
        dataScientist -> dashboard "Manages MLflow instances via dashboard"
        dataScientist -> console "Views MLflow links in application menu"

        admin -> mlflowOperator "Deploys and configures via kubectl/oc"
        admin -> console "Monitors MLflow operator and instances"

        # Relationships - Operator Internal
        controller -> helmEngine "Uses for manifest templating"
        controller -> httpRouteController "Manages HTTPRoute reconciliation"
        controller -> consoleLinkController "Manages ConsoleLink reconciliation"
        controller -> metricsEndpoint "Exposes metrics"

        # Relationships - Operator to External Systems
        controller -> kubernetes "Watches MLflow CRs, creates/updates resources (Deployments, Services, etc.)" "HTTPS/6443, TLS 1.2+, ServiceAccount Token"
        httpRouteController -> gateway "Creates HTTPRoutes for MLflow instances" "Gateway API CRD"
        consoleLinkController -> console "Creates ConsoleLinks for application menu" "ConsoleLink CRD"
        prometheus -> metricsEndpoint "Scrapes operator metrics" "HTTPS/8443, TLS 1.2+, Bearer Token"

        # Relationships - Operator creates MLflow Instances
        controller -> mlflowServer "Creates and manages lifecycle"

        # Relationships - MLflow Server
        gateway -> restAPI "Routes external traffic to MLflow API" "HTTPS/8443, TLS 1.3, HTTPRoute"
        gateway -> webUI "Routes external traffic to MLflow UI" "HTTPS/8443, TLS 1.3, HTTPRoute /mlflow/*"

        restAPI -> authModule "Validates user Bearer tokens"
        webUI -> authModule "Validates user Bearer tokens"
        authModule -> kubernetes "Performs self_subject_access_review" "HTTPS/6443, TLS 1.2+, ServiceAccount Token"

        serviceCa -> mlflowServer "Provisions and auto-rotates TLS certificates" "service-ca annotation"

        # Relationships - MLflow Server to External Storage (Optional)
        restAPI -> postgresql "Stores experiment/model metadata" "PostgreSQL/5432, TLS 1.2+ (optional), User/Pass"
        restAPI -> s3Storage "Stores/retrieves ML artifacts (models, plots, files)" "HTTPS/443, TLS 1.2+, AWS IAM/Access Keys"

        # Relationships - Dashboard (indirect)
        dashboard -> gateway "Provides links to MLflow instances"
    }

    views {
        systemContext mlflowOperator "MLflowOperator-SystemContext" {
            include *
            autoLayout lr
            description "System context diagram for MLflow Operator showing external actors and dependencies"
        }

        container mlflowOperator "MLflowOperator-Containers" {
            include *
            autoLayout lr
            description "Container diagram showing internal components of MLflow Operator"
        }

        container mlflowServer "MLflowServer-Containers" {
            include *
            autoLayout tb
            description "Container diagram for MLflow Server instances created by the operator"
        }

        systemLandscape "MLflow-Landscape" {
            include *
            autoLayout lr
            description "System landscape showing MLflow Operator in the context of RHOAI/ODH platform"
        }

        dynamic mlflowOperator "MLflow-UserAccess" "User accessing MLflow via Gateway" {
            dataScientist -> gateway "1. Sends HTTPS request to /mlflow/* (Bearer Token)"
            gateway -> restAPI "2. Routes to MLflow Service (HTTPRoute backend)"
            restAPI -> authModule "3. Validates Bearer Token"
            authModule -> kubernetes "4. self_subject_access_review API call"
            kubernetes -> authModule "5. Returns authorization result"
            authModule -> restAPI "6. Authorization complete"
            restAPI -> dataScientist "7. Returns MLflow response (experiment data, UI, etc.)"
            autoLayout lr
            description "Dynamic view of user accessing MLflow through the data-science-gateway"
        }

        dynamic mlflowOperator "MLflow-Reconciliation" "Operator reconciling MLflow CR" {
            admin -> kubernetes "1. Creates MLflow CR (kubectl apply)"
            kubernetes -> controller "2. Watch event triggers reconciliation"
            controller -> helmEngine "3. Render Helm templates with CR values"
            helmEngine -> controller "4. Returns Kubernetes manifests"
            controller -> kubernetes "5. Create/update resources (Deployment, Service, SA, etc.)"
            httpRouteController -> gateway "6. Create HTTPRoute for external access"
            consoleLinkController -> console "7. Create ConsoleLink for application menu"
            autoLayout lr
            description "Dynamic view of operator reconciling a new MLflow CR"
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }

            element "SoftwareSystem" {
                background #1168bd
                color #ffffff
            }

            element "Container" {
                background #438dd5
                color #ffffff
            }

            element "Operator" {
                background #4a90e2
                color #ffffff
            }

            element "Controller" {
                background #5ca0f2
                color #ffffff
            }

            element "TemplateEngine" {
                background #0f1689
                color #ffffff
            }

            element "ManagedInstance" {
                background #0194e2
                color #ffffff
            }

            element "WebUI" {
                background #50e3c2
                color #000000
            }

            element "API" {
                background #4a90e2
                color #ffffff
            }

            element "Security" {
                background #f5a623
                color #000000
            }

            element "InternalODH" {
                background #7ed321
                color #000000
            }

            element "External" {
                background #999999
                color #ffffff
            }

            element "ExternalOptional" {
                background #cccccc
                color #000000
                stroke #999999
                strokeWidth 2
            }

            element "Monitoring" {
                background #bd10e0
                color #ffffff
            }
        }

        themes default
    }
}

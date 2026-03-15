workspace {
    model {
        user = person "Data Scientist" "Creates ML experiments and tracks models using MLflow"
        admin = person "Platform Administrator" "Deploys and manages MLflow instances on Kubernetes"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator that automates deployment and lifecycle management of MLflow experiment tracking and model registry servers" {
            controller = container "MLflow Operator Controller" "Watches MLflow CRs and reconciles desired state by rendering Helm charts" "Go"
            helmEngine = container "Embedded Helm Chart Engine" "Renders Kubernetes manifests for MLflow deployments" "Helm v3"
            httprouteController = container "HTTPRoute Controller" "Creates Gateway API HTTPRoutes for external access" "Go Reconciler"
            consolelinkController = container "ConsoleLink Controller" "Creates OpenShift Console application menu links" "Go Reconciler"
        }

        mlflowServer = softwareSystem "MLflow Server Instance" "Provides experiment tracking, model registry, and artifact storage capabilities" "Python Application"

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        gateway = softwareSystem "data-science-gateway" "Gateway API ingress for routing external traffic to MLflow instances" "Internal ODH"
        console = softwareSystem "OpenShift Console" "OpenShift web console with application menu" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection system" "Internal ODH"
        dashboard = softwareSystem "ODH/RHOAI Dashboard" "Centralized dashboard for data science platform" "Internal ODH"

        postgresql = softwareSystem "PostgreSQL" "Relational database for MLflow metadata storage (backend/registry store)" "External Optional"
        s3 = softwareSystem "S3 Storage" "Object storage for ML model artifacts" "External Optional"
        serviceCA = softwareSystem "service-ca-operator" "OpenShift operator for automatic TLS certificate provisioning" "External Optional"

        # User interactions
        admin -> mlflowOperator "Creates MLflow CRs via kubectl"
        user -> gateway "Accesses MLflow UI and API via HTTPS"
        user -> console "Opens MLflow from application menu"

        # Gateway routing
        gateway -> mlflowServer "Routes traffic to MLflow instances via HTTPRoute"

        # Dashboard integration
        dashboard -> gateway "Routes users to MLflow"

        # Operator interactions
        mlflowOperator -> kubernetes "Watches MLflow CRs, creates/updates Kubernetes resources (Deployments, Services, Secrets, etc.)" "HTTPS/6443"
        mlflowOperator -> gateway "Creates HTTPRoute resources for traffic routing" "Kubernetes API"
        mlflowOperator -> console "Creates ConsoleLink resources for menu integration" "Kubernetes API"
        mlflowOperator -> mlflowServer "Manages lifecycle (create, update, delete)"

        # MLflow server dependencies
        mlflowServer -> kubernetes "Performs authentication checks (self_subject_access_review), lists namespaces" "HTTPS/6443"
        mlflowServer -> postgresql "Stores experiment metadata (optional)" "PostgreSQL/5432"
        mlflowServer -> s3 "Stores model artifacts (optional)" "HTTPS/443"

        # Monitoring
        prometheus -> mlflowOperator "Scrapes operator metrics via ServiceMonitor" "HTTPS/8443"

        # TLS provisioning
        serviceCA -> mlflowServer "Injects TLS certificates for HTTPS endpoints (OpenShift only)" "Annotation-based"

        # Internal container relationships
        controller -> helmEngine "Renders templates with CR values"
        controller -> httprouteController "Triggers HTTPRoute reconciliation"
        controller -> consolelinkController "Triggers ConsoleLink reconciliation"
    }

    views {
        systemContext mlflowOperator "SystemContext" {
            include *
            autoLayout
        }

        container mlflowOperator "Containers" {
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
                color #333333
            }
            element "Internal ODH" {
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
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }

        theme default
    }
}

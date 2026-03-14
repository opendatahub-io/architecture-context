workspace {
    model {
        user = person "Data Scientist" "Tracks ML experiments, logs models and artifacts using MLflow API"
        admin = person "Platform Admin" "Deploys and manages MLflow instances via MLflow CRs"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator that automates deployment and lifecycle management of MLflow experiment tracking and model registry servers" {
            controller = container "MLflow Operator Controller" "Reconciles MLflow CRs and manages MLflow server lifecycle" "Go Operator" {
                tags "Operator"
            }
            helmEngine = container "Embedded Helm Chart" "Renders Kubernetes manifests for MLflow deployments" "Helm v3" {
                tags "Template"
            }
            httpRouteController = container "HTTPRoute Controller" "Creates Gateway API routes for MLflow instances" "Go Reconciler" {
                tags "Operator"
            }
            consoleLinkController = container "ConsoleLink Controller" "Creates OpenShift Console application menu links" "Go Reconciler" {
                tags "Operator"
            }
        }

        mlflowServer = softwareSystem "MLflow Server" "Provides experiment tracking, model registry, and artifact storage REST API" {
            server = container "MLflow Server" "Handles experiment tracking and model registry requests" "Python/MLflow 3.6.0" {
                tags "Application"
            }
        }

        k8s = softwareSystem "Kubernetes API" "Cluster orchestration and API server" "External"
        gateway = softwareSystem "data-science-gateway" "Gateway API routing for external access" "Internal ODH"
        osConsole = softwareSystem "OpenShift Console" "Web console with application menu integration" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH"
        serviceCa = softwareSystem "service-ca-operator" "Automatic TLS certificate provisioning" "Internal ODH"

        postgresql = softwareSystem "PostgreSQL" "Backend and registry store for MLflow metadata" "External"
        s3 = softwareSystem "S3 Storage" "Artifact storage for MLflow models and files" "External"

        # Relationships - User interactions
        user -> mlflowServer "Tracks experiments, logs models, uploads artifacts" "HTTPS/8443, Bearer Token"
        user -> gateway "Accesses MLflow via /mlflow path" "HTTPS/443, Bearer Token"
        admin -> mlflowOperator "Creates MLflow CRs to deploy instances" "kubectl/OpenShift"

        # Relationships - Operator
        controller -> k8s "Watches MLflow CRs, creates/updates resources" "HTTPS/6443, SA Token"
        controller -> helmEngine "Renders Helm templates for manifests" "Local filesystem"
        httpRouteController -> gateway "Creates HTTPRoutes for MLflow instances" "Gateway API"
        consoleLinkController -> osConsole "Creates ConsoleLinks for application menu" "ConsoleLink CRD"
        controller -> prometheus "Exposes operator metrics" "HTTPS/8443"

        # Relationships - MLflow Server
        mlflowServer -> k8s "Validates bearer tokens via self_subject_access_review" "HTTPS/6443, SA Token"
        mlflowServer -> postgresql "Stores experiment and model metadata" "PostgreSQL/5432, TLS optional"
        mlflowServer -> s3 "Stores artifacts (models, files)" "HTTPS/443, AWS IAM"
        mlflowServer -> serviceCa "Auto-provisioned TLS certificates" "Annotation-based"

        # Relationships - Gateway
        gateway -> mlflowServer "Routes external traffic to MLflow" "HTTPS/8443, HTTPRoute"

        # Operator internal relationships
        controller -> httpRouteController "Creates HTTPRoute resources"
        controller -> consoleLinkController "Creates ConsoleLink resources"
    }

    views {
        systemContext mlflowOperator "MLflowOperatorSystemContext" {
            include *
            autoLayout
        }

        container mlflowOperator "MLflowOperatorContainers" {
            include *
            autoLayout
        }

        systemContext mlflowServer "MLflowServerSystemContext" {
            include *
            autoLayout
        }

        container mlflowServer "MLflowServerContainers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "External" {
                background #999999
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
            element "Template" {
                background #5bc0de
                color #ffffff
            }
            element "Application" {
                background #50e3c2
                color #000000
            }
        }
    }
}

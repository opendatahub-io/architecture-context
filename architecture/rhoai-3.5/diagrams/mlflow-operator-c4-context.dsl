workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML experiments, models, and traces via MLflow workspaces"
        platformAdmin = person "Platform Admin" "Deploys and configures MLflow instances via MLflow CR"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator that automates deployment, lifecycle management, and database migration orchestration for MLflow on OpenShift" {
            mlflowController = container "MLflow Controller" "Watches MLflow CRs, renders Helm chart, applies resources via SSA, manages migration Jobs, reconciles HTTPRoute and ConsoleLink" "Go (controller-runtime)"
            mlflowOperatorController = container "MLflowOperator Controller" "Watches singleton MLflowOperator CR for platform module handoff, projects gateway config, tracks release status" "Go (controller-runtime)"
            namespaceRBACController = container "Namespace RBAC Controller" "Watches labeled Namespaces and Auth CR, reconciles view/edit RoleBindings in workspace namespaces" "Go (controller-runtime)"
            helmRenderer = container "Helm Renderer" "Converts MLflow CR spec to Helm values, renders chart templates, produces unstructured Kubernetes objects" "Go (Helm SDK v3)"
        }

        mlflowServer = softwareSystem "MLflow Server" "Deployed MLflow instance serving REST API for experiment tracking, model registry, and trace management" {
            mlflowApp = container "MLflow Application" "Serves MLflow REST API with Kubernetes-native auth" "Python (uvicorn)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Central control plane API for cluster resource management" "Infrastructure"
        gateway = softwareSystem "data-science-gateway" "Envoy-based Gateway API gateway in openshift-ingress namespace for external traffic routing" "Infrastructure"
        serviceCA = softwareSystem "service-ca-operator" "OpenShift automatic TLS certificate provisioning via service annotations" "Infrastructure"
        openshiftConsole = softwareSystem "OpenShift Console" "Web console for OpenShift cluster management" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring via ServiceMonitor" "Infrastructure"

        postgresql = softwareSystem "PostgreSQL" "Relational database for MLflow metadata store (backend + registry)" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for MLflow artifact storage (S3, MinIO, SeaweedFS)" "External"

        authCR = softwareSystem "Auth CR" "Platform service providing allowedGroups and adminGroups for namespace RBAC" "Internal RHOAI"
        mlflowOperatorCR = softwareSystem "MLflowOperator CR" "Platform module handoff CR projecting gateway domain, name, and section title" "Internal RHOAI"

        # Relationships
        platformAdmin -> mlflowOperator "Creates/updates MLflow CR" "kubectl/oc"
        dataScientist -> gateway "Accesses MLflow API" "HTTPS/443, Bearer token"

        gateway -> mlflowServer "Forwards requests" "HTTPS/8443, TLS (service-ca)"

        mlflowController -> helmRenderer "Renders Helm chart" "In-process"
        mlflowController -> k8sAPI "Watches CRs, applies resources via SSA" "HTTPS/6443, SA token"
        mlflowController -> k8sAPI "Creates HTTPRoute, ConsoleLink" "HTTPS/6443, SA token"
        mlflowOperatorController -> k8sAPI "Watches MLflowOperator CR" "HTTPS/6443, SA token"
        namespaceRBACController -> k8sAPI "Manages workspace RoleBindings" "HTTPS/6443, SA token"

        mlflowServer -> k8sAPI "SelfSubjectAccessReview" "HTTPS/6443, Caller's bearer token"
        mlflowServer -> postgresql "Stores/queries metadata" "PostgreSQL/5432, TLS verify-full"
        mlflowServer -> s3Storage "Stores/retrieves artifacts" "HTTPS/443, AWS IAM"

        serviceCA -> mlflowServer "Provisions TLS certificates" "Annotation-driven, auto-rotate"
        mlflowOperator -> openshiftConsole "Creates ConsoleLink" "CR management"
        prometheus -> mlflowOperator "Scrapes metrics" "HTTPS/8443, TLS"
        prometheus -> mlflowServer "Scrapes metrics" "HTTPS/8443, TLS"

        mlflowOperator -> authCR "Reads groups for RBAC" "HTTPS/6443, SA token"
        mlflowOperator -> mlflowOperatorCR "Reads gateway config" "HTTPS/6443, SA token"
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
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

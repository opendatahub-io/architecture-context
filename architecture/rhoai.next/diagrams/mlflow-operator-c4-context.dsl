workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages MLflow experiments, models, and artifacts via the MLflow UI and API"
        platformAdmin = person "Platform Admin" "Configures MLflow CR, manages workspace access, and monitors operator health"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator managing MLflow tracking server lifecycle, database migrations, Gateway API ingress, and workspace RBAC" {
            mlflowReconciler = container "MLflowReconciler" "Reconciles MLflow CR; renders embedded Helm chart; manages Deployment, Service, NetworkPolicy, PVC, ServiceMonitor, CronJobs" "Go Controller (controller-runtime)"
            mlflowOperatorReconciler = container "MLflowOperatorReconciler" "Reconciles MLflowOperator module CR; projects gateway config from platform operator" "Go Controller (controller-runtime)"
            namespaceRBACReconciler = container "NamespaceRBACReconciler" "Watches labeled namespaces and Auth CR; creates workspace-scoped RoleBindings (view/edit)" "Go Controller (controller-runtime)"
            helmRenderer = container "Helm Chart Renderer" "Renders embedded charts/mlflow Helm chart with values from MLflow CR spec" "helm.sh/helm/v3 (in-process)"
            migrationOrchestrator = container "Migration Orchestrator" "Detects version mismatches; scales Deployment to zero; creates migration Job; monitors completion" "Go (embedded)"
            routingManager = container "Routing Manager" "Creates/updates HTTPRoute for Gateway API ingress and ConsoleLink for OpenShift console" "Go (embedded)"
            mlflowServer = container "MLflow Server" "MLflow tracking server with kubernetes-auth plugin for SSAR-based authorization" "Python (uvicorn) 8443/TCP HTTPS"
        }

        gateway = softwareSystem "data-science-gateway" "Platform Gateway CR in openshift-ingress namespace for external traffic routing" "External"
        authCR = softwareSystem "Auth CR" "Platform Auth CR (services.platform.opendatahub.io) providing workspace group definitions" "Internal RHOAI"
        mlflowOperatorCR = softwareSystem "MLflowOperator CR" "Platform module CR for coordinated handoff with RHOAI platform operator" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Relational database for MLflow metadata storage (experiments, runs, params, metrics)" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for MLflow artifacts (models, datasets, logs)" "External"
        prometheus = softwareSystem "Prometheus" "Cluster monitoring via ServiceMonitor scraping operator metrics" "External"
        openshiftConsole = softwareSystem "OpenShift Console" "Web console with ConsoleLink integration for MLflow access" "External"
        certManager = softwareSystem "OpenShift service-ca" "Automatic TLS certificate provisioning and rotation via service-ca annotations" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management, RBAC, and SelfSubjectAccessReview" "External"

        # User interactions
        datascientist -> mlflowOperator "Accesses MLflow UI and REST API via Gateway" "HTTPS/443"
        platformAdmin -> mlflowOperator "Creates/updates MLflow CR and MLflowOperator CR" "kubectl"

        # Internal component interactions
        mlflowReconciler -> helmRenderer "Renders Helm chart with CR spec values" ""
        mlflowReconciler -> migrationOrchestrator "Triggers DB migration on version mismatch" ""
        mlflowReconciler -> routingManager "Creates HTTPRoute and ConsoleLink" ""
        mlflowOperatorReconciler -> mlflowReconciler "Projects gateway domain, name, section title" ""

        # External dependencies
        mlflowOperator -> gateway "HTTPRoute parent reference for external ingress" "HTTPS/443"
        mlflowOperator -> authCR "Reads allowedGroups and adminGroups for workspace RBAC" "K8s API/TLS"
        mlflowOperator -> mlflowOperatorCR "Watches module CR for platform handoff config" "K8s API/TLS"
        mlflowOperator -> k8sAPI "Resource CRUD, RBAC, leader election, status updates" "HTTPS/6443"
        mlflowServer -> postgresql "Stores experiment metadata, run data, parameters, metrics" "TCP/5432 TLS optional"
        mlflowServer -> s3 "Stores and retrieves model artifacts and datasets" "HTTPS/443"
        migrationOrchestrator -> postgresql "Runs schema migrations via migration Job" "TCP/5432 TLS optional"
        prometheus -> mlflowOperator "Scrapes operator metrics via ServiceMonitor" "HTTPS/8443"
        certManager -> mlflowServer "Provisions and rotates TLS certificates" "service-ca annotation"
        routingManager -> openshiftConsole "Creates ConsoleLink for MLflow access in console menu" "K8s API"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

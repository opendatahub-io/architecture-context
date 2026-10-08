workspace {
    model {
        user = person "Data Scientist" "Creates and manages MLflow tracking server instances"
        platformAdmin = person "Platform Admin" "Configures RHOAI platform components"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator that automates deployment and lifecycle management of MLflow tracking servers" {
            controllerManager = container "Controller Manager" "Main operator binary with three controllers" "Go Operator"
            mlflowReconciler = container "MLflowReconciler" "Reconciles MLflow CRs, renders Helm charts, manages child resources" "Go Controller"
            mlflowOperatorReconciler = container "MLflowOperatorReconciler" "Handles platform-level component lifecycle via MLflowOperator CR" "Go Controller (conditional)"
            namespaceRBACReconciler = container "NamespaceRBACReconciler" "Manages per-namespace workspace RoleBindings for multi-tenant access" "Go Controller (conditional)"
            securityProfileWatcher = container "SecurityProfileWatcher" "Watches TLS profile changes and triggers operator restart" "Go Controller"
            helmChart = container "Helm Chart" "Renders MLflow tracking server manifests (Deployment, Service, PVC, CronJobs)" "Helm Templates"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        gatewayAPI = softwareSystem "Platform Gateway" "data-science-gateway for external traffic routing via HTTPRoute" "Internal Platform"
        openshiftConsole = softwareSystem "OpenShift Console" "Web console with ConsoleLink integration" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "Internal Platform"
        odhOperator = softwareSystem "ODH Operator" "Platform operator managing component lifecycle via MLflowOperator CR" "Internal Platform"
        odhAuth = softwareSystem "ODH Auth CR" "Platform authentication configuration for namespace RBAC" "Internal Platform"
        serviceCaOperator = softwareSystem "service-ca-operator" "TLS certificate provisioning for metrics endpoint" "External"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Cluster-wide TLS cryptographic policy configuration" "External"
        mlflow = softwareSystem "MLflow" "ML tracking server v3.15.2 deployed as container" "Managed Application"

        user -> mlflowOperator "Creates MLflow CR via kubectl"
        platformAdmin -> odhOperator "Configures platform components"
        odhOperator -> mlflowOperator "Sends lifecycle signals via MLflowOperator CR"
        mlflowOperator -> kubernetesAPI "CRUD resources, CRD watches" "HTTPS/6443"
        mlflowOperator -> gatewayAPI "Creates HTTPRoute for external access" "HTTPS"
        mlflowOperator -> openshiftConsole "Registers ConsoleLink" "HTTPS"
        mlflowOperator -> prometheus "Creates ServiceMonitor" "HTTPS"
        mlflowOperator -> odhAuth "Reads Auth CR for namespace RBAC" "HTTPS"
        mlflowOperator -> serviceCaOperator "Requests TLS certificates" "Service annotation"
        mlflowOperator -> openshiftAPIServer "Reads TLS profile" "HTTPS"
        mlflowOperator -> mlflow "Deploys and manages lifecycle" "Helm chart rendering"
        prometheus -> mlflowOperator "Scrapes metrics" "HTTPS/8443"
        user -> mlflow "Accesses tracking UI and API via Gateway" "HTTPS/443"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Managed Application" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

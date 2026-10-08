workspace {
    model {
        user = person "Data Scientist / Platform Admin" "Creates MLflow CRs to deploy MLflow tracking servers"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator automating MLflow tracking server lifecycle on OpenShift" {
            controllerManager = container "Controller Manager" "Main operator binary with multiple controllers" "Go Operator"
            mlflowReconciler = container "MLflow Reconciler" "Reconciles MLflow CRs into Helm-rendered resources" "controller-runtime"
            moduleReconciler = container "MLflowOperator Reconciler" "Handles ODH platform module handoff" "controller-runtime"
            nsRBACReconciler = container "Namespace RBAC Reconciler" "Propagates workspace RoleBindings" "controller-runtime"
            tlsWatcher = container "SecurityProfile Watcher" "Watches TLS profile changes and triggers restart" "controller-runtime"
            helmRenderer = container "Helm Renderer" "Renders embedded charts/mlflow/ into K8s manifests" "helm.sh/helm/v3"
        }

        mlflowServer = softwareSystem "MLflow Tracking Server" "Deployed MLflow instances managed by the operator" "Managed"

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        gatewayAPI = softwareSystem "Gateway API" "Data-science-gateway for ingress routing" "Internal RHOAI"
        openshiftConsole = softwareSystem "OpenShift Console" "Web console with application menu links" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring stack for metrics collection" "Internal RHOAI"
        authCR = softwareSystem "Auth CR" "Platform authentication configuration" "Internal RHOAI"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Cluster TLS security profile provider" "External"
        odhOperator = softwareSystem "ODH Operator" "Platform operator coordinating component lifecycle" "Internal RHOAI"

        # Relationships
        user -> mlflowOperator "Creates MLflow CRs via kubectl"
        user -> mlflowServer "Accesses tracking UI via Gateway" "HTTPS/443"

        mlflowOperator -> kubernetesAPI "Reconciles resources, watches CRDs" "HTTPS/6443"
        mlflowOperator -> gatewayAPI "Creates HTTPRoutes for MLflow ingress" "HTTPS/6443"
        mlflowOperator -> openshiftConsole "Creates ConsoleLinks for menu entries" "HTTPS/6443"
        mlflowOperator -> prometheusOperator "Creates ServiceMonitors for scraping" "HTTPS/6443"
        mlflowOperator -> authCR "Reads workspace group subjects" "HTTPS/6443"
        mlflowOperator -> openshiftAPIServer "Fetches TLS profile configuration" "HTTPS/6443"
        mlflowOperator -> mlflowServer "Deploys and manages lifecycle" "Helm-rendered resources"

        odhOperator -> mlflowOperator "Coordinates via MLflowOperator CR" "HTTPS/6443"

        gatewayAPI -> mlflowServer "Routes traffic via HTTPRoute" "HTTPS/8443"
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
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Managed" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

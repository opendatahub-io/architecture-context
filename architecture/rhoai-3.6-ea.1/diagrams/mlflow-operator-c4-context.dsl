workspace {
    model {
        platformAdmin = person "Platform Admin" "Configures MLflow instances and workspace access via CRDs"
        datascientist = person "Data Scientist" "Uses MLflow Tracking Server for experiment tracking"

        mlflowOperator = softwareSystem "mlflow-operator" "Kubernetes operator managing MLflow Tracking Server lifecycle, Helm-based deployment, Gateway API routing, and workspace RBAC" {
            mlflowController = container "MLflow Controller" "Reconciles MLflow CRs, renders Helm charts, manages server-side apply of Kubernetes resources" "Go controller-runtime"
            mlflowOperatorController = container "MLflowOperator Controller" "Reconciles MLflowOperator CRs for RHOAI platform integration" "Go controller-runtime"
            namespaceRBACController = container "Namespace RBAC Controller" "Watches Auth CR and labeled namespaces, propagates view/edit RoleBindings" "Go controller-runtime"
            helmRenderer = container "Helm Chart Renderer" "Renders bundled Helm charts into Kubernetes manifests" "helm.sh/helm/v3"
            metricsEndpoint = container "Metrics Endpoint" "TLS-protected Prometheus metrics on :8443 with TokenReview/SAR auth" "controller-runtime metrics"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "Infrastructure"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTP routing (optional)" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection via ServiceMonitor (optional)" "Infrastructure"
        openshiftConsole = softwareSystem "OpenShift Console" "Web console with ConsoleLink integration (optional)" "Infrastructure"
        authService = softwareSystem "RHOAI Auth Service" "Platform auth configuration (services.platform.opendatahub.io)" "Internal RHOAI"
        odhOperator = softwareSystem "odh-operator" "RHOAI platform operator managing component lifecycle" "Internal RHOAI"

        platformAdmin -> mlflowOperator "Creates MLflow/MLflowOperator CRs via kubectl"
        datascientist -> mlflowOperator "Uses managed MLflow Tracking Server"

        mlflowController -> helmRenderer "Renders Helm charts into manifests"
        mlflowController -> k8sAPI "Server-side apply (Deployments, Services, PVCs, CronJobs, NetworkPolicies)" "HTTPS/6443 TLS 1.2+"
        mlflowController -> gatewayAPI "Creates HTTPRoutes (conditional)" "HTTPS/6443"
        mlflowController -> prometheus "Creates ServiceMonitors (conditional)" "HTTPS/6443"
        mlflowController -> openshiftConsole "Creates ConsoleLinks (conditional)" "HTTPS/6443"

        mlflowOperatorController -> k8sAPI "Watches MLflowOperator CR, reads ConfigMaps" "HTTPS/6443 TLS 1.2+"
        odhOperator -> mlflowOperator "Manages via MLflowOperator CR" "Kubernetes API"

        namespaceRBACController -> authService "Watches Auth CR for user/group mappings" "Kubernetes API"
        namespaceRBACController -> k8sAPI "Creates workspace RoleBindings (mlflow-view, mlflow-edit)" "HTTPS/6443 TLS 1.2+"

        prometheus -> metricsEndpoint "Scrapes metrics" "HTTPS/8443 TLS + TokenReview"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

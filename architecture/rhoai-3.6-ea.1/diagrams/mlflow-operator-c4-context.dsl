workspace {
    model {
        user = person "Data Scientist" "Creates and manages MLflow Tracking Server instances via CRs"
        platformAdmin = person "Platform Admin" "Manages MLflowOperator component lifecycle and cluster configuration"

        mlflowOperator = softwareSystem "mlflow-operator" "Manages MLflow Tracking Server lifecycle on OpenShift AI through three Kubernetes controllers" {
            mlflowController = container "MLflow Controller" "Reconciles MLflow CRs, renders Helm charts, manages instance lifecycle" "Go controller-runtime"
            operatorController = container "MLflowOperator Controller" "Reconciles MLflowOperator platform component lifecycle" "Go controller-runtime"
            namespaceController = container "Namespace RBAC Controller" "Manages per-namespace RoleBindings for MLflow access control" "Go controller-runtime"
            helmRenderer = container "Helm Chart Renderer" "Renders bundled charts/mlflow templates into Kubernetes manifests" "helm.sh/helm/v3"
            tlsWatcher = container "TLS Profile Watcher" "Watches OpenShift TLS profile, triggers reload on change" "Go"
            gcRBACCache = container "GCRBACWatchCache" "Manages garbage-collection RBAC with resourceNames-scoped selectors" "Go"
            metricsEndpoint = container "Metrics Endpoint" "Serves Prometheus metrics with TokenReview+SAR auth" "HTTPS :8443"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource operations" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTP routing (conditional)" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Manages Prometheus monitoring resources (conditional)" "External"
        openshiftConsole = softwareSystem "OpenShift Console" "Provides web console links (conditional)" "External"
        openshiftAPIServer = softwareSystem "OpenShift API Server" "Provides cluster TLS profile configuration" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes operator metrics" "External"

        mlflowTrackingServer = softwareSystem "MLflow Tracking Server" "Deployed ML experiment tracking instances" "Managed"

        user -> mlflowOperator "Creates MLflow CRs via kubectl/dashboard"
        platformAdmin -> mlflowOperator "Manages MLflowOperator component"

        mlflowOperator -> kubernetesAPI "Watches CRDs, manages resources" "HTTPS/6443, TLS 1.2+, ServiceAccount token"
        mlflowOperator -> gatewayAPI "Creates HTTPRoutes (conditional)" "HTTPS/6443"
        mlflowOperator -> prometheusOperator "Creates ServiceMonitors (conditional)" "HTTPS/6443"
        mlflowOperator -> openshiftConsole "Creates ConsoleLinks (conditional)" "HTTPS/6443"
        mlflowOperator -> openshiftAPIServer "Reads TLS profile, watches for changes" "HTTPS/6443"
        mlflowOperator -> mlflowTrackingServer "Deploys and manages lifecycle" "Kubernetes API"

        prometheus -> mlflowOperator "Scrapes metrics" "HTTPS/8443, TokenReview+SAR"

        mlflowController -> helmRenderer "Renders chart templates" "In-process"
        mlflowController -> gcRBACCache "Manages cluster-scoped RBAC" "In-process"
        mlflowController -> kubernetesAPI "CRUD managed resources" "HTTPS/6443"
        operatorController -> kubernetesAPI "Manages component lifecycle" "HTTPS/6443"
        namespaceController -> kubernetesAPI "Manages RoleBindings" "HTTPS/6443"
        tlsWatcher -> openshiftAPIServer "Watches TLS profile changes" "HTTPS/6443"
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
            element "Managed" {
                background #7ed321
                color #000000
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
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

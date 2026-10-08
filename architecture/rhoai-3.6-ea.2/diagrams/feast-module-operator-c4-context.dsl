workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components"

        feastModuleOperator = softwareSystem "feast-module-operator" "Module operator that manages the lifecycle of the upstream Feast feature store operator within the RHOAI platform" {
            controller = container "FeastOperator Controller" "Reconciles FeastOperator CRs using composable action pipeline" "Go Operator"
            kustomizeRenderer = container "Kustomize Renderer" "Renders bundled manifests with platform-specific overlays" "Go Library"
            chartgen = container "chartgen CLI" "Generates Helm charts from kustomize manifests" "Go CLI"
        }

        odhOperator = softwareSystem "ODH Operator" "Deploys module operators via Helm charts and creates component CRs" "Internal RHOAI"
        feastOperator = softwareSystem "feast-operator" "Upstream Feast operator (v0.66.0) that manages FeatureStore CRDs" "Managed Workload"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "Infrastructure"
        prometheusOperator = softwareSystem "prometheus-operator" "Manages monitoring resources (ServiceMonitor)" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook resources watched by feast-operator" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "MLflow resources watched by feast-operator" "Internal RHOAI"
        sparkOperator = softwareSystem "Spark Operator" "Manages SparkApplications for feast-operator" "Internal RHOAI"
        openShiftRoutes = softwareSystem "OpenShift Router" "Manages routes for the feast-operator" "Infrastructure"

        # Relationships
        platformAdmin -> odhOperator "Configures RHOAI components"
        odhOperator -> feastModuleOperator "Creates FeastOperator CR and odh-feastoperator-config ConfigMap" "HTTPS/6443"
        feastModuleOperator -> kubernetesAPI "Manages resources (Deployments, CRDs, RBAC, Services)" "HTTPS/6443"
        feastModuleOperator -> feastOperator "Deploys and manages feast-operator-controller-manager" "HTTPS/6443"
        feastModuleOperator -> prometheusOperator "Creates ServiceMonitor resources" "HTTPS/6443"
        prometheus -> feastModuleOperator "Scrapes /metrics endpoint" "HTTPS/8443 TokenReview+SAR"
        feastOperator -> kubeflowNotebooks "Watches Notebook resources (read-only)" "HTTPS/6443"
        feastOperator -> mlflow "Watches MLflow resources (read-only)" "HTTPS/6443"
        feastOperator -> sparkOperator "Creates/deletes SparkApplications" "HTTPS/6443"
        feastOperator -> openShiftRoutes "Manages routes" "HTTPS/6443"

        # Container relationships
        controller -> kustomizeRenderer "Renders manifests with overlays"
    }

    views {
        systemContext feastModuleOperator "SystemContext" {
            include *
            autoLayout
        }

        container feastModuleOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Managed Workload" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

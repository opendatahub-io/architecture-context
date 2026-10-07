workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages the ODH/RHOAI platform and component lifecycle"
        dataScientist = person "Data Scientist" "Creates FeatureStore instances for ML feature management"

        feastModuleOperator = softwareSystem "feast-module-operator" "Module operator that deploys and manages the upstream feast-operator via kustomize manifests" {
            reconciler = container "Reconciler" "Watches FeastOperator CRs, runs action pipeline" "Go (controller-runtime)"
            kustomizeRenderer = container "Kustomize Renderer" "Renders platform-specific manifests (ODH/RHOAI overlays)" "Go"
            upgradeHandler = container "Upgrade Handler" "Platform version handshake and semver-based migrations" "Go"
            chartgen = container "Chart Generator" "Generates Helm chart artifacts for module deployment" "Go CLI"
        }

        odhOperator = softwareSystem "ODH Operator" "Central platform operator that deploys module operators via Helm" "Internal RHOAI"
        feastOperator = softwareSystem "feast-operator" "Upstream feast operator managing FeatureStore CRs" "Deployed by feast-module-operator"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring stack operator" "Internal Platform"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook management (read-only watch)" "Internal Platform"
        mlflow = softwareSystem "MLflow" "ML experiment tracking (read-only watch)" "Internal Platform"
        sparkOperator = softwareSystem "Spark Operator" "Spark job management for batch materialization" "Internal Platform"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "Infrastructure"

        # Relationships
        platformAdmin -> odhOperator "Configures platform components"
        dataScientist -> feastOperator "Creates FeatureStore CRs via kubectl"

        odhOperator -> feastModuleOperator "Deploys via Helm chart, creates FeastOperator CR"
        odhOperator -> kubernetesAPI "Writes odh-feastoperator-config ConfigMap"

        feastModuleOperator -> kubernetesAPI "Watches CRs, applies manifests, manages resources" "HTTPS/6443"
        feastModuleOperator -> feastOperator "Deploys via kustomize manifests"
        feastModuleOperator -> prometheusOperator "Creates ServiceMonitor for metrics scraping" "HTTPS/6443"

        feastOperator -> kubeflowNotebooks "Watches Notebook CRs (read-only)" "HTTPS/6443"
        feastOperator -> mlflow "Watches MLflow CRs (read-only)" "HTTPS/6443"
        feastOperator -> sparkOperator "Creates SparkApplications for materialization" "HTTPS/6443"

        # Internal container relationships
        reconciler -> kustomizeRenderer "Invokes for manifest rendering"
        reconciler -> upgradeHandler "Invokes for version migrations"
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
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Internal Platform" {
                background #82b366
            }
            element "Deployed by feast-module-operator" {
                background #9b59b6
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

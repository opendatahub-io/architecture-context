workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages RHOAI platform installation and upgrades"
        dataScientist = person "Data Scientist" "Uses Feast feature stores for ML pipelines"

        feastModuleOperator = softwareSystem "feast-module-operator" "Kubernetes operator that manages Feast feature store deployments on OpenShift as a RHOAI platform module" {
            controller = container "FeastOperator Controller" "Reconciles FeastOperator CR, renders kustomize manifests, deploys Feast components" "Go / controller-runtime"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics on :8443 with TokenReview auth" "controller-runtime metrics"
            kustomizeRenderer = container "Kustomize Renderer" "Renders bundled /manifests/ directory with platform-specific parameters" "kustomize"
            platformVersionHandler = container "Platform Version Handler" "Implements version handshake protocol via odh-feastoperator-config ConfigMap" "Go"
        }

        rhoaiOperator = softwareSystem "RHOAI Platform Operator" "Manages RHOAI platform components and coordinates module upgrades" "Internal RHOAI"
        feastFeatureStore = softwareSystem "Feast Feature Store" "Feature store runtime (FeatureStore CR from feast.dev)" "Internal RHOAI"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Managed Jupyter notebook workbenches" "Internal RHOAI"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages Prometheus monitoring via ServiceMonitor CRDs" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "External Infrastructure"
        openshiftRouter = softwareSystem "OpenShift Router" "Manages Routes for external access" "External Infrastructure"
        sparkOperator = softwareSystem "Spark Operator" "Manages Spark applications on Kubernetes" "Internal RHOAI"

        # Relationships
        platformAdmin -> rhoaiOperator "Configures RHOAI platform"
        rhoaiOperator -> feastModuleOperator "Creates FeastOperator CR and platform version ConfigMap"
        dataScientist -> feastFeatureStore "Uses feature stores for ML training/serving"

        feastModuleOperator -> kubernetesAPI "CRUD operations on managed resources" "HTTPS/6443 TLS 1.2+"
        feastModuleOperator -> feastFeatureStore "Watches FeatureStore CRDs" "Kubernetes Watch API"
        feastModuleOperator -> kubeflowNotebooks "Watches Notebook CRDs" "Kubernetes Watch API"
        feastModuleOperator -> prometheusOperator "Creates ServiceMonitor resources" "Kubernetes API"
        feastModuleOperator -> openshiftRouter "Watches Route resources" "Kubernetes API"
        feastModuleOperator -> sparkOperator "Creates SparkApplication resources" "Kubernetes API"

        prometheusOperator -> feastModuleOperator "Scrapes /metrics via ServiceMonitor" "HTTPS/8443 TLS"

        # Container relationships
        controller -> kustomizeRenderer "Renders manifests for deployment"
        controller -> platformVersionHandler "Checks platform version before reconciliation"
        controller -> metricsServer "Registers custom metrics"
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
            element "External Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

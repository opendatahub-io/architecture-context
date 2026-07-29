workspace {
    model {
        platformAdmin = person "Platform Admin" "Configures ODH/RHOAI platform components"
        dataScientist = person "Data Scientist" "Creates and manages feature stores"

        feastModuleOperator = softwareSystem "Feast Module Operator" "ODH/RHOAI platform module operator that deploys and manages the upstream Feast operator for feature store lifecycle management" {
            cli = container "feast-module-operator CLI" "Cobra CLI with operator and chartgen subcommands" "Go CLI"
            controllerManager = container "feast-operator-controller-manager" "Reconciles FeastOperator CRs, deploys upstream Feast operator" "Go Operator"
            metricsService = container "Metrics Service" "Exposes Prometheus metrics on port 8443" "ClusterIP Service"
        }

        upstreamFeastOperator = softwareSystem "Upstream Feast Operator" "Manages FeatureStore CR lifecycle, deployed by feast-module-operator" "Managed"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        opendatahubOperator = softwareSystem "OpenDataHub Operator" "Platform operator providing common.PlatformObject interface" "Internal ODH"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages Prometheus monitoring resources" "Internal ODH"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook workbench management" "Internal ODH"
        openShift = softwareSystem "OpenShift" "Container platform providing Routes" "External"

        platformAdmin -> feastModuleOperator "Creates FeastOperator CR via kubectl"
        dataScientist -> upstreamFeastOperator "Creates FeatureStore CRs"

        feastModuleOperator -> kubernetesAPI "CRUD on Deployments, Services, RBAC, ConfigMaps" "HTTPS/6443 TLS 1.2+"
        feastModuleOperator -> upstreamFeastOperator "Deploys and manages lifecycle"
        feastModuleOperator -> prometheusOperator "Creates ServiceMonitors" "Kubernetes API"
        feastModuleOperator -> kubeflowNotebooks "Reads Notebook resources" "Kubernetes API"
        feastModuleOperator -> openShift "Manages Routes" "Kubernetes API"

        upstreamFeastOperator -> kubernetesAPI "Manages FeatureStore workloads" "HTTPS/6443"

        controllerManager -> metricsService "Serves metrics"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
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

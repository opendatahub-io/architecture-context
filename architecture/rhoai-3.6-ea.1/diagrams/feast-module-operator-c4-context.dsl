workspace {
    model {
        clusterAdmin = person "Cluster Admin" "Manages RHOAI platform components"

        feastModuleOperator = softwareSystem "Feast Module Operator" "Kubernetes operator managing Feast feature store deployments within RHOAI" {
            controller = container "FeastOperator Controller" "Reconciles FeastOperator CR, renders kustomize manifests, deploys Feast components" "Go / controller-runtime"
            metricsServer = container "Metrics Server" "Serves Prometheus metrics with RBAC auth" "HTTPS/8443"
            healthProbes = container "Health Probes" "Liveness and readiness endpoints" "HTTP/8081"
            configLoader = container "Viper Config" "Layered configuration: defaults, ConfigMap, env vars" "Go / Viper"
            reconcilerPipeline = container "ODH Reconciler Pipeline" "Kustomize render, ordered deploy, GC, status tracking" "opendatahub-operator/v2"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource operations" "External"
        feastUpstream = softwareSystem "Feast Feature Store" "Upstream Feast operator and FeatureStore CRDs" "Internal ODH"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook workbench management" "Internal ODH"
        prometheusOperator = softwareSystem "prometheus-operator" "Manages Prometheus monitoring resources" "Internal ODH"
        openshiftRoutes = softwareSystem "OpenShift Routes" "Route-based ingress for dashboard status" "External"
        odhOperator = softwareSystem "opendatahub-operator" "Platform operator providing reconciler framework" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"

        clusterAdmin -> feastModuleOperator "Creates/updates FeastOperator CR via kubectl"
        feastModuleOperator -> kubernetesAPI "Resource CRUD operations" "HTTPS/6443 TLS 1.2+"
        feastModuleOperator -> feastUpstream "Watches FeatureStore CRDs, deploys Feast components" "Kubernetes API"
        feastModuleOperator -> kubeflowNotebooks "Watches Notebook CRs for workbench awareness" "Kubernetes API"
        feastModuleOperator -> prometheusOperator "Creates/manages ServiceMonitors" "Kubernetes API"
        feastModuleOperator -> openshiftRoutes "Watches Routes for dashboard status" "Kubernetes API"
        prometheus -> feastModuleOperator "Scrapes metrics" "HTTPS/8443 RBAC Auth"

        controller -> reconcilerPipeline "Executes action pipeline"
        controller -> configLoader "Reads runtime configuration"
        reconcilerPipeline -> kubernetesAPI "Applies rendered manifests"
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
            element "Person" {
                shape Person
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

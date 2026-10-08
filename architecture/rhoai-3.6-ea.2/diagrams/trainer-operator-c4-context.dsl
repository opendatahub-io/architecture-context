workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components via Trainer CR"

        trainerOperator = softwareSystem "Trainer Operator" "Reconciles Trainer CR to deploy and manage upstream Kubeflow Trainer v2 on OpenShift AI" {
            controllerManager = container "trainer-operator-controller-manager" "Watches Trainer CR, renders manifests via kustomize, applies via SSA, manages lifecycle of upstream Trainer resources" "Go Operator (controller-runtime)"
            metricsServer = container "Metrics Server" "Serves Prometheus metrics with TLS and RBAC auth" "HTTPS 8443/TCP"
            manifestPipeline = container "Manifest Pipeline" "Copies upstream templates, applies RELATED_IMAGE overrides, renders via kustomize" "Kustomize"
        }

        kubeflowTrainer = softwareSystem "Kubeflow Trainer v2" "Upstream training orchestration — CRDs, controller, webhooks, ClusterTrainingRuntimes" "Managed by Operator"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        jobsetOperator = softwareSystem "JobSet Operator" "Manages JobSet CRDs, required dependency for training workloads" "OLM Managed"
        prometheusOperator = softwareSystem "prometheus-operator" "Manages ServiceMonitor for metrics scraping" "Internal ODH"
        odhPlatformOperator = softwareSystem "ODH Platform Operator" "Creates Trainer CR and platform config ConfigMap" "Internal ODH"
        odhPlatformUtilities = softwareSystem "odh-platform-utilities" "Go library: framework reconciler, condition manager, GC, SSA apply" "Internal ODH"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Provides cluster TLS profile and adherence policy" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes operator metrics via ServiceMonitor" "External"

        platformAdmin -> trainerOperator "Creates/updates Trainer CR (default-trainer)"
        trainerOperator -> kubernetesAPI "Watches, SSA apply, CRD CRUD, GC cleanup" "HTTPS/6443"
        trainerOperator -> kubeflowTrainer "Deploys CRDs, controller, webhooks, runtimes"
        trainerOperator -> jobsetOperator "Validates OLM installation, CR health, CRD availability" "HTTPS/6443"
        trainerOperator -> prometheusOperator "Creates ServiceMonitor" "HTTPS/6443"
        trainerOperator -> openshiftAPIServer "Reads TLS profile and adherence policy" "HTTPS/6443"
        trainerOperator -> odhPlatformUtilities "Uses framework reconciler, SSA apply, GC" "Go library"
        odhPlatformOperator -> trainerOperator "Creates Trainer CR, provides odh-trainer-config ConfigMap"
        prometheus -> trainerOperator "Scrapes /metrics" "HTTPS/8443"
    }

    views {
        systemContext trainerOperator "SystemContext" {
            include *
            autoLayout
        }

        container trainerOperator "Containers" {
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
            element "Managed by Operator" {
                background #f5a623
                color #ffffff
            }
            element "OLM Managed" {
                background #ffe6cc
                color #333333
            }
        }
    }
}

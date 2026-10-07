workspace {
    model {
        platformOperator = person "Platform Operator" "Enables/disables the Ray module via the platform operator"
        dataScientist = person "Data Scientist" "Creates Ray workloads (RayCluster, RayJob) from Notebooks"

        rayModuleOperator = softwareSystem "Ray Module Operator" "Manages the lifecycle of the KubeRay operator within the ODH/RHOAI modular architecture" {
            moduleController = container "ray-module-operator" "Reconciles the Ray CR to deploy, upgrade, and remove the KubeRay operand" "Go Operator (controller-runtime)"
            kuberayOperand = container "kuberay-operator" "Manages Ray distributed computing workloads (RayCluster, RayJob, RayService, RayCronJob)" "Go Operator (operand)"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for webhooks" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        gatewayAPI = softwareSystem "Gateway API" "Ingress management for Ray clusters" "External"
        openshiftRoutes = softwareSystem "OpenShift Routes" "Ray dashboard access routing" "External"
        platformOperatorSystem = softwareSystem "Platform Operator" "ODH/RHOAI platform lifecycle management" "Internal ODH"
        workbenches = softwareSystem "Workbenches (Notebooks)" "Jupyter notebooks for data science" "Internal ODH"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Shared framework for reconciliation, platform detection, manifests" "Internal ODH"

        platformOperator -> rayModuleOperator "Creates Ray CR 'default-ray' to enable module"
        dataScientist -> kuberayOperand "Creates RayCluster/RayJob via kubectl or Notebook"

        moduleController -> kubernetesAPI "CR watch, SSA apply, status updates" "HTTPS/6443"
        moduleController -> kuberayOperand "Deploys and manages lifecycle"
        kuberayOperand -> kubernetesAPI "Ray workload reconciliation" "HTTPS/6443"
        kuberayOperand -> gatewayAPI "Manages HTTPRoutes for Ray ingress" "Kubernetes API"
        kuberayOperand -> openshiftRoutes "Creates Routes for Ray dashboard" "Kubernetes API"

        moduleController -> certManager "Validates CRD availability before deploying" "Kubernetes API"
        prometheus -> kuberayOperand "Scrapes metrics" "HTTP/8080"
        workbenches -> rayModuleOperator "Binds ray ClusterRole for notebook SAs"
        moduleController -> platformOperatorSystem "Watches odh-ray-config ConfigMap" "Kubernetes API"
        moduleController -> odhPlatformUtils "Uses reconciliation framework" "Go library"
    }

    views {
        systemContext rayModuleOperator "SystemContext" {
            include *
            autoLayout
        }

        container rayModuleOperator "Containers" {
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
        }
    }
}

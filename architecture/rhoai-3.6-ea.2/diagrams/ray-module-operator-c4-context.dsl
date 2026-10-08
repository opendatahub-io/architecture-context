workspace {
    model {
        platformOperator = person "ODH Platform Operator" "Manages component lifecycle via component CRs"
        clusterAdmin = person "Cluster Admin" "Monitors operator metrics and health"
        datascientist = person "Data Scientist" "Uses Notebooks/Workbenches to submit Ray jobs"

        rayModuleOperator = softwareSystem "Ray Module Operator" "Module operator managing KubeRay operator lifecycle as part of ODH/RHOAI modular architecture" {
            controllerManager = container "ray-module-operator-controller-manager" "Reconciles Ray CR to deploy and manage KubeRay operand resources via server-side-apply" "Go Operator (controller-runtime)"
            vendoredManifests = container "KubeRay Operand Manifests" "Embedded kustomize manifests for KubeRay operator deployment" "Kustomize (/opt/manifests)"
        }

        kuberay = softwareSystem "KubeRay Operator" "Manages Ray cluster lifecycle (RayCluster, RayJob, RayService)" "Operand"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "Infrastructure"
        certManager = softwareSystem "cert-manager" "Certificate management for webhook TLS" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes networking gateway resources" "External"
        platformUtilities = softwareSystem "odh-platform-utilities" "Reconciler framework, action pipeline, kustomize rendering" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"

        platformOperator -> rayModuleOperator "Creates/manages Ray CR to enable/disable module" "HTTPS/6443"
        datascientist -> kuberay "Submits RayJobs via notebook ClusterRole" "kubectl/API"
        clusterAdmin -> rayModuleOperator "Scrapes metrics" "HTTPS/8443"

        controllerManager -> vendoredManifests "Reads and renders kustomize manifests"
        controllerManager -> k8sAPI "Reconcile Ray CR, SSA deploy KubeRay, manage RBAC/webhooks/CRDs" "HTTPS/6443"
        rayModuleOperator -> kuberay "Deploys via server-side-apply of vendored manifests" "HTTPS/6443"
        rayModuleOperator -> certManager "Validates Issuer and Certificate CRDs are available" "HTTPS/6443"
        rayModuleOperator -> gatewayAPI "Manages Gateway, HTTPRoute, ReferenceGrant resources" "HTTPS/6443"

        prometheus -> rayModuleOperator "Scrapes /metrics endpoint" "HTTPS/8443"
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
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Operand" {
                background #f5a623
                color #ffffff
            }
        }
    }
}

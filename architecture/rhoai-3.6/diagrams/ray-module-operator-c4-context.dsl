workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and enables/disables modules"
        dataSciUser = person "Data Scientist" "Creates and runs Ray distributed compute workloads"

        rayModuleOperator = softwareSystem "ray-module-operator" "Module operator that manages the lifecycle of the KubeRay operator as part of the ODH/RHOAI modular platform architecture" {
            controllerManager = container "Controller Manager" "Reconciles Ray CR and deploys KubeRay operand via kustomize rendering and server-side apply" "Go controller-runtime"
            healthProbes = container "Health Probes" "Liveness and readiness endpoints" "HTTP :8081"
            metricsServer = container "Metrics Server" "Prometheus metrics with authn/authz" "HTTPS :8443"
            reconciliationPipeline = container "Reconciliation Pipeline" "Linear action chain: mgmt-state, releases, manifest-init, kustomize-render, notebook-rbac, deploy, status, GC" "odh-platform-utilities framework"
        }

        kubeRayOperator = softwareSystem "KubeRay Operator" "Managed operand that provides ray.io CRDs and manages Ray clusters, jobs, and services" "Operand"

        platformOperator = softwareSystem "ODH/RHOAI Platform Operator" "Creates Ray CR when Ray module is enabled" "Internal Platform"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes networking resources" "External"
        kubeAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        workbenches = softwareSystem "Workbenches (Notebooks)" "Jupyter notebook environments for data scientists" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Relationships
        platformAdmin -> platformOperator "Enables Ray module"
        platformOperator -> rayModuleOperator "Creates Ray CR" "HTTPS/6443"
        rayModuleOperator -> kubeAPI "Reconciles CRs, SSA applies manifests, manages RBAC" "HTTPS/6443"
        rayModuleOperator -> kubeRayOperator "Deploys and manages lifecycle" "Server-Side Apply"
        rayModuleOperator -> certManager "Validates CRDs exist before deployment" "HTTPS/6443"
        rayModuleOperator -> gatewayAPI "Operand may include Gateway resources" "HTTPS/6443"
        rayModuleOperator -> workbenches "Creates ray ClusterRole for Notebook SA binding"
        dataSciUser -> kubeRayOperator "Creates RayCluster, RayJob via kubectl/UI"
        prometheus -> rayModuleOperator "Scrapes /metrics" "HTTPS/8443"

        # Internal relationships
        controllerManager -> reconciliationPipeline "Executes action chain"
        reconciliationPipeline -> controllerManager "Returns reconciliation result"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Operand" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
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

workspace {
    model {
        clusterAdmin = person "Cluster Administrator" "Manages RHOAI platform components"

        mcpLifecycleOp = softwareSystem "MCP Lifecycle Module Operator" "Manages lifecycle of MCP lifecycle operator operand via kustomize-rendered manifests with Server-Side Apply" {
            controllerManager = container "Controller Manager" "Watches MCPLifecycleOperator CR, renders and applies operand manifests, garbage-collects stale resources" "Go Operator (controller-runtime 0.24.1)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Provides cluster-level TLS configuration (min version, cipher suites)" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Manages Prometheus monitoring stack via ServiceMonitor CRDs" "Internal RHOAI"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Platform detection, manifest rendering, SSA deployment, and garbage collection helpers" "Internal RHOAI"

        clusterAdmin -> mcpLifecycleOp "Creates/manages MCPLifecycleOperator CR (singleton)" "kubectl"
        mcpLifecycleOp -> k8sAPI "Watches CRs, applies resources via SSA, garbage-collects stale resources" "HTTPS/6443, SA Token"
        mcpLifecycleOp -> openshiftAPIServer "Reads TLS configuration for operand" "HTTPS/6443, SA Token"
        mcpLifecycleOp -> prometheusOp "Creates ServiceMonitor resources" "CRD CRUD"
        controllerManager -> odhPlatformUtils "Uses Deployer, GC, labels, platform detection" "Go Library"
    }

    views {
        systemContext mcpLifecycleOp "SystemContext" {
            include *
            autoLayout
        }

        container mcpLifecycleOp "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
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

workspace {
    model {
        clusterAdmin = person "Cluster Admin" "Creates and manages MCPLifecycleOperator CR"

        mcpLifecycleModuleOperator = softwareSystem "mcp-lifecycle-module-operator" "Module operator managing the lifecycle of the mcp-lifecycle-operator operand" {
            manager = container "Manager Process" "controller-runtime operator entrypoint (/manager)" "Go"
            reconciler = container "MCPLifecycleOperator Reconciler" "Watches MCPLifecycleOperator CR and reconciles operand stack" "Go Controller"
            embeddedManifests = container "Embedded Manifest FS" "Go embedded filesystem containing operand YAML manifests" "Go embed"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External" {
            tags "External"
        }

        odhPlatformUtilities = softwareSystem "odh-platform-utilities" "Platform detection, manifest rendering, SSA deployer" "Internal Library" {
            tags "Internal"
        }

        prometheusOperator = softwareSystem "prometheus-operator" "Manages Prometheus monitoring stack" "External" {
            tags "External"
        }

        mcpLifecycleOperator = softwareSystem "mcp-lifecycle-operator" "Child operator managing MCPServer resources (deployed operand)" "Internal Operand" {
            tags "Operand"
        }

        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Platform-level TLS configuration" "External" {
            tags "External"
        }

        clusterAdmin -> mcpLifecycleModuleOperator "Creates MCPLifecycleOperator CR" "kubectl/oc"
        mcpLifecycleModuleOperator -> kubernetesAPI "Watches CRs, applies resources via SSA" "HTTPS/6443, TLS 1.2+"
        mcpLifecycleModuleOperator -> odhPlatformUtilities "Uses for manifest rendering and deployment" "Go library"
        mcpLifecycleModuleOperator -> mcpLifecycleOperator "Deploys and manages lifecycle" "Server-Side Apply"
        mcpLifecycleModuleOperator -> prometheusOperator "Creates ServiceMonitor CRs" "HTTPS, TLS 1.2+"
        mcpLifecycleModuleOperator -> openshiftAPIServer "Watches for TLS config changes" "Kubernetes API"
    }

    views {
        systemContext mcpLifecycleModuleOperator "SystemContext" {
            include *
            autoLayout
        }

        container mcpLifecycleModuleOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #9b59b6
                color #ffffff
            }
            element "Operand" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
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

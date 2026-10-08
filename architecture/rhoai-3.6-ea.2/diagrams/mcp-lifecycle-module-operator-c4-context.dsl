workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages ODH/RHOAI platform installation and configuration"

        mcpLifecycleModuleOperator = softwareSystem "mcp-lifecycle-module-operator" "Module operator that manages the lifecycle of the MCP Lifecycle Operator as a deployable ODH/RHOAI component" {
            reconciler = container "Reconciler" "Watches MCPLifecycleOperator CR and manages operand lifecycle" "Go (controller-runtime)"
            tlsResolver = container "TLS Profile Resolver" "Reads cluster TLS profile from OpenShift APIServer CR" "Go (library-go)"
            manifestRenderer = container "Manifest Renderer" "Loads and transforms embedded kustomize manifests" "Go (manifestival)"
            ssaDeployer = container "SSA Deployer" "Applies operand resources via Server-Side Apply" "Go (odh-platform-utilities)"
        }

        odhPlatformOperator = softwareSystem "ODH Platform Operator" "Creates MCPLifecycleOperator CR to trigger module deployment" "Internal ODH"
        mcpLifecycleOperator = softwareSystem "MCP Lifecycle Operator" "Operand that manages MCPServer resources (Model Context Protocol)" "Deployed Operand"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Cluster-wide TLS configuration source" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics monitoring via ServiceMonitor CRD" "External"

        odhPlatformOperator -> mcpLifecycleModuleOperator "Creates MCPLifecycleOperator CR" "HTTPS/6443"
        mcpLifecycleModuleOperator -> kubernetesAPI "Watches CRs, SSA deploys, GC, discovery" "HTTPS/6443"
        mcpLifecycleModuleOperator -> openshiftAPIServer "Reads cluster TLS profile" "HTTPS/6443"
        mcpLifecycleModuleOperator -> mcpLifecycleOperator "Deploys and manages operand lifecycle" "SSA"
        prometheusOperator -> mcpLifecycleOperator "Scrapes metrics via ServiceMonitor" "HTTPS/8443"

        reconciler -> tlsResolver "Requests TLS configuration"
        reconciler -> manifestRenderer "Triggers manifest rendering"
        manifestRenderer -> ssaDeployer "Passes transformed manifests"
        ssaDeployer -> kubernetesAPI "Server-Side Apply" "HTTPS/6443"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Deployed Operand" {
                background #f5a623
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

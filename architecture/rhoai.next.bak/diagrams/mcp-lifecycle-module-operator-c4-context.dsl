workspace {
    model {
        platformAdmin = person "Platform Admin" "Configures RHOAI platform components via the ODH operator"

        mcpLifecycleModuleOperator = softwareSystem "MCP Lifecycle Module Operator" "Thin lifecycle management layer that deploys and manages the MCP Lifecycle Operator operand via Server-Side Apply (SSA)" {
            reconciler = container "MCPLifecycleOperatorReconciler" "Watches MCPLifecycleOperator CRs, renders manifests, applies via SSA, garbage-collects stale resources, checks operand readiness" "Go controller-runtime"
            kustomizeProvider = container "KustomizeProvider" "Loads pre-rendered operand YAML from embedded filesystem, patches namespace/image/labels via manifestival transformers" "Go manifestival"
            conditionsManager = container "ConditionsManager" "Manages standard ODH platform conditions (Ready, ProvisioningSucceeded, Degraded, MCPLifecycleOperatorAvailable)" "Go"
        }

        odhPlatformOperator = softwareSystem "ODH Platform Operator" "Creates and manages MCPLifecycleOperator CR to trigger operand deployment" "Internal ODH"
        mcpLifecycleOperator = softwareSystem "MCP Lifecycle Operator (Operand)" "Manages MCPServer CRDs for running Model Context Protocol servers in Kubernetes" "Internal ODH"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource CRUD operations" "External"

        # Library dependencies (compile-time)
        controllerRuntime = softwareSystem "controller-runtime" "Kubernetes controller framework v0.24.1" "External Library"
        manifestival = softwareSystem "manifestival" "YAML manifest loading and transformation v0.7.2" "External Library"
        odhPlatformUtilities = softwareSystem "odh-platform-utilities" "SSA deployer, garbage collector, label utilities, platform API types v0.1.0" "Internal ODH Library"

        # Relationships
        platformAdmin -> odhPlatformOperator "Configures platform components"
        odhPlatformOperator -> mcpLifecycleModuleOperator "Creates MCPLifecycleOperator CR" "Kubernetes API / HTTPS 443"
        mcpLifecycleModuleOperator -> kubernetesAPI "SSA Apply, Garbage Collect, Status Patch, RBAC management" "HTTPS/443, TLS 1.2+, ServiceAccount token"
        mcpLifecycleModuleOperator -> mcpLifecycleOperator "Deploys and manages operand via embedded manifests" "SSA via Kubernetes API"

        # Internal container relationships
        reconciler -> kustomizeProvider "Loads rendered manifests"
        reconciler -> conditionsManager "Updates CR status conditions"
        reconciler -> kubernetesAPI "SSA Apply, Watch, List, Delete" "HTTPS/443"
    }

    views {
        systemContext mcpLifecycleModuleOperator "SystemContext" {
            include *
            exclude controllerRuntime manifestival odhPlatformUtilities
            autoLayout
        }

        container mcpLifecycleModuleOperator "Containers" {
            include *
            exclude controllerRuntime manifestival odhPlatformUtilities
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Library" {
                background #cccccc
                color #333333
            }
            element "Internal ODH" {
                background #7ed321
                color #333333
            }
            element "Internal ODH Library" {
                background #a8e063
                color #333333
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #3a7bd5
                color #ffffff
            }
        }
    }
}

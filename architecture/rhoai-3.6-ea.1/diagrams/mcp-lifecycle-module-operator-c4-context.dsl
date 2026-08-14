workspace {
    model {
        clusterAdmin = person "Cluster Admin" "Creates MCPLifecycleOperator CR to enable MCP server management"
        dataScientist = person "Data Scientist" "Creates MCPServer CRs to deploy Model Context Protocol servers"

        mcpLifecycleModuleOperator = softwareSystem "MCP Lifecycle Module Operator" "Controller-runtime operator that manages the lifecycle of the MCP Lifecycle Operator operand via server-side apply" {
            reconciler = container "MCPLifecycleOperatorReconciler" "Watches MCPLifecycleOperator CR and reconciles operand resources" "Go controller-runtime"
            kustomizeProvider = container "KustomizeProvider" "Renders operand manifests from embedded filesystem" "manifests.NewKustomizeProvider"
            ssaDeployer = container "SSA Deployer" "Applies rendered manifests via server-side apply with ordered sequencing" "odh-platform-utilities deploy.NewDeployer"
        }

        mcpLifecycleOperator = softwareSystem "MCP Lifecycle Operator" "Operand that manages MCPServer custom resources for Model Context Protocol server lifecycle" {
            operandController = container "MCPServer Controller" "Watches and reconciles MCPServer CRs in user namespaces" "Go controller-runtime"
            metricsServer = container "Metrics Server" "Exposes /metrics on port 8443 with TokenReview/SAR auth" "controller-runtime metrics"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource management" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages ServiceMonitor resources for metrics collection" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Scrapes metrics from operator endpoints" "Internal RHOAI"
        odhPlatformUtilities = softwareSystem "ODH Platform Utilities" "Shared Go library for platform detection, manifest rendering, and deployment" "Internal RHOAI"

        # Relationships
        clusterAdmin -> mcpLifecycleModuleOperator "Creates MCPLifecycleOperator CR" "kubectl / RHOAI Operator"
        dataScientist -> mcpLifecycleOperator "Creates MCPServer CRs" "kubectl / Dashboard"

        mcpLifecycleModuleOperator -> kubernetesAPI "Watches CRs, applies resources via SSA" "HTTPS/6443, SA token"
        mcpLifecycleModuleOperator -> mcpLifecycleOperator "Deploys and monitors operand" "SSA via Kubernetes API"

        mcpLifecycleOperator -> kubernetesAPI "Watches MCPServer CRs, manages resources" "HTTPS/6443, SA token"
        prometheus -> mcpLifecycleOperator "Scrapes /metrics" "HTTPS/8443, TokenReview auth"
        mcpLifecycleModuleOperator -> prometheusOperator "Creates ServiceMonitor" "Kubernetes API"

        # Internal container relationships
        reconciler -> kustomizeProvider "Requests rendered manifests"
        kustomizeProvider -> ssaDeployer "Passes rendered manifests"
        ssaDeployer -> kubernetesAPI "Server-side apply with field ownership" "HTTPS/6443"
    }

    views {
        systemContext mcpLifecycleModuleOperator "SystemContext" {
            include *
            autoLayout
        }

        container mcpLifecycleModuleOperator "ModuleOperatorContainers" {
            include *
            autoLayout
        }

        container mcpLifecycleOperator "OperandContainers" {
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
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
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

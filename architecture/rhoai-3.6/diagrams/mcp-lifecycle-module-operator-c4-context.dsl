workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages RHOAI platform lifecycle"
        endUser = person "End User" "Creates MCPServer resources for MCP server management"

        mcpModuleOperator = softwareSystem "MCP Lifecycle Module Operator" "Module operator that manages the lifecycle of the MCP Lifecycle Operator operand within the ODH/RHOAI modular platform" {
            reconciler = container "MCPLifecycleOperator Reconciler" "Reconciles MCPLifecycleOperator CR to deploy operand" "Go (controller-runtime)"
            manifestRenderer = container "Manifest Renderer" "Renders operand manifests via kustomize + embed.FS" "Go"
            ssaDeployer = container "SSA Deployer" "Applies operand manifests via server-side apply" "Go"
            conversionChecker = container "Conversion Health Checker" "Validates MCPServer objects are convertible to v1beta1" "Go"
            gatewayDiscovery = container "Gateway Discovery" "Dynamically discovers MCPGatewayExtension and Gateway CRDs" "Go"
            storageMigration = container "Storage Version Migration" "Drives MCPServer storage version migration to v1beta1" "Go"
        }

        mcpLifecycleOperator = softwareSystem "MCP Lifecycle Operator" "Operand that manages MCPServer and MCPGatewayBinding lifecycle" "Operand"

        odhPlatformOperator = softwareSystem "ODH Platform Operator" "Creates MCPLifecycleOperator CR to trigger module operator" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Provisions TLS certificates for operand webhook" "External"
        gatewayAPI = softwareSystem "Gateway API" "Provides Gateway and HTTPRoute for MCP server ingress" "External"
        kuadrantMCPGateway = softwareSystem "Kuadrant MCP Gateway" "MCP gateway extension for server registration" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Metrics collection via ServiceMonitor" "External"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Provides cluster TLS profile configuration" "External"
        storageVersionMigrator = softwareSystem "Storage Version Migrator" "Migrates stored MCPServer objects to v1beta1" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for all resource operations" "External"
        odhPlatformUtilities = softwareSystem "odh-platform-utilities" "Shared Go library for platform detection, SSA, GC" "Internal RHOAI"

        # Relationships
        platformAdmin -> odhPlatformOperator "Configures platform via DSCInitialization/DataScienceCluster"
        odhPlatformOperator -> mcpModuleOperator "Creates MCPLifecycleOperator CR" "HTTPS/6443"
        mcpModuleOperator -> mcpLifecycleOperator "Deploys and manages via SSA" "HTTPS/6443"
        mcpModuleOperator -> kubernetesAPI "Resource CRUD, watches, leader election" "HTTPS/6443"
        mcpModuleOperator -> openshiftAPIServer "Reads TLS profile" "HTTPS/6443"
        mcpModuleOperator -> certManager "Creates Certificate CRs for webhook TLS" "HTTPS/6443"
        mcpModuleOperator -> gatewayAPI "Discovers Gateway/HTTPRoute resources" "HTTPS/6443"
        mcpModuleOperator -> kuadrantMCPGateway "Discovers MCPGatewayExtension CRs" "HTTPS/6443"
        mcpModuleOperator -> prometheusOperator "Creates ServiceMonitor for operand metrics" "HTTPS/6443"
        mcpModuleOperator -> storageVersionMigrator "Creates StorageVersionMigration for MCPServer" "HTTPS/6443"
        mcpModuleOperator -> odhPlatformUtilities "Uses for manifest rendering, SSA, GC" "Go library"
        endUser -> mcpLifecycleOperator "Creates MCPServer/MCPGatewayBinding resources" "kubectl"

        # Internal container relationships
        reconciler -> manifestRenderer "Renders operand manifests"
        reconciler -> ssaDeployer "Applies manifests"
        reconciler -> conversionChecker "Validates conversion health"
        reconciler -> gatewayDiscovery "Discovers gateway CRDs"
        reconciler -> storageMigration "Triggers storage migration"
    }

    views {
        systemContext mcpModuleOperator "SystemContext" {
            include *
            autoLayout
        }

        container mcpModuleOperator "Containers" {
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
            element "Operand" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

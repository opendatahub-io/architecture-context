workspace {
    model {
        platformAdmin = person "Platform Administrator" "Manages RHOAI platform installation and upgrades"
        dataScientist = person "Data Scientist / Developer" "Creates MCPServer resources to deploy MCP servers"

        mcpModuleOp = softwareSystem "MCP Lifecycle Module Operator" "Module operator that manages the lifecycle of the MCP Lifecycle Operator operand via MCPLifecycleOperator CR" {
            controller = container "Module Operator Controller" "Watches MCPLifecycleOperator CR and reconciles operand deployment" "Go (controller-runtime)"
            manifestRenderer = container "Manifest Renderer" "Loads and transforms embedded kustomize manifests with TLS, image, and network policy overrides" "Go (manifestival)"
            ssaDeployer = container "SSA Deployer" "Applies operand resources via server-side apply and garbage collects stale resources" "Go (odh-platform-utilities)"
            conversionChecker = container "Conversion Health Checker" "Validates MCPServer convertibility from v1alpha1 to v1beta1 via dynamic LIST" "Go (dynamic client)"
            migrationDriver = container "Storage Migration Driver" "Creates StorageVersionMigration to re-encode MCPServer objects; bounded retry (5 attempts)" "Go"
            tlsResolver = container "TLS Config Resolver" "Fetches OpenShift APIServer TLS profile; defaults to Intermediate (TLS 1.2)" "Go (openshift/controller-runtime-common)"
        }

        mcpLifecycleOp = softwareSystem "MCP Lifecycle Operator" "Manages MCPServer and MCPGatewayBinding resources (operand deployed by module operator)" "Operand"

        odhPlatformOp = softwareSystem "ODH Platform Operator" "Creates MCPLifecycleOperator CR, reads status.releases for upgrade tracking" "Internal Platform"
        certManager = softwareSystem "cert-manager" "Provisions and auto-rotates TLS certificates for operand webhook" "Internal Platform"
        gatewayAPI = softwareSystem "Gateway API" "Provides HTTPRoute and Gateway CRDs for traffic management" "Internal Platform"
        prometheusOp = softwareSystem "prometheus-operator" "Scrapes operand metrics via ServiceMonitor" "Internal Platform"
        kubeStorageMigrator = softwareSystem "kube-storage-version-migrator" "Re-encodes stored API objects to latest storage version" "Internal Platform"
        kuadrant = softwareSystem "Kuadrant MCP Extensions" "MCPGatewayExtensions and MCPServerRegistrations for gateway integration" "Internal Platform"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Provides cluster-level TLS profile configuration" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"

        # Relationships
        platformAdmin -> odhPlatformOp "Installs/upgrades RHOAI platform"
        odhPlatformOp -> mcpModuleOp "Creates MCPLifecycleOperator CR" "Kubernetes API/HTTPS"
        mcpModuleOp -> odhPlatformOp "Reports status.releases for upgrade tracking" "Kubernetes API/HTTPS"

        dataScientist -> mcpLifecycleOp "Creates MCPServer resources via kubectl" "Kubernetes API/HTTPS"

        controller -> manifestRenderer "Renders operand manifests"
        controller -> tlsResolver "Fetches TLS configuration"
        manifestRenderer -> ssaDeployer "Applies rendered manifests"
        controller -> conversionChecker "Validates MCPServer conversion"
        controller -> migrationDriver "Drives storage version migration"

        mcpModuleOp -> kubernetesAPI "CRUD resources, SSA apply, dynamic list" "HTTPS/6443"
        mcpModuleOp -> mcpLifecycleOp "Deploys and manages operand" "Kubernetes API/HTTPS"
        mcpModuleOp -> openshiftAPIServer "Reads TLS profile" "HTTPS/6443"
        mcpModuleOp -> certManager "Applies Certificate and Issuer CRs" "Kubernetes API/HTTPS"
        mcpModuleOp -> prometheusOp "Applies ServiceMonitor" "Kubernetes API/HTTPS"
        mcpModuleOp -> kubeStorageMigrator "Creates StorageVersionMigration CR" "Kubernetes API/HTTPS"

        mcpLifecycleOp -> gatewayAPI "Manages HTTPRoutes" "Kubernetes API/HTTPS"
        mcpLifecycleOp -> kuadrant "Watches MCPGatewayExtensions, manages MCPServerRegistrations" "Kubernetes API/HTTPS"
        mcpLifecycleOp -> kubernetesAPI "Manages MCPServer, MCPGatewayBinding" "HTTPS/6443"
    }

    views {
        systemContext mcpModuleOp "SystemContext" {
            include *
            autoLayout
        }

        container mcpModuleOp "Containers" {
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
                background #50c878
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

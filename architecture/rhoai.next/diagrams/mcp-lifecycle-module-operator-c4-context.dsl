workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components"
        dataScientist = person "Data Scientist" "Creates MCPServer instances for MCP protocol endpoints"

        mcpLifecycleModuleOp = softwareSystem "MCP Lifecycle Module Operator" "Manages the lifecycle of the MCP Lifecycle Operator operand as a component within the ODH/RHOAI platform" {
            controller = container "Module Operator Controller" "Reconciles MCPLifecycleOperator CR, renders and applies operand manifests via SSA" "Go (controller-runtime)"
            embeddedManifests = container "Embedded Manifests" "Pre-rendered kustomize manifests for the MCP Lifecycle Operator operand" "go:embed YAML"
            kustomizeProvider = container "KustomizeProvider" "Applies runtime transformations: namespace, image, labels, TLS env vars" "Go (manifestival)"
        }

        odhPlatformOperator = softwareSystem "ODH Platform Operator" "Creates and manages MCPLifecycleOperator CR" "Internal Platform"
        mcpLifecycleOperator = softwareSystem "MCP Lifecycle Operator" "Operand that manages MCPServer CRs for Model Context Protocol servers" "Internal Platform"
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "Infrastructure"
        openshiftApiServer = softwareSystem "OpenShift APIServer" "Provides cluster-wide TLS profile configuration" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"

        # Relationships
        odhPlatformOperator -> mcpLifecycleModuleOp "Creates MCPLifecycleOperator CR" "Kubernetes CRD"
        mcpLifecycleModuleOp -> k8sApi "Watches CRs, applies resources via SSA, patches status" "HTTPS/443, SA Token"
        mcpLifecycleModuleOp -> openshiftApiServer "Reads cluster TLS profile" "HTTPS/443, SA Token"
        mcpLifecycleModuleOp -> mcpLifecycleOperator "Deploys and manages operand lifecycle" "SSA (Deployment, RBAC, CRD, Service, NetworkPolicy)"
        prometheus -> mcpLifecycleModuleOp "Scrapes metrics" "HTTPS/8443, Bearer Token"
        mcpLifecycleOperator -> k8sApi "Manages MCPServer CRs" "HTTPS/443, SA Token"
        dataScientist -> mcpLifecycleOperator "Creates MCPServer instances via kubectl" "Kubernetes API"
        platformAdmin -> odhPlatformOperator "Configures platform components" "Kubernetes API"

        # Internal container relationships
        controller -> embeddedManifests "Reads pre-rendered operand manifests"
        controller -> kustomizeProvider "Delegates manifest transformation"
        kustomizeProvider -> embeddedManifests "Transforms embedded manifests"
    }

    views {
        systemContext mcpLifecycleModuleOp "SystemContext" {
            include *
            autoLayout
        }

        container mcpLifecycleModuleOp "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

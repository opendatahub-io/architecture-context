workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages ODH/RHOAI platform deployment and configuration"

        mcpModuleOperator = softwareSystem "MCP Lifecycle Module Operator" "Manages the lifecycle of the MCP Lifecycle Operator as a deployable module within the ODH/RHOAI platform" {
            reconciler = container "Reconciler" "Watches MCPLifecycleOperator CR and reconciles operand state" "Go (controller-runtime)"
            tlsReader = container "TLS Profile Reader" "Reads OpenShift APIServer CR for cluster TLS configuration" "Go"
            manifestProvider = container "Manifest Provider" "Renders and transforms embedded operand manifests" "Go (manifestival)"
            garbageCollector = container "Garbage Collector" "Discovers and removes stale operand resources" "Go (odh-platform-utilities)"
            embeddedManifests = container "Embedded Manifests" "Pre-rendered operand install manifest (2167 lines, go:embed)" "YAML"

            reconciler -> tlsReader "Reads TLS config"
            reconciler -> manifestProvider "Renders manifests"
            reconciler -> garbageCollector "Triggers cleanup"
            manifestProvider -> embeddedManifests "Loads manifest YAML"
        }

        odhPlatformOperator = softwareSystem "ODH Platform Operator" "Platform operator (odh-operator / rhods-operator) that manages all ODH/RHOAI modules" "Internal Platform"
        mcpLifecycleOperator = softwareSystem "MCP Lifecycle Operator" "Operand that manages MCPServer custom resources for running MCP servers in Kubernetes" "Internal Platform"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for all resource operations" "Infrastructure"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Provides cluster-wide TLS profile configuration (config.openshift.io)" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring via ServiceMonitor" "Infrastructure"

        # Relationships
        odhPlatformOperator -> mcpModuleOperator "Creates MCPLifecycleOperator CR to trigger deployment" "HTTPS/443, TLS 1.2+, SA Token"
        mcpModuleOperator -> kubernetesAPI "CRUD on CRDs, Deployments, RBAC, Services, NetworkPolicies" "HTTPS/443, TLS 1.2+, SA Token"
        mcpModuleOperator -> openshiftAPIServer "Reads cluster TLS profile" "HTTPS/443, TLS 1.2+, SA Token"
        mcpModuleOperator -> mcpLifecycleOperator "Deploys and manages via SSA (Server-Side Apply)" "HTTPS/443, TLS 1.2+, SA Token"
        prometheus -> mcpLifecycleOperator "Scrapes /metrics endpoint" "HTTPS/8443, Bearer Token"
        mcpLifecycleOperator -> kubernetesAPI "Manages MCPServer custom resources" "HTTPS/443, TLS 1.2+, SA Token"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Person" {
                background #9b59b6
                color #ffffff
                shape person
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

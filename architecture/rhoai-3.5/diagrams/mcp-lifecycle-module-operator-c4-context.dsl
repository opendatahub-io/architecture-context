workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages ODH/RHOAI platform configuration"

        mcpLifecycleModuleOp = softwareSystem "MCP Lifecycle Module Operator" "Manages lifecycle of MCP Lifecycle Operator operand via SSA; follows ODH v2 modular architecture pattern" {
            controller = container "Module Operator Controller" "Reconciles MCPLifecycleOperator CR, renders kustomize manifests, applies via SSA, garbage-collects stale resources, monitors operand readiness" "Go (controller-runtime v0.24.1)"
            kustomizeProvider = container "KustomizeProvider" "Loads embedded operand manifests, applies namespace/image/label/TLS transformations" "Go (manifestival v0.7.2)"
            tlsReader = container "TLS Config Reader" "Reads OpenShift APIServer TLS profile, converts OpenSSL to IANA cipher names" "Go (library-go)"
            garbageCollector = container "Garbage Collector" "Deletes labeled resources not in current desired set" "Go (odh-platform-utilities)"
        }

        mcpLifecycleOp = softwareSystem "MCP Lifecycle Operator" "Manages MCPServer resources; deployed as operand by the module operator" {
            operandController = container "Operand Controller" "Reconciles MCPServer CRDs" "Go Operator"
            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus metrics on 8443/TCP HTTPS" "Go HTTP Server"
        }

        odhPlatformOp = softwareSystem "ODH Platform Operator" "Creates MCPLifecycleOperator CR to trigger module operator reconciliation" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes API for resource management" "Infrastructure"
        openshiftAPI = softwareSystem "OpenShift APIServer" "Cluster configuration including TLS profiles" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"

        # Relationships
        platformAdmin -> odhPlatformOp "Configures platform components"
        odhPlatformOp -> k8sAPI "Creates MCPLifecycleOperator CR" "HTTPS/443"
        k8sAPI -> mcpLifecycleModuleOp "Delivers watch events" "HTTPS/443"

        mcpLifecycleModuleOp -> k8sAPI "SSA apply operand resources, garbage collection, status updates" "HTTPS/443"
        mcpLifecycleModuleOp -> openshiftAPI "Reads cluster TLS profile" "HTTPS/443"
        mcpLifecycleModuleOp -> mcpLifecycleOp "Deploys and manages lifecycle via SSA" "Kubernetes API"

        prometheus -> mcpLifecycleOp "Scrapes metrics via ServiceMonitor" "HTTPS/8443"
        mcpLifecycleOp -> k8sAPI "Manages MCPServer resources" "HTTPS/443"

        # Container-level relationships
        controller -> kustomizeProvider "Requests manifest rendering"
        controller -> tlsReader "Requests TLS configuration"
        controller -> garbageCollector "Triggers stale resource cleanup"
        kustomizeProvider -> k8sAPI "SSA apply transformed manifests" "HTTPS/443"
        tlsReader -> openshiftAPI "GET apiservers resource" "HTTPS/443"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        user = person "Platform User" "Creates MCPServer custom resources to deploy MCP-compliant servers"
        admin = person "Platform Admin" "Manages the operator deployment and monitors metrics"

        mcpLifecycleOperator = softwareSystem "MCP Lifecycle Operator" "Declarative API to deploy, manage, and safely roll out MCP Servers with production-grade automation" {
            controller = container "MCPServer Controller" "Reconciles MCPServer CRs into Deployments, Services, and NetworkPolicies" "Go (controller-runtime v0.24.1)"
            validator = container "Validation Phase" "Validates MCPServer spec (image, port, container names, volume mounts, referenced resources)" "Go"
            handshakeVerifier = container "MCP Handshake Verifier" "Performs MCP protocol initialize handshake to verify server capabilities" "Go (modelcontextprotocol/go-sdk v1.6.1)"
            configHashComputer = container "Config Hash Computer" "Computes SHA-256 of referenced ConfigMaps/Secrets for rolling update annotations" "Go"
            ownershipManager = container "Ownership Manager" "Validates ownership, handles cross-UID adoption on MCPServer recreation" "Go"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics (reconcile_phase_duration, condition_info, validation_failures)" "Go (prometheus/client_golang v1.23.2)" "8443/TCP HTTPS"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster control plane providing resource CRUD and watch APIs" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring platform" "External"
        mcpServers = softwareSystem "MCP Server Containers" "User-provided containers implementing the Model Context Protocol" "External"

        # User interactions
        user -> mcpLifecycleOperator "Creates/updates MCPServer CRs via kubectl" "HTTPS/443"
        admin -> prometheus "Monitors operator reconciliation health" "HTTPS"

        # Internal container relationships
        controller -> validator "Invokes validation phase"
        controller -> handshakeVerifier "Invokes MCP handshake after deployment available"
        controller -> configHashComputer "Computes config hash for rolling updates"
        controller -> ownershipManager "Validates resource ownership before updates"

        # External relationships
        controller -> k8sApiServer "CRUD: Deployments, Services, NetworkPolicies, ConfigMaps, Secrets, Pods, MCPServers" "HTTPS/443, SA Token"
        handshakeVerifier -> mcpServers "MCP initialize handshake (Streamable HTTP)" "HTTP/{port}"
        prometheus -> metricsServer "Scrapes metrics" "HTTPS/8443, Bearer Token"
        k8sApiServer -> controller "Watch events for MCPServer CRs, ConfigMaps, Secrets" "HTTP/2 long-poll, TLS 1.2+"
    }

    views {
        systemContext mcpLifecycleOperator "SystemContext" {
            include *
            autoLayout
            description "MCP Lifecycle Operator in the Kubernetes ecosystem"
        }

        container mcpLifecycleOperator "Containers" {
            include *
            autoLayout
            description "Internal structure of the MCP Lifecycle Operator"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

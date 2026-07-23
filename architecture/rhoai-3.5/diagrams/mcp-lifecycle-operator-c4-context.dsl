workspace {
    model {
        user = person "Platform User / Data Scientist" "Creates MCPServer custom resources to deploy MCP servers"
        clusterAdmin = person "Cluster Admin" "Manages operator deployment and RBAC bindings"

        mcpLifecycleOperator = softwareSystem "MCP Lifecycle Operator" "Kubernetes operator that manages the full lifecycle of Model Context Protocol (MCP) servers with protocol-aware validation" {
            controller = container "MCP Lifecycle Operator Controller" "Reconciles MCPServer CRs into Deployments, Services, and NetworkPolicies; performs MCP protocol handshake" "Go (controller-runtime v0.24.1)"
            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus metrics via HTTPS with Bearer Token auth" "HTTPS/8443"
            healthProbes = container "Health Probes" "Liveness (/healthz) and readiness (/readyz) endpoints" "HTTP/8081"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster API for managing Kubernetes resources" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring platform" "External"
        mcpServer = softwareSystem "MCP Server" "User-deployed Model Context Protocol server (managed by operator)" "Managed"
        certManager = softwareSystem "cert-manager" "TLS certificate management (optional)" "External"

        # Relationships
        user -> mcpLifecycleOperator "Creates MCPServer CRs via kubectl"
        clusterAdmin -> mcpLifecycleOperator "Deploys operator, configures RBAC"

        controller -> k8sApiServer "CRUD Deployments, Services, NetworkPolicies; Watch MCPServer/ConfigMap/Secret" "HTTPS/443, SA Token"
        controller -> mcpServer "MCP protocol handshake (initialize)" "HTTP/{port}, MCP Streamable HTTP"
        prometheus -> metricsEndpoint "Scrapes /metrics" "HTTPS/8443, Bearer Token"

        mcpLifecycleOperator -> certManager "Optional TLS cert provisioning" "HTTPS"
    }

    views {
        systemContext mcpLifecycleOperator "SystemContext" {
            include *
            autoLayout
        }

        container mcpLifecycleOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Managed" {
                background #7ed321
                color #000000
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

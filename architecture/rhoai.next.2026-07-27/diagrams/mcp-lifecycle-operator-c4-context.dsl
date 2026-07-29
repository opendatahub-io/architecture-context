workspace {
    model {
        platformAdmin = person "Platform Admin" "Creates and manages MCPServer custom resources"

        mcpLifecycleOperator = softwareSystem "mcp-lifecycle-operator" "Kubernetes operator managing MCP server lifecycle via MCPServer CRs" {
            controllerManager = container "Controller Manager" "Reconciles MCPServer CRs into Deployments, Services, and NetworkPolicies" "Go / controller-runtime v0.24.1"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics on :8443 with TokenReview/SAR auth" "HTTPS / self-signed TLS"
            healthProbes = container "Health Probes" "Liveness and readiness endpoints on :8081" "HTTP"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        managedMCPServer = softwareSystem "Managed MCP Server" "User-specified MCP server container managed by the operator" "Managed"

        platformAdmin -> mcpLifecycleOperator "Creates MCPServer CRs via kubectl" "kubectl / Kubernetes API"
        mcpLifecycleOperator -> k8sAPI "Watches MCPServer CRs, manages Deployments/Services/NetworkPolicies" "HTTPS/WSS :6443, TLS 1.2+, ServiceAccount Token"
        mcpLifecycleOperator -> managedMCPServer "Creates and manages lifecycle" "ownerReferences"
        prometheus -> mcpLifecycleOperator "Scrapes metrics" "HTTPS :8443, TokenReview + SAR"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Managed" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

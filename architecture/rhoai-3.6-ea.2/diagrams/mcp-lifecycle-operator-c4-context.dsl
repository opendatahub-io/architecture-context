workspace {
    model {
        platformUser = person "Platform User" "Creates MCPServer custom resources to deploy MCP servers"

        mcpLifecycleOperator = softwareSystem "mcp-lifecycle-operator" "Kubernetes operator providing declarative API to deploy, manage, and safely roll out MCP servers with production-grade lifecycle automation" {
            controllerManager = container "Controller Manager" "Runs the operator binary with leader election, secure metrics, and health probes" "Go (controller-runtime v0.24.1)"
            reconciler = container "MCPServerReconciler" "Single controller reconciling MCPServer CRs; manages Deployments, Services, and NetworkPolicies" "Go Operator"
            tlsConfig = container "TLS Config" "Parses TLS_MIN_VERSION and TLS_CIPHER_SUITES from environment; validates against Go cipher suite registry" "Go"
            metricsServer = container "Metrics Server" "Serves Prometheus metrics over HTTPS with TokenReview + SubjectAccessReview auth" "controller-runtime"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Control plane API server for cluster operations" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring system that scrapes operator metrics" "External"
        mcpServers = softwareSystem "Managed MCP Servers" "User-deployed MCP server instances managed by the operator" "Managed"

        platformUser -> mcpLifecycleOperator "Creates MCPServer CR via kubectl/API"
        mcpLifecycleOperator -> kubernetesAPI "CRUD on MCPServer, Deployment, Service, NetworkPolicy; read ConfigMap, Secret, Pod" "HTTPS/6443, SA token"
        mcpLifecycleOperator -> mcpServers "MCP protocol handshake and capability discovery" "HTTP/HTTPS, StreamableHTTP"
        prometheus -> mcpLifecycleOperator "Scrapes operator metrics" "HTTPS/8443, TokenReview + SAR"

        controllerManager -> reconciler "Starts reconciliation loop"
        controllerManager -> tlsConfig "Configures TLS profiles"
        controllerManager -> metricsServer "Hosts metrics endpoint"
        reconciler -> kubernetesAPI "Manages child resources" "HTTPS/6443"
        reconciler -> mcpServers "MCP handshake verification" "HTTP/HTTPS"
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
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
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

workspace {
    model {
        platformUser = person "Platform User" "Creates MCPServer custom resources to deploy MCP-compliant servers"

        mcpLifecycleOperator = softwareSystem "MCP Lifecycle Operator" "Manages lifecycle of Model Context Protocol servers by reconciling MCPServer CRs into Deployments and Services with protocol handshake verification" {
            controller = container "MCPServerReconciler" "Watches MCPServer CRs; creates/updates Deployments and Services; performs MCP handshake; computes config hash for rolling updates" "Go (controller-runtime)"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics with authn/authz" "HTTPS/8443, TLS self-signed, Bearer Token"
            healthProbes = container "Health Probes" "Liveness and readiness endpoints" "HTTP/8081"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Control plane API for cluster resource management" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Monitoring"
        mcpServers = softwareSystem "MCP Server Pods" "User-deployed containers implementing Model Context Protocol" "User Workload"
        configData = softwareSystem "ConfigMaps & Secrets" "Configuration data referenced by MCPServer CRs" "Infrastructure"

        platformUser -> mcpLifecycleOperator "Creates MCPServer CRs via kubectl / GitOps"

        controller -> kubernetesAPI "CRUD Deployments, Services; read ConfigMaps, Secrets, Pods; patch MCPServer/status" "HTTPS/443, TLS 1.2+, Bearer Token (SA)"
        controller -> mcpServers "MCP initialize handshake to verify protocol conformance" "HTTP/{port}, plaintext, no auth"
        controller -> configData "Reads referenced ConfigMap/Secret data for config hash computation" "via Kubernetes API"

        prometheus -> metricsServer "Scrapes metrics" "HTTPS/8443, TLS self-signed, Bearer Token"
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
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Monitoring" {
                background #f5a623
                color #ffffff
            }
            element "User Workload" {
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
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

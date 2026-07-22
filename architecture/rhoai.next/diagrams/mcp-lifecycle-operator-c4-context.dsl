workspace {
    model {
        user = person "User / Platform Admin" "Creates MCPServer custom resources to deploy MCP servers on Kubernetes"

        mcpLifecycleOperator = softwareSystem "MCP Lifecycle Operator" "Kubernetes operator that manages the lifecycle of Model Context Protocol (MCP) servers by reconciling MCPServer CRs into Deployments, Services, and NetworkPolicies" {
            controller = container "mcpserver-controller" "Reconciles MCPServer CRDs; creates Deployments, Services, NetworkPolicies; performs MCP handshake verification; computes config hashes" "Go (controller-runtime)"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics on 8443/TCP with TLS and Bearer Token auth" "controller-runtime metrics"
            healthProbes = container "Health Probes" "Liveness (/healthz) and readiness (/readyz) on 8081/TCP" "HTTP"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane for resource CRUD operations" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting platform" "Internal Platform"
        mcpServers = softwareSystem "MCP Server Containers" "User-deployed MCP server instances created by the operator" "Managed"

        configMaps = softwareSystem "ConfigMaps" "Kubernetes ConfigMaps referenced by MCPServer specs" "External"
        secrets = softwareSystem "Secrets" "Kubernetes Secrets referenced by MCPServer specs" "External"

        # Relationships
        user -> mcpLifecycleOperator "Creates MCPServer CR via kubectl/API"
        mcpLifecycleOperator -> k8sApi "CRUD Deployments, Services, NetworkPolicies; watch MCPServer CRs; read ConfigMaps/Secrets" "HTTPS/443, TLS 1.2+, Bearer Token"
        mcpLifecycleOperator -> mcpServers "MCP protocol handshake (initialize) to verify server capabilities" "HTTP/{port}, Streamable HTTP"
        mcpLifecycleOperator -> configMaps "Watches for changes; reads data for config hash computation" "Kubernetes API"
        mcpLifecycleOperator -> secrets "Watches for changes; reads data for config hash computation" "Kubernetes API"
        prometheus -> mcpLifecycleOperator "Scrapes metrics via ServiceMonitor" "HTTPS/8443, TLS, Bearer Token"

        controller -> k8sApi "Watch MCPServer, ConfigMap, Secret; CRUD Deployment, Service, NetworkPolicy" "HTTPS/443"
        controller -> mcpServers "MCP handshake verification" "HTTP/{port}"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #f5a623
                color #ffffff
            }
            element "Managed" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

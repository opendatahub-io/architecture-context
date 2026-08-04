workspace {
    model {
        user = person "User / Platform Admin" "Creates and manages MCPServer custom resources"
        prometheus = person "Prometheus" "Scrapes operator metrics" "Monitoring"

        mcpLifecycleOperator = softwareSystem "MCP Lifecycle Operator" "Manages lifecycle of Model Context Protocol servers via MCPServer CRDs" {
            reconciler = container "MCPServerReconciler" "Watches MCPServer CRs, creates/manages Deployments, Services, NetworkPolicies" "Go controller-runtime"
            healthServer = container "Health Server" "Liveness and readiness probes" "HTTP :8081"
            metricsServer = container "Metrics Server" "Prometheus metrics with TLS and authn/authz" "HTTPS :8443"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External" {
            tags "External"
        }

        mcpServerPods = softwareSystem "MCP Server Pods" "Managed MCP server workloads running in user namespaces" "Managed" {
            tags "Managed"
        }

        // Relationships
        user -> kubernetesAPI "Creates/updates MCPServer CRs" "HTTPS/6443, RBAC"
        kubernetesAPI -> reconciler "Watch events for MCPServer, ConfigMap, Secret" "Watch/TLS, ServiceAccount"
        reconciler -> kubernetesAPI "CRUD: Deployments, Services, NetworkPolicies, ConfigMaps (read), Secrets (read), MCPServer status" "HTTPS/6443, TLS 1.2+, ServiceAccount"
        reconciler -> mcpServerPods "Creates and manages via Kubernetes API" "Deployment/Service/NetworkPolicy"
        prometheus -> metricsServer "Scrapes metrics" "HTTPS/8443, TokenReview+SAR"
        kubernetesAPI -> healthServer "Kubelet health probes" "HTTP/8081, No Auth"
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
            element "Monitoring" {
                background #9673a6
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

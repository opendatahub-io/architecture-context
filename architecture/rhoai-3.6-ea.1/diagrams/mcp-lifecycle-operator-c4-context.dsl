workspace {
    model {
        user = person "Platform User" "Creates MCPServer custom resources to deploy MCP server instances"
        admin = person "Cluster Admin" "Manages operator deployment, RBAC, and TLS configuration"

        mcpLifecycleOperator = softwareSystem "mcp-lifecycle-operator" "Kubernetes operator managing the lifecycle of MCP server deployments, including provisioning, network policy, and protocol verification" {
            manager = container "Manager Process" "Single-replica controller-runtime process with leader election" "Go binary (/manager)"
            reconciler = container "MCPServerReconciler" "Reconciles MCPServer CRs: creates Deployments, Services, NetworkPolicies; computes config hashes for rolling updates" "controller-runtime Reconciler"
            handshakeClient = container "MCP Handshake Client" "Performs MCP protocol initialize handshake against deployed servers; extracts capabilities (tools, resources, prompts)" "go-sdk v1.6.1"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics with TLS and RBAC authentication" "controller-runtime :8443"
            healthProbes = container "Health Probes" "Kubernetes health and readiness endpoints" "HTTP :8081"
            tlsConfig = container "TLS Configuration" "Environment-driven TLS settings (TLS_MIN_VERSION, TLS_CIPHER_SUITES) with optional propagation to managed pods" "tlsSettings struct"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource CRUD, watches, leader election, and RBAC enforcement" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        managedMCPServers = softwareSystem "Managed MCP Servers" "MCP-compliant server pods deployed and verified by the operator" "Managed Workload"

        # User interactions
        user -> mcpLifecycleOperator "Creates/updates MCPServer CRs via kubectl" "Kubernetes API"
        admin -> mcpLifecycleOperator "Configures TLS, RBAC, and deployment settings" "Environment variables, RBAC"

        # Operator to external systems
        mcpLifecycleOperator -> kubernetesAPI "CRUD on Deployments, Services, NetworkPolicies, ConfigMaps, Secrets; watches MCPServer CRs" "HTTPS/6443 TLS 1.2+ ServiceAccount token"
        mcpLifecycleOperator -> managedMCPServers "MCP protocol handshake to verify compliance and extract capabilities" "HTTP/dynamic (in-cluster)"
        prometheus -> mcpLifecycleOperator "Scrapes metrics" "HTTPS/8443 TokenReview+SAR"

        # Internal container relationships
        manager -> reconciler "Starts and manages"
        reconciler -> handshakeClient "Initiates handshake after Deployment available"
        manager -> metricsServer "Configures and serves"
        manager -> healthProbes "Exposes"
        tlsConfig -> metricsServer "Configures TLS"
        tlsConfig -> managedMCPServers "Propagates TLS env vars (optional)" "PROPAGATE_TLS_ENV_VARS"
        reconciler -> kubernetesAPI "CRUD operations" "HTTPS/6443"
        handshakeClient -> managedMCPServers "MCP initialize" "HTTP"
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
            element "Managed Workload" {
                background #9673a6
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

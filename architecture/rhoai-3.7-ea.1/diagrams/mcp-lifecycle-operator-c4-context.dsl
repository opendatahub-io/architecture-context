workspace {
    model {
        user = person "Platform User / GitOps" "Declares MCPServer resources in a tenant namespace"
        mcpClient = person "MCP Client" "AI agent or application consuming MCP tools via a gateway"

        mcpOperator = softwareSystem "mcp-lifecycle-operator" "Deploys, verifies, network-isolates and exposes Model Context Protocol servers via the MCPServer API" {
            manager = container "controller-manager" "Single controller-runtime manager; leader-elected; FIPS build" "Go Operator"
            mcpServerController = container "MCPServer Controller" "Managed Deployment/Service/NetworkPolicy or BYO refs, MCP handshake verification, status, owned MCPGatewayBinding" "Go Controller"
            httprouteProvider = container "httproute Provider" "Reconciles MCPGatewayBinding into Gateway API HTTPRoutes" "Go Controller"
            kuadrantProvider = container "kuadrant Provider" "Reconciles MCPGatewayBinding into Kuadrant MCPServerRegistrations" "Go Controller"
            crdWatcher = container "CRD Watcher" "Starts gateway providers lazily once their CRDs exist" "Go Controller"
            webhooks = container "Webhook Server" "Validating admission + v1alpha1/v1beta1 conversion on 9443/TCP" "HTTPS"
            metrics = container "Metrics Server" "Prometheus metrics on 8443/TCP with TokenReview/SAR" "HTTPS"
        }

        kubeApi = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        mcpServers = softwareSystem "MCP Servers (operands)" "Managed Deployments or BYO workloads in tenant namespaces" "Operand"
        gatewayApi = softwareSystem "Gateway API Gateway" "Platform or tenant Gateway exposing HTTPRoutes" "External"
        kuadrant = softwareSystem "Kuadrant MCP Gateway" "MCP gateway aggregator (mcp.kuadrant.io)" "External"
        certManager = softwareSystem "cert-manager" "Issues webhook and metrics TLS certificates (upstream default)" "External"
        odhOperator = softwareSystem "opendatahub-operator" "Deploys the operator via DataScienceCluster mcplifecycleoperator component" "Internal RHOAI"
        monitoring = softwareSystem "OpenShift Monitoring" "Prometheus (platform + user-workload)" "Internal RHOAI"

        user -> kubeApi "Creates MCPServer" "HTTPS/6443"
        mcpClient -> gatewayApi "Calls MCP tools" "HTTP/HTTPS"
        mcpClient -> kuadrant "Calls MCP tools" "HTTP/HTTPS"
        gatewayApi -> mcpServers "Routes via HTTPRoute" "spec.config.port"
        kuadrant -> mcpServers "Routes via MCPServerRegistration" "spec.config.port"

        odhOperator -> mcpOperator "Deploys and lifecycles"
        kubeApi -> webhooks "Admission and conversion" "HTTPS/443->9443"
        monitoring -> metrics "Scrapes metrics" "HTTPS/8443 Bearer token"
        certManager -> mcpOperator "Provides serving certificates"

        manager -> mcpServerController "Hosts"
        manager -> httprouteProvider "Hosts"
        manager -> kuadrantProvider "Hosts"
        manager -> crdWatcher "Hosts"
        crdWatcher -> httprouteProvider "Starts when Gateway API CRDs exist"
        crdWatcher -> kuadrantProvider "Starts when Kuadrant CRDs exist"

        mcpServerController -> kubeApi "Reconciles MCPServer, Deployment, Service, NetworkPolicy, MCPGatewayBinding" "HTTPS/6443 SA token"
        mcpServerController -> mcpServers "MCP initialize handshake" "HTTP/HTTPS, optional TLS"
        httprouteProvider -> gatewayApi "Creates HTTPRoutes, reads Gateway address" "via Kubernetes API"
        kuadrantProvider -> kuadrant "Creates MCPServerRegistrations, reads MCPGatewayExtension" "via Kubernetes API"
    }

    views {
        systemContext mcpOperator "SystemContext" {
            include *
            autoLayout
        }

        container mcpOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Operand" {
                background #fff2cc
            }
            element "Person" {
                shape person
            }
        }
    }
}

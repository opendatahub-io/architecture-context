workspace {
    model {
        user = person "Platform User" "Creates and manages MCPServer resources via kubectl or GitOps"
        securityTeam = person "Security / SRE" "Monitors metrics, reviews RBAC and network policies"

        mcpLifecycleOperator = softwareSystem "mcp-lifecycle-operator" "Kubernetes operator providing declarative lifecycle management for MCP servers with production-grade automation and gateway integrations" {
            mcpServerController = container "MCPServer Controller" "Core lifecycle reconciler: creates Deployments, Services, NetworkPolicies; performs MCP protocol verification handshake" "Go controller-runtime"
            httpRouteController = container "HTTPRoute Gateway Controller" "Gateway API HTTPRoute provider: creates HTTPRoute resources linking MCPServer Services to a named Gateway" "Go controller-runtime"
            kuadrantController = container "Kuadrant Gateway Controller" "Kuadrant provider: creates MCPServerRegistration and HTTPRoute coordinated with MCPGatewayExtension" "Go controller-runtime"
            configMapController = container "ConfigMap Controller" "Watches ConfigMap for runtime log level changes" "Go controller-runtime"
            validatingWebhook = container "Validating Webhook" "Validates MCPServer create/update: image allowlist, digest enforcement, storage limits, required labels" "Kubernetes Admission Webhook"
            conversionWebhook = container "Conversion Webhook" "Converts MCPServer between v1alpha1 and v1beta1 API versions" "CRD Conversion Webhook"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource CRUD, admission, and leader election" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for traffic routing via Gateway and HTTPRoute resources" "External"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management for webhook and metrics TLS" "External"
        kuadrant = softwareSystem "Kuadrant" "API management platform with MCPGatewayExtension and MCPServerRegistration" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting via ServiceMonitor" "External"
        managedMCPServers = softwareSystem "Managed MCP Servers" "User-supplied MCP server container images deployed and verified by the operator" "Managed"

        # User interactions
        user -> mcpLifecycleOperator "Creates MCPServer CRs via kubectl" "HTTPS/6443"
        securityTeam -> prometheus "Reviews operator metrics"

        # Operator → external systems
        mcpServerController -> kubernetesAPI "Reconciles resources (Deployments, Services, NetworkPolicies)" "HTTPS/6443"
        mcpServerController -> managedMCPServers "MCP protocol verification handshake" "HTTP(S)/config.port"
        httpRouteController -> gatewayAPI "Creates HTTPRoute, reads Gateway" "HTTPS/6443"
        kuadrantController -> kuadrant "Creates MCPServerRegistration, reads MCPGatewayExtension" "HTTPS/6443"
        validatingWebhook -> kubernetesAPI "Receives admission requests" "HTTPS/9443"
        conversionWebhook -> kubernetesAPI "Receives conversion requests" "HTTPS/9443"

        # External → operator
        certManager -> mcpLifecycleOperator "Provisions TLS certificates, CA injection"
        prometheus -> mcpLifecycleOperator "Scrapes metrics" "HTTPS/8443"
        kubernetesAPI -> validatingWebhook "Admission webhook calls" "HTTPS/9443"
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
                color #000000
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

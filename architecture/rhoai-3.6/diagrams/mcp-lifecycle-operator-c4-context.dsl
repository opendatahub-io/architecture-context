workspace {
    model {
        user = person "Platform User" "Creates and manages MCP server instances on OpenShift via MCPServer custom resources"
        securityAdmin = person "Security Admin" "Configures admission policies (image allowlists, digest requirements, labels)"

        mcpLifecycleOperator = softwareSystem "mcp-lifecycle-operator" "Kubernetes operator that declaratively deploys, manages, and verifies MCP servers on OpenShift with production-grade automation and gateway integration" {
            controllerManager = container "Controller Manager" "Single-binary controller-runtime operator with reconciliation loops, webhooks, and metrics server" "Go Operator" {
                mcpServerReconciler = component "MCPServerReconciler" "Reconciles MCPServer CRs into Deployments, Services, NetworkPolicies, MCPGatewayBindings; performs MCP handshake verification" "Controller"
                httprouteReconciler = component "HTTPRoute Reconciler" "Reconciles MCPGatewayBinding CRs into Gateway API HTTPRoute resources" "Controller"
                kuadrantReconciler = component "Kuadrant Reconciler" "Reconciles MCPGatewayBinding CRs into Kuadrant MCPServerRegistration resources" "Controller"
                logLevelController = component "Log Level Controller" "Watches ConfigMap for runtime log level changes" "Controller"
                validatingWebhook = component "MCPServerCustomValidator" "Validates MCPServer CRs: image allowlist, digest requirement, storage limits, required labels" "Webhook"
                conversionWebhook = component "Conversion Webhook" "Converts MCPServer between v1alpha1 and v1beta1 API versions" "Webhook"
            }
        }

        mcpServerPods = softwareSystem "MCP Server Pods" "User-deployed MCP server containers managed by the operator as operands" "Operand"
        kubeAPIServer = softwareSystem "Kubernetes API Server" "Cluster API server for resource CRUD and watch operations" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway and HTTPRoute resources for external traffic routing" "External"
        certManager = softwareSystem "cert-manager" "Provisions and rotates TLS certificates for webhooks and metrics" "External"
        kuadrant = softwareSystem "Kuadrant" "Optional API management platform for MCP server registration and gateway extensions" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics scraping and monitoring" "External"
        mcpGoSDK = softwareSystem "MCP Protocol (go-sdk)" "Model Context Protocol client SDK for server handshake verification" "Library"

        # Relationships
        user -> mcpLifecycleOperator "Creates MCPServer CRs via kubectl" "HTTPS/6443"
        securityAdmin -> mcpLifecycleOperator "Configures admission policies"

        mcpLifecycleOperator -> kubeAPIServer "CRUD resources (Deployments, Services, NetworkPolicies, HTTPRoutes)" "HTTPS/6443"
        mcpLifecycleOperator -> mcpServerPods "Performs MCP protocol handshake verification" "HTTP(S)/configurable"
        mcpLifecycleOperator -> gatewayAPI "Creates HTTPRoute resources for external MCP server exposure" "HTTPS/6443"
        mcpLifecycleOperator -> kuadrant "Registers MCP servers via MCPServerRegistration" "HTTPS/6443"
        mcpLifecycleOperator -> mcpGoSDK "Uses for MCP handshake verification" "In-process"

        certManager -> mcpLifecycleOperator "Provisions TLS certificates for webhooks and metrics" "Kubernetes Secret"
        prometheus -> mcpLifecycleOperator "Scrapes metrics" "HTTPS/8443"
        kubeAPIServer -> mcpLifecycleOperator "Sends admission webhook requests" "HTTPS/9443"
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

        component controllerManager "Components" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Operand" {
                background #7ed321
                color #000000
            }
            element "Library" {
                background #d4a574
                color #000000
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

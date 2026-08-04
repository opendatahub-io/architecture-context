workspace {
    model {
        user = person "CLI User" "Developer or platform admin using kubectl to manage RHOAI clusters"
        agent = person "AI Agent" "MCP client consuming CLI operations as typed tool calls"

        odhCli = softwareSystem "odh-cli" "Kubectl plugin providing operational diagnostics, migration assistance, component inspection, and MCP server for RHOAI clusters" {
            cobraRoot = container "Cobra CLI" "Root command dispatcher with subcommands for diagnose, status, migrate, events, logs, deps, lint, api" "Go CLI"
            k8sClient = container "Kubernetes Client" "Unified client wrapping dynamic, discovery, OLM, metadata, and typed API clients" "Go Library"
            rbacCheck = container "RBAC Pre-flight" "SelfSubjectAccessReview checks before privileged operations" "Go Library"
            migrationEngine = container "Migration Engine" "TrustYAI metrics backup/restore via HTTPS to OpenShift Routes" "Go Library"
            mcpServer = container "MCP Server" "JSON-RPC server exposing CLI operations as MCP tools over SSE or stdio" "Go Service"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane providing resource CRUD and watch" "External"
        olm = softwareSystem "Operator Lifecycle Manager" "Manages operator lifecycle via CSVs and Subscriptions" "External"
        trustyai = softwareSystem "TrustYAI Service" "ML model explainability service with metrics endpoints" "Internal RHOAI"
        odhOperator = softwareSystem "opendatahub-operator" "RHOAI platform operator providing clusterhealth, failureclassifier, and mcptools libraries" "Internal RHOAI"

        # User interactions
        user -> odhCli "Invokes via kubectl odh <subcommand>"
        agent -> mcpServer "JSON-RPC tool calls via SSE (8080/TCP) or stdio"

        # Internal flows
        cobraRoot -> k8sClient "Delegates Kubernetes operations"
        k8sClient -> rbacCheck "Pre-flight permission checks"
        cobraRoot -> migrationEngine "Invokes TrustYAI migration"
        mcpServer -> k8sClient "Executes tool calls against cluster"

        # External dependencies
        k8sClient -> k8sApi "HTTPS/6443 TLS 1.2+ (Bearer/ClientCert/OIDC)"
        k8sClient -> olm "HTTPS/6443 via kube-apiserver (CSV/Subscription queries)"
        migrationEngine -> trustyai "HTTPS/443 TLS 1.2+ (Bearer token, InsecureSkipVerify)"
        odhCli -> odhOperator "Go library imports (clusterhealth, failureclassifier, mcptools)"
    }

    views {
        systemContext odhCli "SystemContext" {
            include *
            autoLayout
        }

        container odhCli "Containers" {
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
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

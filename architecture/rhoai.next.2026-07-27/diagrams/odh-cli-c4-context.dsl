workspace {
    model {
        user = person "Cluster Administrator / Data Scientist" "Manages ODH/RHOAI deployments via kubectl"

        odhCli = softwareSystem "odh-cli (kubectl-odh)" "kubectl plugin for ODH/RHOAI cluster inspection, linting, migration, and operator lifecycle management" {
            cobraCli = container "Cobra CLI" "12-subcommand kubectl plugin entry point" "Go CLI"
            unifiedClient = container "Unified Client" "Creates 6 Kubernetes client types from single REST config" "Go Library"
            rbacPreflight = container "RBAC Pre-flight" "SelfSubjectAccessReview checks before privileged operations" "Go Library"
            eventSubsystem = container "Event Subsystem" "Batch fetch + watch-based streaming with reconnection" "Go Library"
            olmManager = container "OLM Manager" "Operator installation and lifecycle operations" "Go Library"
            mcpServer = container "MCP Server" "Model Context Protocol server capability" "Go Service"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        olm = softwareSystem "Operator Lifecycle Manager" "Operator installation and lifecycle management" "External"
        odhOperator = softwareSystem "OpenDataHub Operator" "ODH/RHOAI platform operator (clusterhealth library)" "Internal RHOAI"

        # External relationships
        user -> odhCli "Runs kubectl odh subcommands"
        odhCli -> k8sApi "REST + WebSocket over HTTPS/6443, TLS 1.2+, kubeconfig auth"
        odhCli -> olm "Manages Subscriptions, CSVs, OperatorGroups via k8s API"
        odhCli -> odhOperator "Imports clusterhealth library for event aggregation"

        # Internal relationships
        cobraCli -> unifiedClient "Delegates API operations"
        cobraCli -> rbacPreflight "Pre-flight checks for privileged commands"
        cobraCli -> eventSubsystem "Event batch fetch and watch streaming"
        cobraCli -> olmManager "Operator lifecycle operations"
        cobraCli -> mcpServer "Serves MCP protocol"
        unifiedClient -> k8sApi "6 client types: dynamic, discovery, apiext, OLM, metadata, typed"
        rbacPreflight -> k8sApi "POST authorization/v1/SelfSubjectAccessReview"
        eventSubsystem -> k8sApi "WATCH /api/v1/events (WSS, auto-reconnect)"
        eventSubsystem -> odhOperator "clusterhealth batch event fetch"
        olmManager -> k8sApi "CRUD on OLM resources"
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
                shape person
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

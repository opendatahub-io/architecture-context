workspace {
    model {
        user = person "Platform Engineer" "Operates and diagnoses RHOAI deployments"
        aiAgent = person "AI Agent" "Integrates via MCP protocol for automated operations"

        odhCli = softwareSystem "odh-cli (rhai-cli)" "Cobra-based kubectl plugin for operating, diagnosing, migrating, and linting RHOAI platform deployments" {
            rootCmd = container "Root Command" "kubectl-odh / rhai-cli entrypoint with 13 subcommands" "Go Cobra CLI"
            unifiedClient = container "Unified Client" "Wraps dynamic, discovery, OLM, API-extensions, core, and authorization K8s clients" "Go Library"
            rbacChecker = container "RBAC Checker" "SelfSubjectAccessReview pre-flight checks before privileged operations" "Go Library"
            mcpServer = container "MCP Server" "Exposes all CLI operations as MCP tool calls over stdio or SSE" "Go Service"
            migrateAction = container "Migration Actions" "TrustYAI metric backup/restore and serverless-to-raw conversion" "Go Library"
            diagnostics = container "Diagnostics Engine" "Health classification and failure analysis using opendatahub-operator packages" "Go Library"
        }

        k8sApi = softwareSystem "Kubernetes API" "Cluster control plane for resource operations" "External"
        olm = softwareSystem "Operator Lifecycle Manager" "Manages operator lifecycle (CSVs, Subscriptions)" "External"
        odhOperator = softwareSystem "opendatahub-operator" "Platform operator providing clusterhealth and failureclassifier packages" "Internal ODH"
        trustyai = softwareSystem "TrustYAI Service" "AI model fairness and explainability service" "Internal ODH"

        # User relationships
        user -> odhCli "Runs CLI commands via kubectl plugin"
        aiAgent -> odhCli "Invokes tool calls via MCP protocol (stdio/SSE)"

        # Internal container relationships
        rootCmd -> unifiedClient "Creates and uses for all K8s operations"
        rootCmd -> rbacChecker "Pre-flight RBAC validation"
        rootCmd -> mcpServer "Registers subcommands as MCP tools"
        rootCmd -> migrateAction "Executes migration workflows"
        rootCmd -> diagnostics "Runs health checks and failure classification"

        # External dependencies
        unifiedClient -> k8sApi "HTTPS/WSS on 6443, TLS 1.2+, kubeconfig credentials"
        rbacChecker -> k8sApi "POST SelfSubjectAccessReview, TLS 1.2+"
        unifiedClient -> olm "Queries CSVs and Subscriptions via K8s API"
        migrateAction -> trustyai "HTTPS/443, TLS 1.2+ (InsecureSkipVerify), Bearer token"
        diagnostics -> odhOperator "Go library import (clusterhealth, failureclassifier, mcptools)"
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
            element "Internal ODH" {
                background #7ed321
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

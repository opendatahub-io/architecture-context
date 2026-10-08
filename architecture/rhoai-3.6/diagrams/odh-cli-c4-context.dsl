workspace {
    model {
        user = person "Platform Engineer" "Manages RHOAI deployments on OpenShift"
        aiAgent = person "AI Agent" "Claude, GPT, or Cursor agent using MCP integration"

        odhCli = softwareSystem "odh-cli (rhai-cli)" "CLI tool (kubectl plugin) for validating, diagnosing, migrating, and managing RHOAI deployments" {
            rootCmd = container "Root Command" "Cobra CLI entry point with 13 subcommands" "Go CLI"
            fatClient = container "Fat Client Layer" "Aggregates dynamic, discovery, API extensions, OLM, typed, and controller-runtime clients" "Go Library"
            migrationFramework = container "Migration Framework" "Registry-based action pattern with version-aware filtering and lifecycle phases" "Go Library"
            mcpServer = container "MCP Server" "Exposes 12 CLI tools + 5 diagnostic tools as typed MCP tool calls" "Go Service"
            genSchemas = container "gen-schemas" "Code generator for JSON schemas from Go types" "Go Build Tool"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster API for all resource operations" "External"
        olm = softwareSystem "Operator Lifecycle Manager" "Manages operator lifecycle (CSVs, Subscriptions)" "External"
        odhOperator = softwareSystem "opendatahub-operator" "Platform operator providing health checks, failure classification, and MCP diagnostic tools" "Internal RHOAI"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Platform detection and manifest rendering utilities" "Internal RHOAI"
        odhGitops = softwareSystem "odh-gitops" "Dependency manifests (values.yaml, Chart.yaml) hosted on GitHub" "Internal RHOAI"
        trustyaiService = softwareSystem "TrustyAI Service" "AI fairness and explainability service with metric endpoints" "Internal RHOAI"

        user -> odhCli "Runs kubectl odh <subcommand>" "CLI"
        aiAgent -> odhCli "Invokes tools via MCP" "JSON-RPC/SSE"

        rootCmd -> fatClient "Initializes and uses"
        rootCmd -> migrationFramework "Invokes for migrate command"
        rootCmd -> mcpServer "Starts for mcp serve command"
        mcpServer -> fatClient "Delegates operations to"

        odhCli -> k8sApiServer "CRUD resources, watch, CRD discovery" "HTTPS/6443"
        odhCli -> olm "CSV and Subscription inspection" "HTTPS/6443"
        odhCli -> odhGitops "Fetch dependency manifests" "HTTPS/443"
        odhCli -> trustyaiService "Metric backup/restore during migration" "HTTPS/443"

        odhCli -> odhOperator "Imports clusterhealth, failureclassifier, mcptools" "Go library"
        odhCli -> odhPlatformUtils "Imports platform detection, manifest rendering" "Go library"
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

workspace {
    model {
        cliUser = person "CLI User" "Platform administrator or data scientist operating RHOAI clusters"
        mcpAgent = person "MCP Agent" "AI agent (Claude, GPT, Cursor) performing automated cluster operations"

        odhCli = softwareSystem "odh-cli / rhai-cli" "CLI tool and kubectl plugin for diagnosing, linting, migrating, and operating Red Hat OpenShift AI deployments" {
            cobraRoot = container "Cobra Root Command" "Dispatches 13 subcommand groups with kubectl-style flags" "Go (cmd/main.go)"
            lintEngine = container "Lint Engine" "Pluggable check framework with glob selectors, severity levels, and version-aware gating" "Go"
            diagnoseEngine = container "Diagnose Engine" "4-step diagnostic flow: triage, investigate, correlate, report" "Go"
            migrateEngine = container "Migrate Engine" "Version-aware cluster migrations with backup, prepare, and run phases" "Go"
            mcpServer = container "MCP Server" "JSON-RPC server exposing CLI tools via stdio/SSE transports for AI agent integration" "Go (pkg/mcp)"
            clientFacade = container "Multi-Client Facade" "Facade over dynamic, discovery, typed, metadata, OLM, and controller-runtime clients" "Go (pkg/util/client)"
            errorClassifier = container "Error Classifier" "Structured error classification with exit codes, retriable flags, and user suggestions" "Go (pkg/util/errors)"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane for all resource operations" "External"
        olm = softwareSystem "Operator Lifecycle Manager" "Manages operator installation and lifecycle via CSVs and Subscriptions" "External"
        odhOperator = softwareSystem "opendatahub-operator" "Platform operator providing cluster health types, failure classifier, and diagnostic MCP tools" "Internal ODH"
        platformUtils = softwareSystem "odh-platform-utilities" "Shared library for platform detection (ODH vs RHOAI), OLM state resolution" "Internal ODH"
        odhGitops = softwareSystem "odh-gitops" "GitOps repository containing dependency manifests (values.yaml, Chart.yaml)" "Internal ODH"
        trustyai = softwareSystem "TrustYAI Service" "AI explainability and fairness monitoring service" "Internal ODH"
        github = softwareSystem "GitHub" "Hosts dependency manifest files at pinned commits" "External"

        # User interactions
        cliUser -> odhCli "Runs CLI commands via terminal or kubectl plugin"
        mcpAgent -> odhCli "Invokes CLI tools via JSON-RPC (stdio or SSE/8080)" "JSON-RPC"

        # Internal flows
        cobraRoot -> lintEngine "Dispatches lint subcommand"
        cobraRoot -> diagnoseEngine "Dispatches diagnose subcommand"
        cobraRoot -> migrateEngine "Dispatches migrate subcommand"
        cobraRoot -> mcpServer "Dispatches mcp serve subcommand"
        mcpServer -> cobraRoot "Bridges tool calls to Commands via toolAdapter"
        lintEngine -> clientFacade "Queries cluster state"
        diagnoseEngine -> clientFacade "Queries cluster state"
        migrateEngine -> clientFacade "Reads/writes cluster state"

        # External dependencies
        clientFacade -> k8sApi "All cluster operations: CRUD, RBAC, health" "HTTPS/6443"
        clientFacade -> olm "CSV and Subscription inspection" "HTTPS/6443"
        odhCli -> trustyai "Metrics backup/restore during migration" "HTTPS/443"
        odhCli -> github "Fetches dependency manifests" "HTTPS/443"

        # Library imports
        diagnoseEngine -> odhOperator "Imports clusterhealth, failureclassifier"
        mcpServer -> odhOperator "Imports diagnostic MCP tools"
        clientFacade -> platformUtils "Imports platform detection, OLM helpers"
        odhCli -> odhGitops "Fetches values.yaml at pinned commit" "HTTPS/443"
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

workspace {
    model {
        operator = person "Platform Operator" "RHOAI cluster administrator who manages upgrades and workloads"
        aiAgent = person "AI Agent" "AI coding assistant using MCP to interact with the CLI"

        odhCli = softwareSystem "odh-cli (rhai-cli)" "CLI tool and kubectl plugin for validating, diagnosing, migrating, and managing RHOAI deployments" {
            cmdLayer = container "Command Layer" "lint, migrate, backup, status, components, deps, get, events, logs commands" "Go (cobra)"
            lintFramework = container "Lint Framework" "Version-aware check registry with 40+ checks across 5 categories" "Go"
            migrateFramework = container "Migration Framework" "Phase-aware action execution with hierarchical step recording" "Go"
            mcpServer = container "MCP Server" "Model Context Protocol server exposing 12 tools via stdio/SSE" "Go (mcp-go)"
            k8sClient = container "Kubernetes Client" "REST client with QPS/Burst throttling and version detection" "Go (client-go)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "OpenShift cluster API server" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Manages DataScienceCluster and DSCInitialization CRs" "Internal RHOAI"
        olm = softwareSystem "Operator Lifecycle Manager" "Manages operator subscriptions and dependencies" "External"
        kserve = softwareSystem "KServe" "Model serving platform (InferenceService CRs)" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "Pipeline orchestration (DSPA CRs)" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI explainability and fairness service" "Internal RHOAI"
        notebooks = softwareSystem "Notebooks" "Jupyter notebook management (Notebook CRs)" "Internal RHOAI"
        rayClusters = softwareSystem "Ray" "Distributed computing framework (RayCluster CRs)" "Internal RHOAI"
        kueue = softwareSystem "Kueue / RHBOK" "Workload queuing and batch processing" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Web UI with AcceleratorProfile and HardwareProfile CRs" "Internal RHOAI"
        odhGitops = softwareSystem "odh-gitops" "Dependency manifest repository on GitHub" "External"

        operator -> odhCli "Runs CLI commands via kubectl plugin"
        aiAgent -> odhCli "Invokes tools via MCP protocol (stdio/SSE)"

        odhCli -> k8sAPI "All cluster operations" "HTTPS/6443, TLS 1.2+, Bearer Token"
        odhCli -> trustyai "Metrics backup/restore during migration" "HTTPS/443, TLS 1.2"
        odhCli -> odhGitops "Fetches dependency manifest" "HTTPS/443"

        cmdLayer -> lintFramework "Registers and executes checks"
        cmdLayer -> migrateFramework "Registers and executes migration actions"
        cmdLayer -> k8sClient "Cluster API calls"
        mcpServer -> cmdLayer "Wraps commands as MCP tools"
        k8sClient -> k8sAPI "REST API calls" "HTTPS/6443"

        k8sAPI -> rhoaiOperator "Manages" "CRDs: DSC, DSCI"
        k8sAPI -> olm "Manages" "CRDs: Subscription, CSV"
        k8sAPI -> kserve "Manages" "CRD: InferenceService"
        k8sAPI -> dsp "Manages" "CRD: DSPA"
        k8sAPI -> notebooks "Manages" "CRD: Notebook"
        k8sAPI -> rayClusters "Manages" "CRD: RayCluster"
        k8sAPI -> kueue "Manages" "CRDs: Kueue resources"
        k8sAPI -> dashboard "Manages" "CRDs: AcceleratorProfile, HardwareProfile"
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
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}

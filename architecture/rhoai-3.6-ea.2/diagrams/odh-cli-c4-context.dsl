workspace {
    model {
        admin = person "Cluster Admin / SRE" "Manages RHOAI deployments on OpenShift clusters"
        aiAgent = person "AI Agent" "Claude, GPT, or Cursor using MCP protocol for cluster diagnostics"

        odhCli = softwareSystem "odh-cli (rhai-cli)" "CLI tool for inspecting, diagnosing, linting, and migrating RHOAI deployments" {
            cobraRoot = container "Cobra Root Command" "13 subcommands for RHOAI operations" "Go CLI"
            lintEngine = container "Lint Engine" "4-tier upgrade readiness checks (components, deps, platform, workloads)" "Go Package"
            migrateEngine = container "Migration Engine" "Action/registry pattern with dry-run capability and version-range targeting" "Go Package"
            diagnoseEngine = container "Diagnose Engine" "4-step diagnostic flow: triage, investigate, correlate, assemble" "Go Package"
            mcpServer = container "MCP Server" "Exposes all CLI tools via JSON-RPC over stdio or HTTP SSE" "Go Service"
            k8sClient = container "Kubernetes Client Layer" "6 client types: dynamic, discovery, apiextensions, OLM, metadata, typed" "Go Package"
            errorClassifier = container "Error Classifier" "Structured error classification with exit codes and suggestions" "Go Package"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "OpenShift cluster API for resource management" "External"
        olm = softwareSystem "Operator Lifecycle Manager" "Operator installation and lifecycle management" "External"
        odhOperator = softwareSystem "opendatahub-operator" "Platform operator providing health, failure classification, and MCP diagnostic libraries" "Internal ODH"
        trustyai = softwareSystem "TrustYAI Service" "Fairness and explainability metrics service" "Internal ODH"
        odhGitops = softwareSystem "odh-gitops" "GitOps manifests for dependency management" "Internal ODH"
        github = softwareSystem "GitHub Raw Content" "Public manifest hosting for dependency resolution" "External"

        // User interactions
        admin -> odhCli "Runs CLI commands (lint, migrate, diagnose, status, etc.)"
        aiAgent -> mcpServer "Invokes tools via JSON-RPC (stdio or SSE/8080)"

        // Internal flows
        cobraRoot -> lintEngine "Delegates lint subcommand"
        cobraRoot -> migrateEngine "Delegates migrate subcommand"
        cobraRoot -> diagnoseEngine "Delegates diagnose subcommand"
        mcpServer -> cobraRoot "Reuses cmd.Command interface for all tools"
        lintEngine -> k8sClient "Read-only cluster queries"
        migrateEngine -> k8sClient "Read-write cluster operations"
        diagnoseEngine -> k8sClient "Read-only diagnostics"
        k8sClient -> errorClassifier "Classifies API errors"

        // External integrations
        k8sClient -> k8sApi "HTTPS/6443, TLS 1.2+, kubeconfig credentials" "REST + WebSocket"
        odhCli -> olm "OLM typed clientset for subscription/CSV inspection" "HTTPS/6443"
        odhCli -> trustyai "Metric backup/restore during migration" "HTTPS/443, Bearer token"
        odhCli -> github "Fetch dependency manifests" "HTTPS/443"

        // Library dependencies
        mcpServer -> odhOperator "Imports clusterhealth, failureclassifier, mcptools packages"
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

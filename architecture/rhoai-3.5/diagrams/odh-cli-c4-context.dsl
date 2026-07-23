workspace {
    model {
        user = person "Platform Engineer / SRE" "Manages RHOAI cluster lifecycle, runs upgrade assessments and migrations"
        aiAgent = person "AI Agent" "Interacts with odh-cli via MCP protocol for automated cluster management"

        odhCli = softwareSystem "odh-cli (rhai-cli)" "CLI tool for RHOAI upgrade readiness assessment, migration execution, and operational diagnostics" {
            commandLayer = container "Command Layer" "15 commands: lint, migrate, status, backup, deps, events, logs, components, workbench" "Go CLI (cmd/)"
            lintFramework = container "Lint Check Framework" "50+ diagnostic checks in 5 groups: Dependency, Service, Platform, Component, Workload" "Go Library (pkg/lint/)"
            migrationFramework = container "Migration Action Framework" "Phased pre/post-upgrade actions with dry-run support and recording" "Go Library (pkg/migrate/)"
            backupPipeline = container "Backup Pipeline" "Three-stage pipeline: discovery, dependency resolution, writing (parallel workers)" "Go Library (pkg/backup/)"
            depManager = container "Dependency Manager" "Parses odh-gitops manifests, validates OLM catalog sources" "Go Library (pkg/deps/)"
            mcpServer = container "MCP Server" "Model Context Protocol server exposing 12 CLI tools via stdio or SSE transport" "Go Service (embedded)"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "OpenShift cluster API providing access to all RHOAI resources" "External"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager for subscription and dependency management" "External"
        openshift = softwareSystem "OpenShift" "Container platform runtime (≥4.19.9)" "External"

        rhoaiOperator = softwareSystem "RHOAI Operator" "opendatahub-operator / rhods-operator managing RHOAI components" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving infrastructure" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI fairness, explainability, and guardrails" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches" "Jupyter notebooks for data science" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed computing for ML workloads" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queuing and fair scheduling" "Internal RHOAI"
        dashboard = softwareSystem "Dashboard" "RHOAI web UI with accelerator/hardware profiles" "Internal RHOAI"
        serviceMesh = softwareSystem "Service Mesh (OSSM)" "Istio/Maistra service mesh for traffic management" "External"
        serverless = softwareSystem "Serverless (Knative)" "Serverless platform for autoscaling" "External"
        certManager = softwareSystem "cert-manager" "Certificate management" "External"

        odhGitops = softwareSystem "odh-gitops" "Dependency manifests hosted on GitHub" "External"

        # Relationships
        user -> odhCli "Runs lint, migrate, status, backup commands" "kubectl plugin"
        aiAgent -> odhCli "Invokes CLI tools via MCP" "JSON-RPC (stdio/SSE)"

        odhCli -> k8sApiServer "Reads/patches cluster resources" "HTTPS/6443, TLS 1.2+, kubeconfig"
        odhCli -> trustyai "Backs up/restores metrics during migration" "HTTPS/443, TLS 1.2, Bearer Token"
        odhCli -> odhGitops "Fetches dependency manifests" "HTTPS/443, TLS 1.2+"

        odhCli -> rhoaiOperator "Reads DSC, DSCI for component state" "via K8s API"
        odhCli -> kserve "Reads/patches InferenceService, ServingRuntime" "via K8s API"
        odhCli -> dsp "Reads/patches DSPA" "via K8s API"
        odhCli -> workbenches "Reads/patches Notebooks" "via K8s API"
        odhCli -> ray "Reads RayCluster, RayJob" "via K8s API"
        odhCli -> kueue "Validates queue labels, subscriptions" "via K8s API"
        odhCli -> dashboard "Reads AcceleratorProfile, HardwareProfile" "via K8s API"
        odhCli -> serviceMesh "Reads SMCP, SMMR, SMM" "via K8s API"
        odhCli -> serverless "Reads KnativeServing, KnativeEventing" "via K8s API"
        odhCli -> olm "Reads Subscriptions, CSVs, PackageManifests" "via K8s API"
        odhCli -> certManager "Validates installation" "via K8s API"

        commandLayer -> lintFramework "Delegates lint checks"
        commandLayer -> migrationFramework "Delegates migration actions"
        commandLayer -> backupPipeline "Delegates backup operations"
        commandLayer -> depManager "Delegates dependency management"
        mcpServer -> commandLayer "Wraps 12 commands as MCP tools"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

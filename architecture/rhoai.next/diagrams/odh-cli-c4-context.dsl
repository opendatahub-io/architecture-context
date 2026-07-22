workspace {
    model {
        platformEngineer = person "Platform Engineer / Admin" "Manages RHOAI deployments, performs upgrades and migrations"
        aiAgent = person "AI Agent" "AI assistant (e.g. Claude) consuming CLI capabilities via MCP"

        odhCli = softwareSystem "odh-cli (rhai-cli)" "CLI tool for diagnosing, auditing, and migrating RHOAI deployments" {
            mainCli = container "Main CLI" "cobra-based CLI with status, components, get, deps, events, logs, backup commands" "Go Binary"
            lintEngine = container "Lint Engine" "Rules-based diagnostic framework with 48 checks across 5 groups" "Go Library (pkg/lint/)"
            migrateFramework = container "Migration Framework" "Action-based migration system with prepare/run phases, dry-run, backup/restore" "Go Library (pkg/migrate/)"
            mcpServer = container "MCP Server" "Model Context Protocol server exposing 13 CLI tools via stdio or SSE" "Go Library (pkg/mcp/)"
            backupPipeline = container "Backup Pipeline" "Three-stage pipeline: discovery, resolution, writing for workload export" "Go Library (pkg/backup/)"
        }

        k8sCluster = softwareSystem "Kubernetes / OpenShift Cluster" "Target cluster for all CLI operations" "External" {
            k8sApi = container "Kubernetes API Server" "Central API for all cluster resource operations" "6443/TCP HTTPS"
        }

        rhodsOperator = softwareSystem "RHOAI Operator" "Manages DataScienceCluster and DSCInitialization CRs" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving with InferenceService CRDs" "Internal RHOAI"
        notebooks = softwareSystem "Kubeflow Notebooks" "Workbench management with Notebook CRDs" "Internal RHOAI"
        kueue = softwareSystem "Kueue / RHBOK" "Job queueing with ClusterQueue/LocalQueue CRDs" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration with DSPA CRDs" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI fairness and drift monitoring with REST API" "Internal RHOAI"
        trainingOperator = softwareSystem "Training Operator" "Distributed training with PyTorchJob/TFJob CRDs" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed computing with RayCluster/RayJob CRDs" "Internal RHOAI"
        llamaStack = softwareSystem "LlamaStack" "LLM distribution management" "Internal RHOAI"

        olm = softwareSystem "OLM" "Operator Lifecycle Manager for subscription management" "External"
        ossm = softwareSystem "OpenShift Service Mesh" "Service mesh (Istio-based) for traffic management" "External"
        knative = softwareSystem "Knative Serving" "Serverless platform for autoscaling" "External"
        certManager = softwareSystem "cert-manager" "Certificate management" "External"
        kuadrant = softwareSystem "Kuadrant / Authorino" "API gateway and authorization" "External"

        odhGitops = softwareSystem "odh-gitops (GitHub)" "Dependency manifest source repository" "External"

        # User interactions
        platformEngineer -> odhCli "Runs lint, migrate, status, backup commands via CLI"
        aiAgent -> mcpServer "Invokes CLI tools via MCP stdio/SSE" "stdio / HTTP SSE (localhost:8080)"

        # Internal container relationships
        mainCli -> lintEngine "Delegates lint commands"
        mainCli -> migrateFramework "Delegates migrate commands"
        mainCli -> mcpServer "Starts MCP server"
        mainCli -> backupPipeline "Delegates backup commands"

        # CLI to cluster
        odhCli -> k8sCluster "All cluster operations (CRD read/write, pod exec, logs)" "HTTPS/6443, Bearer Token"
        odhCli -> trustyai "Backup/restore scheduled metrics" "HTTPS/443, Bearer Token, InsecureSkipVerify"
        odhCli -> odhGitops "Fetch dependency manifests" "HTTPS/443, No Auth"

        # CRD interactions (via K8s API)
        lintEngine -> rhodsOperator "Read DSC, DSCI state"
        lintEngine -> kserve "Check InferenceService configs"
        lintEngine -> notebooks "Check workbench state"
        lintEngine -> kueue "Check data integrity"
        lintEngine -> dsPipelines "Check DSPA renaming"
        lintEngine -> trustyai "Check guardrails state"
        lintEngine -> ossm "Check service mesh removal"
        lintEngine -> knative "Check Serverless removal"
        lintEngine -> kuadrant "Check Kuadrant readiness"

        migrateFramework -> kserve "Migrate ModelMesh to Raw deployment"
        migrateFramework -> notebooks "Migrate auth model OAuth to RBAC"
        migrateFramework -> kueue "Migrate embedded Kueue to RHBOK"
        migrateFramework -> dsPipelines "Migrate v1alpha1 to v1"
        migrateFramework -> trustyai "Backup/restore metrics via REST"
        migrateFramework -> ray "Backup/migrate RayClusters"
        migrateFramework -> olm "Install RHBOK operator subscription"

        backupPipeline -> k8sApi "Discover and export workload definitions"
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
                background #85bbf0
                color #000000
            }
        }
    }
}

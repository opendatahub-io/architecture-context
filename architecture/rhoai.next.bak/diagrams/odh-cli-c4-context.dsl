workspace {
    model {
        operator = person "Platform Operator" "RHOAI administrator performing upgrades, migrations, and diagnostics"

        odhCli = softwareSystem "odh-cli" "CLI tool for RHOAI upgrade readiness, migration automation, workload backup, and operational diagnostics" {
            cobraCli = container "Cobra CLI Framework" "Root command and subcommand routing" "Go (cobra)"
            lintEngine = container "Lint Framework" "Upgrade readiness assessment with 38 checks, severity classification, structured output" "Go (pkg/lint/)"
            migrateEngine = container "Migration Framework" "19 migration actions with prepare/run lifecycle, step recording, RBAC pre-validation" "Go (pkg/migrate/)"
            backupPipeline = container "Backup Pipeline" "Three-stage pipeline: discovery, dependency resolution, JQ-based writer" "Go (pkg/backup/)"
            operationalCmds = container "Operational Commands" "components, deps, status, logs, events, get subcommands" "Go"
        }

        openshift = softwareSystem "OpenShift / Kubernetes" "Target platform cluster with RHOAI installed" {
            k8sApi = container "Kubernetes API Server" "Central API for all cluster operations" "6443/TCP HTTPS"
        }

        odhOperator = softwareSystem "opendatahub-operator" "Manages RHOAI platform lifecycle via DataScienceCluster and DSCInitialization CRDs" "Internal RHOAI"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager for subscription and CSV management" "OpenShift"

        kserve = softwareSystem "KServe" "Model serving platform with InferenceService and ServingRuntime CRDs" "Internal RHOAI"
        notebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook workbench management" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration with DSPA CRDs" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job scheduling and quota management" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed computing framework for ML workloads" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI fairness, drift monitoring, and guardrails" "Internal RHOAI"
        trainingOp = softwareSystem "Training Operator" "Distributed training job management (PyTorch, TF, MPI, XGBoost)" "Internal RHOAI"
        llamastack = softwareSystem "LlamaStack" "LLM distribution management" "Internal RHOAI"
        dashboard = softwareSystem "Dashboard" "RHOAI web UI with accelerator and hardware profiles" "Internal RHOAI"

        github = softwareSystem "GitHub" "Hosts odh-gitops dependency manifests" "External"
        localFs = softwareSystem "Local Filesystem" "Stores backup files (YAML/JSON) and kubeconfig" "External"

        # Relationships - User
        operator -> odhCli "Runs lint, migrate, backup, status commands via" "CLI (kubectl plugin)"

        # Relationships - CLI to cluster
        odhCli -> openshift "Reads/writes Kubernetes resources via" "HTTPS/6443, Bearer Token"

        # Relationships - CLI to platform components (via K8s API)
        odhCli -> odhOperator "Reads DSC/DSCI CRDs, component state" "Kubernetes API"
        odhCli -> olm "Reads/writes Subscriptions, CSVs, InstallPlans" "Kubernetes API"
        odhCli -> kserve "Lint checks, migration (serverless->raw, modelmesh->raw)" "Kubernetes API"
        odhCli -> notebooks "Lint checks, container name migration, backup" "Kubernetes API"
        odhCli -> dsp "Lint checks, v1alpha1->v1 migration, RBAC patching" "Kubernetes API"
        odhCli -> kueue "Lint checks, RHBOK migration" "Kubernetes API"
        odhCli -> ray "Lint checks, backup, migration" "Kubernetes API"
        odhCli -> trustyai "Data/metrics backup, guardrails patching, OTEL migration" "HTTPS/443 + Kubernetes API"
        odhCli -> trainingOp "Training workload verification, deprecation notices" "Kubernetes API"
        odhCli -> llamastack "Backup before 3.5 rename to OGX" "Kubernetes API"
        odhCli -> dashboard "Accelerator/hardware profile migration checks" "Kubernetes API"

        # Relationships - External
        odhCli -> github "Fetches dependency manifest (odh-gitops)" "HTTPS/443"
        odhCli -> localFs "Writes backup files (YAML/JSON, mode 0600)" "File I/O"

        # Internal container relationships
        cobraCli -> lintEngine "Routes lint subcommand"
        cobraCli -> migrateEngine "Routes migrate subcommand"
        cobraCli -> backupPipeline "Routes backup subcommand"
        cobraCli -> operationalCmds "Routes ops subcommands"
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
            element "OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

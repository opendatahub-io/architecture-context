workspace {
    model {
        admin = person "RHOAI Platform Administrator" "Runs CLI to inspect, validate, and migrate RHOAI deployments"
        ciPipeline = person "CI/CD Pipeline" "Automated lint checks and migration execution"

        odhCli = softwareSystem "odh-cli" "CLI tool for inspecting, validating, and migrating RHOAI deployments on OpenShift clusters" {
            cliApp = container "rhai-cli" "Main CLI binary (kubectl-odh plugin)" "Go CLI"
            lintEngine = container "Lint Engine" "Upgrade readiness validation (38 checks, 5 groups)" "Go Framework"
            migrateEngine = container "Migrate Engine" "Migration action execution (19 actions, prepare/run phases)" "Go Framework"
            backupPipeline = container "Backup Pipeline" "Workload backup with dependency resolution" "Go Library"
            k8sClient = container "K8s Client Layer" "Unified client with Reader/Writer separation" "Go Library"
            outputSystem = container "Output System" "Multi-format rendering (table, JSON, YAML)" "Go Library"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster API for all resource operations" "External"
        openshiftApi = softwareSystem "OpenShift API Server" "ClusterVersion detection, Routes, ImageStreams" "External"
        olm = softwareSystem "OLM" "Operator discovery, subscription management" "External"

        odhOperator = softwareSystem "opendatahub-operator" "RHOAI platform operator managing DataScienceCluster" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed computing framework" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queueing and scheduling" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI model trust and fairness monitoring" "Internal RHOAI"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook workloads" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for RHOAI platform" "Internal RHOAI"
        llamastack = softwareSystem "LlamaStack" "LLM deployment framework" "Internal RHOAI"
        trainingOperator = softwareSystem "Training Operator" "Distributed training jobs" "Internal RHOAI"

        github = softwareSystem "GitHub" "odh-gitops manifest source (build-time)" "External"
        filesystem = softwareSystem "Local Filesystem" "Backup YAML file storage" "External"

        # User interactions
        admin -> odhCli "Runs lint, migrate, status, backup commands via CLI"
        ciPipeline -> odhCli "Automated upgrade readiness checks (JSON output)"

        # Internal container interactions
        cliApp -> lintEngine "Invokes lint checks"
        cliApp -> migrateEngine "Invokes migration actions"
        cliApp -> backupPipeline "Invokes workload backup"
        lintEngine -> k8sClient "Uses (Reader interface only)"
        migrateEngine -> k8sClient "Uses (Reader + Writer interfaces)"
        backupPipeline -> k8sClient "Uses (Reader interface only)"
        lintEngine -> outputSystem "Renders results"
        migrateEngine -> outputSystem "Renders results"
        backupPipeline -> outputSystem "Renders results"

        # External system interactions
        odhCli -> k8sApiServer "All cluster operations" "HTTPS/6443 TLS 1.2+"
        odhCli -> openshiftApi "ClusterVersion, Routes" "HTTPS/6443 TLS 1.2+"
        odhCli -> olm "CSV, Subscription discovery" "HTTPS/6443 TLS 1.2+"

        # Platform component interactions (via K8s API)
        odhCli -> odhOperator "Read/Write DSC, DSCI" "HTTPS/6443 via API Server"
        odhCli -> kserve "Read/Write InferenceService, ServingRuntime" "HTTPS/6443 via API Server"
        odhCli -> dsp "Read/Write DSPA" "HTTPS/6443 via API Server"
        odhCli -> ray "Read/Write RayCluster, RayJob" "HTTPS/6443 via API Server"
        odhCli -> kueue "Read ClusterQueue, LocalQueue" "HTTPS/6443 via API Server"
        odhCli -> trustyai "Read/Write CRDs + HTTP metrics" "HTTPS/6443 + 443"
        odhCli -> kubeflowNotebooks "Read Notebooks" "HTTPS/6443 via API Server"
        odhCli -> dashboard "Read AcceleratorProfile, HardwareProfile" "HTTPS/6443 via API Server"
        odhCli -> llamastack "Read LlamaStackDistribution" "HTTPS/6443 via API Server"
        odhCli -> trainingOperator "Read training jobs" "HTTPS/6443 via API Server"

        # External services
        odhCli -> github "Fetch dependency manifest (build-time)" "HTTPS/443"
        odhCli -> filesystem "Write backup YAML files" "File I/O"
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

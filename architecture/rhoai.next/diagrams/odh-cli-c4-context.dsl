workspace {
    model {
        admin = person "Platform Admin" "RHOAI platform administrator performing upgrade readiness checks and migrations"

        odhcli = softwareSystem "odh-cli" "CLI tool for validating, managing, and migrating RHOAI deployments" {
            cliCore = container "kubectl-odh" "Primary CLI binary with lint, backup, migrate, get, deps, components commands" "Go 1.25 (Cobra, FIPS-compliant)"
            lintFramework = container "Lint Framework" "37 diagnostic checks across 5 groups (dependency, platform, component, workload, service)" "Go"
            backupPipeline = container "Backup Pipeline" "3-stage pipeline: discovery → resolution → writing with concurrent workers" "Go"
            migrationFramework = container "Migration Framework" "ActionRegistry-based migration execution with dry-run support" "Go"
            k8sClient = container "Kubernetes Client" "Reader/Writer interfaces with elevated QPS (50/100), nil-safe OLM" "Go (client-go)"
            yq = container "yq" "Vendored YAML processor built with FIPS-compliant build tags" "Go"
            upgradeHelpers = container "rhoai-upgrade-helpers" "Shell and Python migration scripts (git submodule)" "Shell, Python"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for all resource operations" "External"
        olmAPI = softwareSystem "Operator Lifecycle Manager" "Operator installation and version management" "External"
        openshift = softwareSystem "OpenShift API" "ClusterVersion detection, ImageStream queries" "External"

        dsc = softwareSystem "DataScienceCluster" "Singleton CR managing RHOAI component lifecycle" "Internal RHOAI"
        dsci = softwareSystem "DSCInitialization" "Singleton CR for RHOAI initialization config" "Internal RHOAI"
        kserve = softwareSystem "KServe" "ML model serving (InferenceService, ServingRuntime)" "Internal ODH"
        kubeflow = softwareSystem "Kubeflow" "Notebook server management" "Internal ODH"
        kueue = softwareSystem "Kueue" "Workload queuing (ClusterQueue, LocalQueue)" "Internal ODH"
        ray = softwareSystem "Ray" "Distributed compute (RayCluster, RayJob)" "Internal ODH"
        trainingOp = softwareSystem "Training Operator" "Distributed training (PyTorchJob)" "Internal ODH"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration (DSPA)" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "AcceleratorProfile, HardwareProfile management" "Internal ODH"
        trustyai = softwareSystem "TrustyAI" "AI governance (GuardrailsOrchestrator)" "Internal ODH"
        codeflare = softwareSystem "CodeFlare" "AppWrapper management (deprecated)" "Internal ODH"
        llamastack = softwareSystem "LlamaStack" "LLM distribution management" "Internal ODH"
        kuadrant = softwareSystem "Kuadrant" "Gateway API management" "External"
        authorino = softwareSystem "Authorino" "Auth/TLS management for KServe" "External"

        odhGitops = softwareSystem "odh-gitops (GitHub)" "Dependency manifest repository" "External"
        localFS = softwareSystem "Local Filesystem" "Backup output and kubeconfig storage" "External"

        admin -> odhcli "Runs upgrade checks, backups, and migrations" "CLI"
        odhcli -> k8sAPI "Reads/writes cluster resources" "HTTPS/6443, Bearer Token"
        odhcli -> olmAPI "Queries operator status, creates subscriptions" "HTTPS/6443, Bearer Token"
        odhcli -> openshift "Detects platform version" "HTTPS/6443, Bearer Token"

        odhcli -> dsc "Reads config, patches component state" "HTTPS/6443"
        odhcli -> dsci "Reads initialization config" "HTTPS/6443"
        odhcli -> kserve "Validates InferenceServices" "HTTPS/6443"
        odhcli -> kubeflow "Validates and backs up Notebooks" "HTTPS/6443"
        odhcli -> kueue "Validates queues, RHBOK migration" "HTTPS/6443"
        odhcli -> ray "Validates RayClusters, AppWrapper cleanup" "HTTPS/6443"
        odhcli -> trainingOp "Checks PyTorchJob completion" "HTTPS/6443"
        odhcli -> dsp "Validates and backs up DSPAs" "HTTPS/6443"
        odhcli -> dashboard "Checks AcceleratorProfile migration" "HTTPS/6443"
        odhcli -> trustyai "Validates OTEL migration" "HTTPS/6443"
        odhcli -> codeflare "Validates AppWrapper removal" "HTTPS/6443"
        odhcli -> llamastack "Validates architecture compatibility" "HTTPS/6443"
        odhcli -> kuadrant "Validates Gateway API readiness" "HTTPS/6443"
        odhcli -> authorino "Validates TLS readiness" "HTTPS/6443"

        odhcli -> odhGitops "Fetches dependency manifests" "HTTPS/443"
        odhcli -> localFS "Writes backup YAML files" "Filesystem I/O"

        cliCore -> lintFramework "Dispatches lint command"
        cliCore -> backupPipeline "Dispatches backup command"
        cliCore -> migrationFramework "Dispatches migrate command"
        cliCore -> k8sClient "All cluster operations"
        lintFramework -> k8sClient "Read-only queries"
        backupPipeline -> k8sClient "Read queries + file writes"
        migrationFramework -> k8sClient "Read + write operations"
    }

    views {
        systemContext odhcli "SystemContext" {
            include *
            autoLayout
        }

        container odhcli "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #e53935
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
                shape RoundedBox
            }
        }
    }
}

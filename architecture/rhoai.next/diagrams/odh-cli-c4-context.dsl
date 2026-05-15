workspace {
    model {
        # Personas
        datascientist = person "Data Scientist" "Creates and manages ML workloads on RHOAI"
        platformadmin = person "Platform Admin" "Manages RHOAI platform, performs upgrades and migrations"
        cipeline = person "CI/CD Pipeline" "Automated pipeline running lint/status checks"

        # The system
        odhcli = softwareSystem "odh-cli (rhai-cli)" "CLI tool for validating, managing, and migrating RHOAI deployments" {
            cmdLayer = container "Command Layer" "Cobra-based CLI commands: lint, status, get, components, deps, logs, backup, migrate, version" "Go (spf13/cobra)"
            lintEngine = container "Lint Engine" "37 diagnostic checks across 5 groups (Dependency, Service, Platform, Component, Workload)" "Go"
            statusEngine = container "Status Engine" "Platform health assessment using clusterhealth library" "Go"
            depsMgr = container "Dependency Manager" "OLM operator dependency discovery, validation, and installation from odh-gitops manifests" "Go"
            migrateFw = container "Migration Framework" "2-phase (Prepare/Run) pluggable action system with step recording" "Go"
            backupEngine = container "Backup Engine" "Resource serialization for notebooks, pipelines, configs" "Go"
            k8sClient = container "Kubernetes Client" "Reader/Writer split client with multi-API composition (Dynamic, Discovery, OLM, Core)" "Go (controller-runtime)"
            outputLayer = container "Output Layer" "Table, JSON, YAML output with envelope wrapping and JSON Schema" "Go"
        }

        bundledTools = softwareSystem "Bundled Tools" "yq, rhoai-upgrade-helpers shell scripts, Python migration helpers" "Container Image Tools"

        # External systems
        k8sapi = softwareSystem "Kubernetes API Server" "Cluster API endpoint for all resource operations" "External"
        olm = softwareSystem "Operator Lifecycle Manager" "Manages operator subscriptions, CSVs, and operator groups" "External"
        openshift = softwareSystem "OpenShift" "Container platform providing ClusterVersion, Routes, OAuth" "External"
        github = softwareSystem "GitHub (odh-gitops)" "Public repository hosting Helm dependency manifests (values.yaml, Chart.yaml)" "External"

        # RHOAI platform CRDs
        dsc = softwareSystem "DataScienceCluster" "Primary RHOAI CR for component management state" "Internal RHOAI"
        dsci = softwareSystem "DSCInitialization" "RHOAI initialization CR for namespace and monitoring config" "Internal RHOAI"
        componentCRs = softwareSystem "Component CRs" "Platform component CRs (dashboards, kserves, rays, etc.) for health enrichment" "Internal RHOAI"

        # Workload systems
        kserve = softwareSystem "KServe" "Model serving platform (InferenceServices, ServingRuntimes)" "Internal RHOAI"
        notebooks = softwareSystem "Kubeflow Notebooks" "Interactive notebook workloads" "Internal RHOAI"
        pipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration (DSPAs)" "Internal RHOAI"
        distributed = softwareSystem "Distributed Workloads" "RayClusters, RayJobs, PyTorchJobs, AppWrappers" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queuing system (ClusterQueues, LocalQueues)" "Internal RHOAI"

        # Relationships - Users to CLI
        platformadmin -> odhcli "Runs lint, migrate, deps, components, backup commands"
        datascientist -> odhcli "Runs get, status, logs commands to inspect workloads"
        cipeline -> odhcli "Runs lint --output=json for automated upgrade readiness checks"

        # Relationships - Internal containers
        cmdLayer -> lintEngine "Dispatches lint command"
        cmdLayer -> statusEngine "Dispatches status command"
        cmdLayer -> depsMgr "Dispatches deps command"
        cmdLayer -> migrateFw "Dispatches migrate command"
        cmdLayer -> backupEngine "Dispatches backup command"
        lintEngine -> k8sClient "Uses client.Reader (read-only)"
        statusEngine -> k8sClient "Uses client.Reader"
        depsMgr -> k8sClient "Uses Reader + Writer for OLM operations"
        migrateFw -> k8sClient "Uses Reader + Writer for DSC patching"
        backupEngine -> k8sClient "Uses client.Reader"
        lintEngine -> outputLayer "Formats DiagnosticResults"
        statusEngine -> outputLayer "Formats status tables"

        # Relationships - CLI to external systems
        odhcli -> k8sapi "All cluster operations" "HTTPS/6443, TLS 1.2+, kubeconfig auth"
        odhcli -> github "Fetches dependency manifests (--refresh)" "HTTPS/443, TLS 1.2+, public"

        # Relationships - K8s API to resources
        k8sapi -> olm "Subscription/CSV management"
        k8sapi -> openshift "ClusterVersion detection"
        k8sapi -> dsc "Component state read/patch"
        k8sapi -> dsci "Namespace discovery"
        k8sapi -> componentCRs "Health enrichment"
        k8sapi -> kserve "InferenceService/ServingRuntime validation"
        k8sapi -> notebooks "Notebook workload inspection"
        k8sapi -> pipelines "DSPA validation"
        k8sapi -> distributed "Workload impact assessment"
        k8sapi -> kueue "Data integrity checks, RHBOK migration"
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
                background #7ed321
                color #ffffff
            }
            element "Container Image Tools" {
                background #f5a623
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
            element "Container" {
                shape RoundedBox
            }
        }
    }
}

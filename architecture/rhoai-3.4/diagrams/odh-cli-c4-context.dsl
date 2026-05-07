workspace {
    model {
        user = person "Platform Engineer / Data Scientist" "Manages RHOAI installations, validates upgrade readiness, backs up workloads"
        ciPipeline = person "CI/CD Pipeline" "Automated upgrade validation and workload backup"

        odhCli = softwareSystem "odh-cli (kubectl-odh)" "CLI tool for validating, diagnosing, and managing RHOAI installations and upgrades" {
            lintSubsystem = container "Lint Subsystem" "37 checks: platform, component, dependency, workload. Version-gated applicability, glob-based selector." "Go"
            backupSubsystem = container "Backup Subsystem" "Three-stage pipeline: Discovery → Resolution → Writing. Parallel workers, dependency chasing." "Go"
            migrateSubsystem = container "Migrate Subsystem" "Action registry with lifecycle: CanApply → Prepare → Run. Interactive confirmations." "Go"
            k8sClient = container "Kubernetes Client Layer" "Wraps controller-runtime and client-go. Dynamic + metadata access, OLM discovery. QPS=50, Burst=100." "Go"
            outputFormatter = container "Output Formatter" "Renders results as table, JSON, or YAML" "Go"

            lintSubsystem -> k8sClient "Reads cluster resources"
            backupSubsystem -> k8sClient "Lists and resolves workloads"
            migrateSubsystem -> k8sClient "Reads and writes cluster resources"
            lintSubsystem -> outputFormatter "Formats diagnostic results"
            backupSubsystem -> outputFormatter "Formats backup output"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "OpenShift cluster control plane" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator (DataScienceCluster, DSCInitialization)" "Internal RHOAI"
        notebookController = softwareSystem "odh-notebook-controller" "Manages Notebook workloads" "Internal RHOAI"
        kserve = softwareSystem "KServe" "ML model serving (InferenceService, ServingRuntime)" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queueing (ClusterQueue, LocalQueue)" "Internal RHOAI"
        olm = softwareSystem "Operator Lifecycle Manager" "Operator management (Subscriptions, CSVs, PackageManifests)" "External"
        openshift = softwareSystem "OpenShift Platform" "Cluster infrastructure (ClusterVersion, ImageStreams)" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"
        serviceMesh = softwareSystem "Service Mesh Operator" "Service mesh management (Istio/OSSM)" "External"
        dspOperator = softwareSystem "Data Science Pipelines Operator" "Pipeline management (DSPA)" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI trustworthiness (GuardrailsOrchestrator)" "Internal RHOAI"
        ray = softwareSystem "Ray / CodeFlare" "Distributed computing (RayCluster, RayJob, AppWrapper)" "Internal RHOAI"
        trainingOperator = softwareSystem "Training Operator" "Distributed training (PyTorchJob)" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "UI management (AcceleratorProfile, HardwareProfile)" "Internal RHOAI"
        localFS = softwareSystem "Local Filesystem" "Backup YAML output destination" "External"

        user -> odhCli "Runs lint, backup, migrate commands via kubectl plugin"
        ciPipeline -> odhCli "Automated upgrade validation (JSON output)"

        odhCli -> k8sApiServer "All cluster queries and mutations" "HTTPS/6443, TLS 1.2+, Bearer Token"

        k8sClient -> rhodsOperator "Reads DSC, DSCI for version detection and upgrade readiness" "HTTPS/6443"
        k8sClient -> notebookController "Reads Notebooks for backup and compatibility checks" "HTTPS/6443"
        k8sClient -> kserve "Reads ISVCs, ServingRuntimes for deployment mode validation" "HTTPS/6443"
        k8sClient -> kueue "Reads ClusterQueues, LocalQueues for migration verification" "HTTPS/6443"
        k8sClient -> olm "Reads/creates Subscriptions, reads CSVs for operator management" "HTTPS/6443"
        k8sClient -> openshift "Reads ClusterVersion, ImageStreams for platform checks" "HTTPS/6443"
        k8sClient -> certManager "Reads OLM Subscriptions for dependency validation" "HTTPS/6443"
        k8sClient -> serviceMesh "Reads Subscriptions, PackageManifests for mesh checks" "HTTPS/6443"
        k8sClient -> dspOperator "Reads DSPA for pipeline renaming and config checks" "HTTPS/6443"
        k8sClient -> trustyai "Reads GuardrailsOrchestrator for config validation" "HTTPS/6443"
        k8sClient -> ray "Reads RayClusters, RayJobs, AppWrappers for CodeFlare checks" "HTTPS/6443"
        k8sClient -> trainingOperator "Reads PyTorchJobs for deprecation assessment" "HTTPS/6443"
        k8sClient -> dashboard "Reads AcceleratorProfiles, HardwareProfiles for migration" "HTTPS/6443"

        backupSubsystem -> localFS "Writes sanitized YAML backup files"
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

workspace {
    model {
        admin = person "Platform Admin" "RHOAI cluster administrator performing upgrade validation and management"

        odhCli = softwareSystem "odh-cli (rhai-cli)" "CLI tool for validating, managing, and migrating RHOAI deployments" {
            cobraCommands = container "Command Layer" "lint, get, backup, components, deps, migrate commands" "Go (Cobra)"
            checkRegistry = container "Check Registry" "37 diagnostic checks across 5 groups (dependency, service, platform, component, workload)" "Go"
            actionRegistry = container "Action Registry" "Migration actions (e.g., RHBOK Kueue migration)" "Go"
            depResolverRegistry = container "Dependency Resolver Registry" "Backup dependency resolution (ConfigMaps, Secrets, PVCs)" "Go"
            k8sClient = container "Kubernetes Client" "Dynamic client with Reader/Writer separation, QPS:50/Burst:100" "Go"
            versionDetector = container "Version Detector" "Detects RHOAI version from DSC/DSCI/CSV sources" "Go"
        }

        yq = softwareSystem "yq (vendored)" "YAML processor built with FIPS-compliant build tags" "Bundled Tool"
        upgradeHelpers = softwareSystem "rhoai-upgrade-helpers" "Shell/Python scripts for upgrade operations" "Bundled Tool"

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for all resource operations" "External"
        openshiftApi = softwareSystem "OpenShift API Server" "OpenShift-specific APIs (ClusterVersion, ImageStreams)" "External"
        olm = softwareSystem "Operator Lifecycle Manager" "Operator installation and version management" "External"

        dsc = softwareSystem "DataScienceCluster" "RHOAI platform singleton CR - version detection and component management" "Internal RHOAI"
        dsci = softwareSystem "DSCInitialization" "RHOAI initialization singleton CR - namespace discovery" "Internal RHOAI"
        rhoaiOperator = softwareSystem "RHOAI Operator" "rhods-operator / opendatahub-operator via OLM" "Internal RHOAI"

        kserve = softwareSystem "KServe" "InferenceService, ServingRuntime CRDs - workload validation" "Internal RHOAI"
        notebooks = softwareSystem "Kubeflow Notebooks" "Notebook CRDs - backup and lint checks" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "ClusterQueue, LocalQueue CRDs - migration and validation" "Internal RHOAI"
        pipelines = softwareSystem "Data Science Pipelines" "DSPA CRDs - backup with S3/MariaDB dependency resolution" "Internal RHOAI"
        ray = softwareSystem "Ray" "RayCluster, RayJob CRDs - AppWrapper cleanup checks" "Internal RHOAI"
        trainingOp = softwareSystem "Training Operator" "PyTorchJob CRDs - completion status checks" "Internal RHOAI"
        dashboard = softwareSystem "Dashboard" "AcceleratorProfile, HardwareProfile CRDs - migration readiness" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "GuardrailsOrchestrator CRDs - OTEL migration checks" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare" "AppWrapper CRDs - removal validation" "Internal RHOAI"

        odhGitops = softwareSystem "odh-gitops (GitHub)" "Remote dependency manifests (values.yaml, Chart.yaml)" "External"
        localFs = softwareSystem "Local Filesystem" "Backup YAML output and migration backups" "External"

        # User interactions
        admin -> odhCli "Runs lint/backup/migrate/get/deps/components commands"

        # Internal container relationships
        cobraCommands -> checkRegistry "Dispatches lint checks"
        cobraCommands -> actionRegistry "Dispatches migration actions"
        cobraCommands -> depResolverRegistry "Resolves backup dependencies"
        cobraCommands -> k8sClient "All Kubernetes operations"
        checkRegistry -> k8sClient "Read-only cluster access"
        actionRegistry -> k8sClient "Read/write cluster access"
        depResolverRegistry -> k8sClient "Read-only cluster access"
        cobraCommands -> versionDetector "RHOAI version detection"
        versionDetector -> k8sClient "Reads DSC/DSCI/CSV"

        # External interactions
        k8sClient -> k8sApi "HTTPS/6443, Bearer Token, TLS 1.2+"
        k8sClient -> openshiftApi "HTTPS/6443, Bearer Token, TLS 1.2+"
        k8sClient -> olm "HTTPS/6443, Bearer Token, TLS 1.2+"

        # Internal RHOAI interactions (all via K8s API)
        odhCli -> dsc "Read/Patch via K8s API" "HTTPS/6443"
        odhCli -> dsci "Read via K8s API" "HTTPS/6443"
        odhCli -> rhoaiOperator "Read OLM status" "HTTPS/6443"
        odhCli -> kserve "Read workloads for lint/backup" "HTTPS/6443"
        odhCli -> notebooks "Read workloads for lint/backup" "HTTPS/6443"
        odhCli -> kueue "Read/migrate ClusterQueues" "HTTPS/6443"
        odhCli -> pipelines "Read DSPAs for lint/backup" "HTTPS/6443"
        odhCli -> ray "Read workloads for lint" "HTTPS/6443"
        odhCli -> trainingOp "Read PyTorchJobs for lint" "HTTPS/6443"
        odhCli -> dashboard "Read profiles for migration checks" "HTTPS/6443"
        odhCli -> trustyai "Read Guardrails for lint" "HTTPS/6443"
        odhCli -> codeflare "Read AppWrappers for removal validation" "HTTPS/6443"

        # External service interactions
        odhCli -> odhGitops "Fetch dependency manifests (optional --refresh)" "HTTPS/443"
        odhCli -> localFs "Write backup YAML files"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Bundled Tool" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

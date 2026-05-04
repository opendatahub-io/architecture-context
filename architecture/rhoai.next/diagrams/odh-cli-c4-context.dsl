workspace {
    model {
        admin = person "Platform Administrator" "RHOAI cluster administrator performing upgrades, diagnostics, and migrations"

        odhCli = softwareSystem "odh-cli (kubectl-odh)" "CLI tool for validating, diagnosing, backing up, and migrating RHOAI deployments" {
            cobraCommands = container "Cobra Command Layer" "lint, backup, get, deps, components, migrate, version commands" "Go (Cobra)"
            lintEngine = container "Lint Engine" "37 diagnostic checks across 5 groups with version-aware gating" "Go"
            backupPipeline = container "Backup Pipeline" "Concurrent 3-stage pipeline: Discovery → Resolver → Writer" "Go"
            migrationFramework = container "Migration Framework" "Two-phase Prepare/Run with progress tracking" "Go"
            clientWrapper = container "K8s Client Wrapper" "client-go with QPS=50, Burst=100, Reader/Writer split" "Go (client-go)"
            resourceRegistry = container "Resource Type Registry" "40+ GVK/GVR definitions, single source of truth" "Go"
            outputEnvelope = container "Output Envelope" "cli.opendatahub.io/v1 self-describing output (table/JSON/YAML)" "Go"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API with RBAC enforcement" "External" {
            tags "External"
        }

        dsc = softwareSystem "DataScienceCluster" "Singleton CR managing RHOAI component lifecycle" "Internal ODH" {
            tags "Internal ODH"
        }

        dsci = softwareSystem "DSCInitialization" "Singleton CR for RHOAI initialization and namespace config" "Internal ODH" {
            tags "Internal ODH"
        }

        olm = softwareSystem "Operator Lifecycle Manager" "Manages operator installations, subscriptions, and CSVs" "External" {
            tags "External"
        }

        workloads = softwareSystem "User Workloads" "Notebooks, InferenceServices, DSPAs, RayClusters, PyTorchJobs, etc." "Internal ODH" {
            tags "Internal ODH"
        }

        certManager = softwareSystem "cert-manager" "Certificate management operator (required RHOAI dependency)" "External" {
            tags "External"
        }

        serviceMesh = softwareSystem "Service Mesh v3" "Istio-based service mesh (required for 2.x→3.x upgrade)" "External" {
            tags "External"
        }

        kueue = softwareSystem "Kueue / RHBOK" "Job queueing system (migration target: Kueue → Red Hat Build of Kueue)" "Internal ODH" {
            tags "Internal ODH"
        }

        github = softwareSystem "GitHub (odh-gitops)" "Public repository hosting dependency manifests" "External" {
            tags "External"
        }

        filesystem = softwareSystem "Local Filesystem" "Stores backup YAML files and migration artifacts" "External" {
            tags "External"
        }

        admin -> odhCli "Runs kubectl odh commands" "CLI"
        odhCli -> k8sApi "Queries and patches resources" "HTTPS/6443 TLS 1.2+ Bearer Token"
        odhCli -> dsc "Reads version, component state; patches managementState" "HTTPS/6443 via K8s API"
        odhCli -> dsci "Reads version, namespace, ServiceMesh state" "HTTPS/6443 via K8s API"
        odhCli -> olm "Checks operator status; creates Subscriptions (migrate)" "HTTPS/6443 via K8s API"
        odhCli -> workloads "Lists and inspects for lint checks and backup" "HTTPS/6443 via K8s API"
        odhCli -> certManager "Validates installation (lint dependency check)" "HTTPS/6443 via K8s API"
        odhCli -> serviceMesh "Validates catalog availability (lint dependency check)" "HTTPS/6443 via K8s API"
        odhCli -> kueue "Validates data integrity; migrates to RHBOK" "HTTPS/6443 via K8s API"
        odhCli -> github "Fetches dependency manifests (optional --refresh)" "HTTPS/443 TLS 1.2+"
        odhCli -> filesystem "Writes backup YAML files and migration artifacts" "Local I/O"

        cobraCommands -> lintEngine "Delegates lint execution"
        cobraCommands -> backupPipeline "Delegates backup execution"
        cobraCommands -> migrationFramework "Delegates migration execution"
        cobraCommands -> outputEnvelope "Formats output"
        lintEngine -> clientWrapper "Reads cluster state (Reader interface only)"
        backupPipeline -> clientWrapper "Reads resources and dependencies"
        migrationFramework -> clientWrapper "Reads and writes cluster state (full Client)"
        clientWrapper -> resourceRegistry "Resolves GVK/GVR definitions"
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
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

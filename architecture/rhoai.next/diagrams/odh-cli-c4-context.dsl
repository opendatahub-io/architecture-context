workspace {
    model {
        admin = person "Platform Admin" "RHOAI cluster administrator performing upgrade readiness, diagnostics, and migrations"
        cicd = person "CI/CD Pipeline" "Automated pipeline runner executing lint checks and backup operations"

        odhCli = softwareSystem "odh-cli" "CLI tool for validating, diagnosing, backing up, and migrating RHOAI deployments (kubectl plugin)" {
            cobraRoot = container "Cobra CLI Framework" "Root command with AddFlags/Complete/Validate/Run lifecycle" "Go (cobra)"
            lintEngine = container "Lint Engine" "37 diagnostic checks across 5 groups (dependency, service, platform, component, workload)" "Go"
            backupPipeline = container "Backup Pipeline" "Three-stage concurrent pipeline: Discovery → Resolver → Writer" "Go (errgroup)"
            migrateFramework = container "Migration Framework" "Two-phase Action/Task pattern with progress tracking" "Go"
            depsChecker = container "Dependency Checker" "Validates required operator dependencies against manifest" "Go"
            componentsMgr = container "Components Manager" "Component health enrichment and state management" "Go"
            getMgr = container "Resource Lister" "Lists workload resources across namespaces" "Go"
            clientWrapper = container "Kubernetes Client" "client-go wrapper with QPS=50/Burst=100, Reader/Writer split" "Go (client-go)"
            resourceTypes = container "Resource Type Registry" "40+ GVK/GVR definitions — single source of truth" "Go"
            printerPkg = container "Output Printer" "Table, JSON, YAML renderers with envelope wrapper (cli.opendatahub.io/v1)" "Go"
        }

        containerImage = softwareSystem "Container Image" "quay.io/rhoai/rhoai-upgrade-helpers-rhel9 — bundles CLI + kubectl + oc + yq + Python helpers" "Distribution"

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane (v1.29+)" "External"
        openshiftApi = softwareSystem "OpenShift API" "OpenShift extensions — ClusterVersion, Routes (v4.14+)" "External"
        olm = softwareSystem "Operator Lifecycle Manager" "Manages operator subscriptions, CSVs, catalogs (v0.39+)" "External"
        certManager = softwareSystem "cert-manager Operator" "Certificate management — required RHOAI dependency" "External"
        serviceMeshV3 = softwareSystem "Service Mesh v3 Operator" "Service mesh — required for 2.x→3.x upgrade" "External"

        dsc = softwareSystem "DataScienceCluster" "Singleton CR managing RHOAI component lifecycle" "Internal ODH"
        dsci = softwareSystem "DSCInitialization" "Singleton CR for platform initialization and namespace config" "Internal ODH"
        notebooks = softwareSystem "Notebooks (kubeflow.org)" "Jupyter notebook workloads" "Internal ODH"
        inferenceServices = softwareSystem "InferenceServices (kserve.io)" "ML model serving workloads" "Internal ODH"
        dspa = softwareSystem "DataSciencePipelinesApplication" "ML pipeline definitions" "Internal ODH"
        kueue = softwareSystem "Kueue (kueue.x-k8s.io)" "Job queuing system — ClusterQueues and LocalQueues" "Internal ODH"
        otherWorkloads = softwareSystem "Other Workloads" "RayClusters, PyTorchJobs, GuardrailsOrchestrators, LlamaStack, LLMInferenceServices" "Internal ODH"

        github = softwareSystem "GitHub (raw.githubusercontent.com)" "Public repo for odh-gitops dependency manifests" "External"
        filesystem = softwareSystem "Local Filesystem" "Backup YAML output and migration backup files" "External"

        konflux = softwareSystem "Konflux Build System" "Hermetic multi-arch container builds with FIPS compliance" "Build"

        # User interactions
        admin -> odhCli "Runs kubectl odh lint|backup|migrate|deps|components|get" "CLI"
        cicd -> odhCli "Executes lint checks in CI pipeline" "CLI (--json output)"

        # CLI to infrastructure
        odhCli -> k8sApi "Queries and mutates cluster resources" "HTTPS/6443, TLS 1.2+, Bearer Token"
        odhCli -> openshiftApi "Reads ClusterVersion, Routes" "HTTPS/6443, TLS 1.2+, Bearer Token"
        odhCli -> olm "Reads Subscriptions/CSVs, creates Subscriptions (migrate)" "HTTPS/6443, TLS 1.2+, Bearer Token"
        odhCli -> github "Fetches dependency manifests (optional --refresh)" "HTTPS/443, No Auth"
        odhCli -> filesystem "Writes backup YAML files" "Local I/O"

        # CLI reads ODH resources
        odhCli -> dsc "Reads version, component state; patches managementState (migrate)" "HTTPS/6443"
        odhCli -> dsci "Reads version, namespace config, ServiceMesh state" "HTTPS/6443"
        odhCli -> notebooks "Lists and backs up notebook workloads with dependencies" "HTTPS/6443"
        odhCli -> inferenceServices "Lists ISVCs, checks serverless/modelmesh/accelerator conditions" "HTTPS/6443"
        odhCli -> dspa "Lists and backs up DSPA with 9-field dependency resolution" "HTTPS/6443"
        odhCli -> kueue "Validates data integrity (3 invariants), migration backup/verify" "HTTPS/6443"
        odhCli -> otherWorkloads "Reads for lint checks and workload listing" "HTTPS/6443"

        # Lint checks dependencies
        odhCli -> certManager "Validates installation (lint dependency check)" "HTTPS/6443"
        odhCli -> serviceMeshV3 "Validates catalog availability for upgrade (lint check)" "HTTPS/6443"

        # Internal container relationships
        cobraRoot -> lintEngine "Dispatches lint command"
        cobraRoot -> backupPipeline "Dispatches backup command"
        cobraRoot -> migrateFramework "Dispatches migrate command"
        cobraRoot -> depsChecker "Dispatches deps command"
        cobraRoot -> componentsMgr "Dispatches components command"
        cobraRoot -> getMgr "Dispatches get command"

        lintEngine -> clientWrapper "Uses Reader interface (read-only)"
        backupPipeline -> clientWrapper "Uses Reader interface"
        migrateFramework -> clientWrapper "Uses full Client (read + write)"
        depsChecker -> clientWrapper "Uses Reader interface"
        componentsMgr -> clientWrapper "Uses full Client"
        getMgr -> clientWrapper "Uses Reader interface"

        clientWrapper -> resourceTypes "Resolves GVK/GVR for API calls"

        lintEngine -> printerPkg "Renders diagnostic results"
        backupPipeline -> printerPkg "Renders backup summaries"
        depsChecker -> printerPkg "Renders dependency status"
        componentsMgr -> printerPkg "Renders component health"
        getMgr -> printerPkg "Renders resource listings"

        # Build
        konflux -> containerImage "Builds hermetic multi-arch image" "Tekton, FIPS"
    }

    views {
        systemContext odhCli "SystemContext" {
            include *
            exclude containerImage konflux
            autoLayout
        }

        container odhCli "Containers" {
            include *
            exclude containerImage konflux
            autoLayout
        }

        systemContext odhCli "BuildContext" {
            include odhCli containerImage konflux admin cicd
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
            element "Distribution" {
                background #f5a623
                color #ffffff
            }
            element "Build" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

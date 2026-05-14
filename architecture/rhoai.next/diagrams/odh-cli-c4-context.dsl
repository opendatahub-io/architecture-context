workspace {
    model {
        admin = person "Platform Admin / SRE" "Manages RHOAI deployments, performs upgrades and diagnostics"
        cicd = person "CI/CD Pipeline" "Automated upgrade readiness checks"

        odhCli = softwareSystem "odh-cli (kubectl-odh)" "CLI tool for validating, diagnosing, backing up, and migrating RHOAI deployments" {
            lintEngine = container "Lint Engine" "37 diagnostic checks across 5 groups for upgrade readiness assessment" "Go (cobra + client-go)"
            backupPipeline = container "Backup Pipeline" "Concurrent 3-stage pipeline: Discovery → Resolver → Writer" "Go (errgroup + channels)"
            migrateFramework = container "Migration Framework" "Two-phase Action/Task pattern: Prepare + Run with progress tracking" "Go"
            getCmd = container "Get Command" "Resource listing with output format support" "Go"
            depsCmd = container "Deps Command" "Dependency checking against odh-gitops manifests" "Go"
            componentsCmd = container "Components Command" "Component management with health enrichment" "Go"
            clientWrapper = container "K8s Client Wrapper" "client-go wrapper with QPS=50, Burst=100, Reader/Writer split" "Go (client-go)"
            resourceRegistry = container "Resource Type Registry" "Single source of truth for 40+ GVK/GVR definitions" "Go"
            outputEnvelope = container "Output Envelope" "Self-describing cli.opendatahub.io/v1 format" "Go"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for all resource operations" "External" {
            tags "External"
        }

        openshiftApi = softwareSystem "OpenShift API" "ClusterVersion detection, Route/ImageStream access" "External" {
            tags "External"
        }

        olm = softwareSystem "OLM (Operator Lifecycle Manager)" "Operator installation and lifecycle management" "External" {
            tags "External"
        }

        dsc = softwareSystem "DataScienceCluster" "Singleton CR managing ODH/RHOAI platform state" "Internal ODH" {
            tags "Internal"
        }

        dsci = softwareSystem "DSCInitialization" "Singleton CR for platform initialization and namespace config" "Internal ODH" {
            tags "Internal"
        }

        certManager = softwareSystem "cert-manager" "Certificate management operator" "External" {
            tags "External"
        }

        serviceMesh = softwareSystem "Service Mesh v3" "Istio-based service mesh operator" "External" {
            tags "External"
        }

        notebooks = softwareSystem "Notebooks (kubeflow.org)" "Jupyter notebook workloads" "Internal ODH" {
            tags "Internal"
        }

        kserve = softwareSystem "KServe" "ML model serving (InferenceServices, ServingRuntimes)" "Internal ODH" {
            tags "Internal"
        }

        dspa = softwareSystem "Data Science Pipelines" "Pipeline orchestration (DataSciencePipelinesApplication)" "Internal ODH" {
            tags "Internal"
        }

        kueue = softwareSystem "Kueue" "Job queueing (ClusterQueues, LocalQueues)" "Internal ODH" {
            tags "Internal"
        }

        ray = softwareSystem "Ray (ray.io)" "Distributed computing (RayClusters, RayJobs)" "Internal ODH" {
            tags "Internal"
        }

        guardrails = softwareSystem "TrustyAI Guardrails" "AI safety orchestration" "Internal ODH" {
            tags "Internal"
        }

        github = softwareSystem "GitHub (odh-gitops)" "Dependency manifest source repository" "External" {
            tags "External"
        }

        localFs = softwareSystem "Local Filesystem" "Backup YAML output and migration backups" "External" {
            tags "External"
        }

        # User relationships
        admin -> odhCli "Runs CLI commands (lint, backup, migrate, get, deps, components)" "kubectl plugin"
        cicd -> odhCli "Automated upgrade readiness checks" "CLI invocation"

        # Internal container relationships
        lintEngine -> clientWrapper "Reads cluster state" "client.Reader"
        backupPipeline -> clientWrapper "Reads workloads and dependencies" "client.Reader"
        migrateFramework -> clientWrapper "Reads and writes resources" "client.Reader + client.Writer"
        getCmd -> clientWrapper "Lists resources" "client.Reader"
        depsCmd -> clientWrapper "Checks installed operators" "client.Reader"
        componentsCmd -> clientWrapper "Queries component health" "client.Reader + client.Writer"

        lintEngine -> resourceRegistry "Resolves GVK/GVR" "Go import"
        backupPipeline -> resourceRegistry "Resolves GVK/GVR" "Go import"

        lintEngine -> outputEnvelope "Formats results" "Go import"
        getCmd -> outputEnvelope "Formats output" "Go import"

        # External system relationships
        clientWrapper -> k8sApi "All cluster queries" "HTTPS/6443, TLS 1.2+, Bearer Token"
        clientWrapper -> openshiftApi "ClusterVersion, Routes" "HTTPS/6443, TLS 1.2+, Bearer Token"
        clientWrapper -> olm "Subscriptions, CSVs, PackageManifests" "HTTPS/6443, TLS 1.2+, Bearer Token"

        odhCli -> dsc "Read spec/status, Patch managementState" "HTTPS/6443"
        odhCli -> dsci "Read spec/status" "HTTPS/6443"
        odhCli -> notebooks "List, backup with dependency resolution" "HTTPS/6443"
        odhCli -> kserve "List InferenceServices, ServingRuntimes, lint checks" "HTTPS/6443"
        odhCli -> dspa "List, backup with 9-field resolution" "HTTPS/6443"
        odhCli -> kueue "List ClusterQueues/LocalQueues, migration backup/verify" "HTTPS/6443"
        odhCli -> ray "List RayClusters/RayJobs, lint checks" "HTTPS/6443"
        odhCli -> guardrails "List GuardrailsOrchestrators, lint checks" "HTTPS/6443"

        depsCmd -> github "Fetch dependency manifests (optional --refresh)" "HTTPS/443"
        backupPipeline -> localFs "Write backup YAML files" "Local I/O"
        migrateFramework -> localFs "Write migration backup files" "Local I/O"
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
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

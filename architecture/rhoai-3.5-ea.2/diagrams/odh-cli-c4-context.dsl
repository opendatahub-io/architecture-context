workspace {
    model {
        operator = person "Cluster Operator" "RHOAI cluster administrator performing upgrades, diagnostics, and migrations"
        ciPipeline = person "CI/CD Pipeline" "Automated upgrade workflows using the containerized CLI"

        odhCli = softwareSystem "odh-cli (rhai-cli)" "CLI tool for inspecting, diagnosing, linting, and migrating RHOAI clusters" {
            cliMain = container "rhai-cli Binary" "Primary CLI with lint, migrate, status, components, deps, events, logs, get, backup commands" "Go 1.26"
            k8sClientWrapper = container "K8s Client Wrapper" "Unified client wrapping dynamic, metadata, discovery, OLM, core, and authorization clients" "Go Library"
            checkRegistry = container "Lint Check Registry" "38+ version-aware checks in 5 groups (dependencies, services, platform, components, workloads)" "Go Library"
            actionRegistry = container "Migration Action Registry" "Version-aware migration actions with two-phase execution (prepare/run)" "Go Library"
            depsManifest = container "Embedded Dependency Manifest" "odh-gitops values.yaml embedded at build time via Go embed" "Static Data"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Target cluster API for all resource operations" "External" {
            tags "External"
        }

        openshiftApi = softwareSystem "OpenShift API Server" "OpenShift-specific APIs (Routes, ClusterVersion)" "External" {
            tags "External"
        }

        olm = softwareSystem "Operator Lifecycle Manager" "Operator dependency management and version detection" "External" {
            tags "External"
        }

        odhOperator = softwareSystem "OpenDataHub Operator" "RHOAI platform operator managing DSC and DSCI CRs" "Internal ODH" {
            tags "Internal ODH"
        }

        kserve = softwareSystem "KServe" "Model serving platform (InferenceService, ServingRuntime CRDs)" "Internal ODH" {
            tags "Internal ODH"
        }

        kubeflow = softwareSystem "Kubeflow" "Notebook and Training Operator workloads" "Internal ODH" {
            tags "Internal ODH"
        }

        dsPipelines = softwareSystem "Data Science Pipelines" "AI pipeline management (DSPA CRDs)" "Internal ODH" {
            tags "Internal ODH"
        }

        trustyai = softwareSystem "TrustyAI" "AI explainability and fairness service with REST API for metrics" "Internal ODH" {
            tags "Internal ODH"
        }

        kueue = softwareSystem "Kueue" "Job queueing system (ClusterQueue, LocalQueue CRDs)" "Internal ODH" {
            tags "Internal ODH"
        }

        raycluster = softwareSystem "Ray" "Distributed computing framework (RayCluster CRDs)" "Internal ODH" {
            tags "Internal ODH"
        }

        certManager = softwareSystem "cert-manager" "Certificate management for TLS" "External" {
            tags "External"
        }

        odhGitops = softwareSystem "odh-gitops (GitHub)" "Dependency manifests repository (build-time only)" "External" {
            tags "External"
        }

        # User relationships
        operator -> odhCli "Runs CLI commands (kubectl odh ...)" "CLI"
        ciPipeline -> odhCli "Executes automated migrations" "Container Image"

        # Internal relationships
        cliMain -> k8sClientWrapper "Uses for all cluster operations"
        cliMain -> checkRegistry "Executes lint checks"
        cliMain -> actionRegistry "Executes migration actions"
        cliMain -> depsManifest "Reads dependency graph"

        # External relationships
        odhCli -> k8sApi "All resource CRUD operations" "HTTPS/6443 TLS 1.2+ Bearer Token"
        odhCli -> openshiftApi "Routes, ClusterVersion" "HTTPS/6443 TLS 1.2+ Bearer Token"
        odhCli -> olm "Dependency management, version detection" "HTTPS/6443 TLS 1.2+ Bearer Token"
        odhCli -> odhOperator "Reads DSC, DSCI, Component CRs" "HTTPS/6443 TLS 1.2+"
        odhCli -> kserve "Reads/patches InferenceService, ServingRuntime" "HTTPS/6443 TLS 1.2+"
        odhCli -> kubeflow "Reads/patches Notebooks, Training jobs" "HTTPS/6443 TLS 1.2+"
        odhCli -> dsPipelines "Reads/patches DSPA, migrates v1alpha1→v1" "HTTPS/6443 TLS 1.2+"
        odhCli -> trustyai "Metrics backup/restore via REST API" "HTTPS/443 TLS 1.2+ Bearer Token"
        odhCli -> kueue "Reads ClusterQueue/LocalQueue for RHBOK migration" "HTTPS/6443 TLS 1.2+"
        odhCli -> raycluster "Backup, delete-and-recreate migration" "HTTPS/6443 TLS 1.2+"
        odhCli -> certManager "Lint dependency checks" "HTTPS/6443 TLS 1.2+"
        odhCli -> odhGitops "Fetches dependency manifests (build-time only)" "HTTPS/443"
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

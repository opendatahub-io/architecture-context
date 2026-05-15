workspace {
    model {
        admin = person "Cluster Admin" "Manages RHOAI deployments, performs upgrades, validates cluster readiness"
        ciPipeline = person "CI/CD Pipeline" "Automated upgrade validation and pre-flight checks"

        odhCli = softwareSystem "odh-cli (rhai-cli)" "CLI tool for validating, diagnosing, and managing RHOAI deployments on Kubernetes clusters" {
            commandLayer = container "Command Layer" "lint, backup, deps, status, logs, components, get, migrate commands" "Go (cobra)"
            lintEngine = container "Lint Engine" "30+ version-aware diagnostic checks with sequential execution, DiagnosticResult pattern" "Go"
            backupEngine = container "Backup Engine" "Workload discovery and transitive dependency resolution with registry pattern" "Go"
            migrateEngine = container "Migration Framework" "Orchestrated cluster migrations with prepare-then-execute workflow" "Go"
            clientLayer = container "Client Layer" "Kubernetes API client with QPS=50, Burst=100 throttling" "Go (client-go, controller-runtime)"
            outputLayer = container "Output Layer" "JSON/YAML/Table output with envelope format and JSON Schema support" "Go"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster API endpoint for all resource operations" "External Infrastructure" {
            tags "External"
        }

        openshiftApi = softwareSystem "OpenShift API" "ClusterVersion, ImageStream, Route APIs" "External Infrastructure" {
            tags "External"
        }

        olm = softwareSystem "OLM" "Operator Lifecycle Manager for dependency tracking and installation" "External Infrastructure" {
            tags "External"
        }

        odhOperator = softwareSystem "opendatahub-operator" "RHOAI platform operator (clusterhealth library)" "Internal ODH" {
            tags "Internal ODH"
        }

        odhGitops = softwareSystem "odh-gitops (GitHub)" "Dependency manifest repository (values.yaml, Chart.yaml)" "External Service" {
            tags "External Service"
        }

        dsc = softwareSystem "DataScienceCluster CR" "Platform component management state and version detection" "Internal ODH" {
            tags "Internal ODH"
        }

        dsci = softwareSystem "DSCInitialization CR" "Platform initialization state and ServiceMesh configuration" "Internal ODH" {
            tags "Internal ODH"
        }

        notebooks = softwareSystem "Notebook CRs" "Jupyter notebook workloads (kubeflow.org/v1)" "Internal ODH" {
            tags "Internal ODH"
        }

        kserve = softwareSystem "InferenceService CRs" "ML model serving workloads (serving.kserve.io)" "Internal ODH" {
            tags "Internal ODH"
        }

        kueue = softwareSystem "Kueue CRs" "Job queueing and scheduling (kueue.x-k8s.io)" "Internal ODH" {
            tags "Internal ODH"
        }

        dspa = softwareSystem "DSPA CRs" "Data Science Pipelines (opendatahub.io)" "Internal ODH" {
            tags "Internal ODH"
        }

        certManager = softwareSystem "cert-manager Operator" "Certificate management dependency" "External" {
            tags "External"
        }

        serviceMesh = softwareSystem "Service Mesh Operator" "Service mesh v2/v3 networking" "External" {
            tags "External"
        }

        admin -> odhCli "Runs CLI commands (lint, backup, status, deps, logs)" "CLI / kubectl plugin"
        ciPipeline -> odhCli "Automated upgrade validation" "CLI with JSON output, exit codes"

        commandLayer -> lintEngine "Executes lint checks"
        commandLayer -> backupEngine "Executes workload backup"
        commandLayer -> migrateEngine "Executes migrations"
        commandLayer -> outputLayer "Formats output"
        lintEngine -> clientLayer "Read-only CRD queries"
        backupEngine -> clientLayer "Workload and dependency reads"
        migrateEngine -> clientLayer "Migration operations"

        clientLayer -> k8sApiServer "All cluster operations" "HTTPS/6443, TLS 1.2+, Bearer Token"
        clientLayer -> openshiftApi "Version detection, image analysis" "HTTPS/6443, TLS 1.2+"
        clientLayer -> olm "Operator queries, dependency install" "HTTPS/6443, TLS 1.2+"

        odhCli -> odhOperator "Cluster health check functions" "Go library import"
        odhCli -> odhGitops "Fetch dependency manifest (optional)" "HTTPS/443, TLS 1.2+"

        odhCli -> dsc "Version detection, component state" "CRD Read via K8s API"
        odhCli -> dsci "Platform init state, ServiceMesh config" "CRD Read via K8s API"
        odhCli -> notebooks "Backup, lint checks, image compat" "CRD Read via K8s API"
        odhCli -> kserve "Backup, deployment mode validation" "CRD Read via K8s API"
        odhCli -> kueue "Management state, data integrity" "CRD Read via K8s API"
        odhCli -> dspa "InstructLab removal, version migration" "CRD Read via K8s API"
        odhCli -> certManager "Dependency status reporting" "OLM Subscription Read"
        odhCli -> serviceMesh "SM v2/v3 upgrade validation" "OLM Subscription Read"
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
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "External Infrastructure" {
                background #999999
                color #ffffff
            }
        }
    }
}

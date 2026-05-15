workspace {
    model {
        user = person "Platform Engineer / SRE" "Runs upgrade readiness checks, backups, and migrations for RHOAI clusters"
        ciPipeline = person "CI Pipeline" "Automated execution of lint checks in CI/CD workflows"

        odhCli = softwareSystem "odh-cli (kubectl-odh)" "CLI tool for validating, backing up, and migrating RHOAI deployments" {
            lintFramework = container "Lint Framework" "38 upgrade readiness checks organized in 5 groups: platform, components, dependencies, workloads, services" "Go (cobra)"
            backupPipeline = container "Backup Pipeline" "Discovery → Dependency Resolution → Writer pipeline for exporting workloads to portable YAML" "Go"
            migrateFramework = container "Migration Framework" "Two-phase Action pattern (Prepare/Run) for version-aware cluster migrations" "Go"
            k8sClient = container "Unified K8s Client" "Aggregated dynamic, discovery, OLM, and metadata clients with Reader/Writer interfaces" "Go (client-go)"
            containerImage = container "Container Image" "All-in-one upgrade toolkit: CLI + oc + kubectl + jq + yq + Python scripts" "OCI (ose-cli-rhel9)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane providing access to all resources" "External"
        openshift = softwareSystem "OpenShift Platform" "Container platform with ClusterVersion, ImageStreams, Ingress Operator" "External"
        olm = softwareSystem "Operator Lifecycle Manager" "Manages operator subscriptions, CSVs, and package manifests" "External"

        dsc = softwareSystem "DataScienceCluster" "RHOAI platform CRD - component management states" "Internal RHOAI"
        dsci = softwareSystem "DSCInitialization" "RHOAI platform CRD - initialization state, service mesh config" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI operator providing platform version via CSV" "Internal RHOAI"

        certManager = softwareSystem "cert-manager Operator" "Certificate management operator" "External Dependency"
        serviceMeshV3 = softwareSystem "Service Mesh v3 Operator" "Istio-based service mesh for RHOAI 3.x" "External Dependency"
        kueueOperator = softwareSystem "Red Hat Build of Kueue" "Standalone Kueue operator installed during migration" "External Dependency"

        notebooks = softwareSystem "Notebook Controller" "Manages Jupyter notebook workloads" "Internal RHOAI"
        kserve = softwareSystem "KServe" "ML model serving platform" "Internal RHOAI"
        pipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queueing system" "Internal RHOAI"

        localFS = softwareSystem "Local Filesystem" "Backup output destination for portable YAML files" "External"

        # Relationships
        user -> odhCli "Runs lint, backup, migrate commands"
        ciPipeline -> odhCli "Executes lint checks in CI"

        lintFramework -> k8sClient "Uses for API queries"
        backupPipeline -> k8sClient "Uses for resource discovery"
        migrateFramework -> k8sClient "Uses for read/write operations"

        k8sClient -> k8sAPI "HTTPS/6443 - Bearer Token / Client Cert" "TLS 1.2+"

        odhCli -> dsc "Reads component management states" "HTTPS/6443"
        odhCli -> dsci "Reads platform initialization state" "HTTPS/6443"
        odhCli -> rhodsOperator "Detects installed RHOAI version" "HTTPS/6443"
        odhCli -> openshift "Validates OpenShift version >= 4.19.9" "HTTPS/6443"
        odhCli -> olm "Queries operator installations" "HTTPS/6443"
        odhCli -> certManager "Validates installation status" "HTTPS/6443"
        odhCli -> serviceMeshV3 "Validates availability in catalog" "HTTPS/6443"
        odhCli -> kueueOperator "Installs during RHBOK migration" "HTTPS/6443"

        odhCli -> notebooks "Inspects notebook workloads" "HTTPS/6443"
        odhCli -> kserve "Inspects InferenceServices" "HTTPS/6443"
        odhCli -> pipelines "Inspects DSPA resources" "HTTPS/6443"
        odhCli -> kueue "Validates queue integrity" "HTTPS/6443"

        backupPipeline -> localFS "Writes portable YAML files"
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
            element "External Dependency" {
                background #b0bec5
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

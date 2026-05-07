workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines via Data Science Pipelines"
        dspOperator = person "DSP Operator" "Deploys and configures Argo Workflows via data-science-pipelines-operator"

        argoWorkflows = softwareSystem "Argo Workflows" "Kubernetes-native workflow execution engine for Data Science Pipelines in RHOAI" {
            workflowController = container "workflow-controller" "Watches Workflow CRDs, orchestrates pod creation, DAG/step scheduling, cron scheduling, artifact GC, workflow archival" "Go (client-go informers)" {
                cronController = component "Cron Controller" "Schedules workflows from CronWorkflow CRs" "Go"
                gcController = component "Artifact GC Controller" "Manages artifact garbage collection" "Go"
                archiver = component "Workflow Archiver" "Persists completed workflows to SQL database" "Go (upper/db)"
                leaderElection = component "Leader Election" "Lease-based HA coordination" "Go (client-go)"
            }
            argoexec = container "argoexec" "Executor sidecar/init container in workflow pods; manages artifact I/O, parameter extraction, container lifecycle via emissary pattern" "Go (emissary pattern)"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform and API server" "External"
        dspOperatorSystem = softwareSystem "Data Science Pipelines Operator" "Deploys and configures Argo Workflows controller and executor images" "Internal RHOAI"
        s3Storage = softwareSystem "S3 / Minio" "Pipeline artifact storage (upload/download)" "External"
        postgresql = softwareSystem "PostgreSQL" "Optional workflow archive and node status offloading" "External"
        gcs = softwareSystem "Google Cloud Storage" "Alternative artifact storage backend" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Alternative artifact storage backend" "External"
        gitRepos = softwareSystem "Git Repositories" "Git-based artifact cloning" "External"
        hdfs = softwareSystem "HDFS" "Hadoop-based artifact storage" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"

        # Relationships
        dataScientist -> dspOperatorSystem "Submits pipeline runs via"
        dspOperator -> dspOperatorSystem "Configures pipeline infrastructure"
        dspOperatorSystem -> argoWorkflows "Deploys and creates Workflow CRs"
        argoWorkflows -> kubernetes "CRUD on Pods, Workflows, ConfigMaps, Secrets" "HTTPS/443, SA Bearer Token"
        argoWorkflows -> s3Storage "Upload/download pipeline artifacts" "S3 API HTTPS/443, AccessKey/SecretKey"
        argoWorkflows -> postgresql "Archive completed workflows" "PostgreSQL/5432, Secret credentials"
        argoWorkflows -> gcs "Upload/download artifacts (alternative)" "HTTPS/443, ServiceAccountKey"
        argoWorkflows -> azureBlob "Upload/download artifacts (alternative)" "HTTPS/443, SharedKey/SAS"
        argoWorkflows -> gitRepos "Clone git-based artifacts" "SSH/22 or HTTPS/443"
        argoWorkflows -> hdfs "HDFS artifact operations" "Hadoop RPC/9000, Kerberos"
        prometheus -> argoWorkflows "Scrapes metrics" "HTTP/9090"

        workflowController -> kubernetes "Watch/create/update Workflows, Pods, CRDs" "HTTPS/443"
        argoexec -> kubernetes "Patch WorkflowTaskResult, read Secrets" "HTTPS/443"
        argoexec -> s3Storage "Artifact upload/download" "S3 API HTTPS/443"
        archiver -> postgresql "Store workflow JSON" "PostgreSQL/5432"
    }

    views {
        systemContext argoWorkflows "SystemContext" {
            include *
            autoLayout
        }

        container argoWorkflows "Containers" {
            include *
            autoLayout
        }

        component workflowController "ControllerComponents" {
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #9b59b6
                color #ffffff
                shape Person
            }
        }
    }
}

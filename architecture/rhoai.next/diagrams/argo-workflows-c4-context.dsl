workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages ML pipeline runs via Data Science Pipelines"
        dspOperator = softwareSystem "Data Science Pipelines Operator" "Deploys and configures Argo Workflows controller and executor images" "Internal RHOAI"

        argoWorkflows = softwareSystem "Argo Workflows" "Kubernetes-native workflow execution engine for Data Science Pipelines" {
            workflowController = container "Workflow Controller" "Watches Workflow CRDs, orchestrates pod creation, DAG/step scheduling, cron scheduling, artifact GC, workflow archival" "Go / client-go informers" {
                cronController = component "Cron Controller" "Schedules workflows based on CronWorkflow cron expressions" "Go"
                artifactGCController = component "Artifact GC Controller" "Manages artifact garbage collection tasks" "Go"
                reconciler = component "Workflow Reconciler" "32 parallel workers for workflow reconciliation" "Go"
                informers = component "Informer Cache" "10+ custom indexes (UID, phase, semaphore, labels, conditions)" "client-go"
            }
            argoexec = container "argoexec" "Executor sidecar/init in workflow pods - artifact I/O, parameter extraction, container lifecycle" "Go (emissary pattern)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Container orchestration platform API" "External"
        s3Storage = softwareSystem "S3 / Minio" "Artifact storage for pipeline step inputs/outputs" "External"
        postgresql = softwareSystem "PostgreSQL" "Optional workflow archive and node status offloading" "External"
        mysql = softwareSystem "MySQL" "Alternative database for workflow archival" "External"
        gcs = softwareSystem "Google Cloud Storage" "Alternative artifact storage backend" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Alternative artifact storage backend" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        gitRepos = softwareSystem "Git Repositories" "Git-based artifact cloning" "External"

        # Relationships
        user -> dspOperator "Creates pipeline runs via"
        dspOperator -> argoWorkflows "Deploys controller, configures executor image, creates Workflow CRs"

        workflowController -> k8sAPI "CRUD on Pods, Workflows, ConfigMaps, CronWorkflows, WorkflowTaskSets" "HTTPS/443 TLS 1.2+ ServiceAccount Bearer"
        argoexec -> k8sAPI "Patch WorkflowTaskResult, read Secrets" "HTTPS/443 TLS 1.2+ ServiceAccount Bearer"
        argoexec -> s3Storage "Upload/download pipeline artifacts" "HTTPS/443 TLS 1.2+ AccessKey/SecretKey"
        argoexec -> gcs "Upload/download artifacts (alternative)" "HTTPS/443 TLS 1.2+"
        argoexec -> azureBlob "Upload/download artifacts (alternative)" "HTTPS/443 TLS 1.2+"
        argoexec -> gitRepos "Clone git artifacts" "SSH/22 or HTTPS/443"

        workflowController -> postgresql "Archive workflows, offload node status (optional)" "PostgreSQL/5432 Configurable TLS"
        workflowController -> mysql "Archive workflows (alternative, optional)" "MySQL/3306 Configurable TLS"

        prometheus -> workflowController "Scrape metrics" "HTTP/9090"

        workflowController -> argoexec "Creates workflow pods with argoexec sidecar" "Kubernetes Pod API"
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
                background #1168bd
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
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

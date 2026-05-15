workspace {
    model {
        dataScientist = person "Data Scientist" "Defines, submits, and monitors ML pipelines using KFP SDK or Dashboard"
        platformAdmin = person "Platform Admin" "Configures DataSciencePipelinesApplication CR via DSPO"

        dsp = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines backend for defining, scheduling, and executing ML workflows as Argo Workflows on Kubernetes" {
            apiServer = container "API Server" "Central REST/gRPC API for pipeline management, run orchestration, and experiment tracking" "Go Service" {
                tags "Primary"
            }
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflow status and persists run state to the API server database" "Go Service" {
                tags "Primary"
            }
            swfController = container "Scheduled Workflow Controller" "Manages ScheduledWorkflow CRDs to create Argo Workflows on cron/periodic schedules" "Go Controller" {
                tags "Primary"
            }
            driver = container "Driver" "Pre-execution orchestration: input resolution, cache checking, pod spec patching" "Go CLI (Argo init step)" {
                tags "DataPlane"
            }
            launcher = container "Launcher" "In-container execution wrapper: artifact download, user code execution, output publishing" "Go CLI (container wrapper)" {
                tags "DataPlane"
            }
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine — pipelines compile to Argo Workflow CRs" {
            tags "External"
        }
        database = softwareSystem "MySQL / PostgreSQL" "Pipeline, run, experiment metadata persistence" {
            tags "External"
        }
        objectStore = softwareSystem "MinIO / S3 / GCS" "Pipeline spec and artifact object storage" {
            tags "External"
        }
        mlmd = softwareSystem "ML Metadata (MLMD)" "Execution metadata tracking (contexts, executions, artifacts)" {
            tags "External"
        }
        kubernetes = softwareSystem "Kubernetes API" "Container orchestration, CRD hosting, RBAC" {
            tags "External"
        }
        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and manages all DSP components via DataSciencePipelinesApplication CR" {
            tags "Internal_ODH"
        }
        dashboard = softwareSystem "RHOAI Dashboard" "Frontend UI for pipeline management" {
            tags "Internal_ODH"
        }
        kfpSDK = softwareSystem "KFP Python SDK" "Pipeline compilation and submission" {
            tags "Internal_ODH"
        }

        # Person relationships
        dataScientist -> dsp "Creates pipelines, submits runs, monitors experiments"
        dataScientist -> kfpSDK "Compiles pipeline definitions"
        platformAdmin -> dspo "Configures DSP deployment"

        # External consumer relationships
        dashboard -> apiServer "Pipeline management UI" "HTTP/8888"
        kfpSDK -> apiServer "Pipeline compilation and submission" "HTTP/8888 + gRPC/8887"

        # Internal container relationships
        persistenceAgent -> apiServer "Reports workflow/SWF status" "HTTP/8888 + gRPC/8887"
        persistenceAgent -> kubernetes "Watches Workflows and ScheduledWorkflows" "HTTPS/443"
        swfController -> apiServer "Creates run records for scheduled executions" "gRPC/8887"
        swfController -> kubernetes "Watches ScheduledWorkflows, creates Argo Workflows" "HTTPS/443"
        driver -> apiServer "Cache check via TaskService" "gRPC/8887"
        driver -> mlmd "Resolve execution context" "gRPC/8080"
        driver -> kubernetes "ConfigMap reads, PVC create/delete" "HTTPS/443"
        driver -> objectStore "Artifact URI resolution" "HTTPS/443"
        launcher -> mlmd "Publish execution outputs and artifacts" "gRPC/8080"
        launcher -> objectStore "Upload output artifacts and logs" "HTTPS/443"
        launcher -> apiServer "Cache registration" "gRPC/8887"

        # System-level dependencies
        apiServer -> database "Pipeline and run metadata" "TCP/3306 or 5432"
        apiServer -> objectStore "Pipeline specs and artifacts" "HTTPS/443"
        apiServer -> argoWorkflows "Submit Argo Workflow CRs" "HTTPS/443"
        apiServer -> mlmd "Execution metadata tracking" "gRPC/8080"
        apiServer -> kubernetes "CRD operations, RBAC checks" "HTTPS/443"
        dspo -> dsp "Deploys and configures all components"
    }

    views {
        systemContext dsp "SystemContext" {
            include *
            autoLayout
        }

        container dsp "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal_ODH" {
                background #7ed321
                color #ffffff
            }
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "DataPlane" {
                background #50c878
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}

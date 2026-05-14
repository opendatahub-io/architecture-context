workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and submits ML pipelines via Python SDK or Dashboard UI"
        platformAdmin = person "Platform Admin" "Manages DSP deployment and configuration via DSPO"

        dsp = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines v2 backend providing ML pipeline definition, scheduling, execution, caching, and artifact management" {
            apiServer = container "API Server" "Central REST/gRPC API for pipeline CRUD, run submission, artifact access, and webhook validation" "Go Service" "Primary"
            driver = container "Driver" "Pre-execution sidecar that resolves inputs, checks cache, and patches pod specs in Argo Workflow steps" "Go CLI (sidecar)"
            launcher = container "Launcher" "In-container sidecar that runs user code, manages artifact upload/download, and publishes execution results to MLMD" "Go CLI (sidecar)"
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflows and syncs execution status back to the API server database" "Go Service"
            scheduledWorkflowController = container "Scheduled Workflow Controller" "Reconciles ScheduledWorkflow CRDs to trigger pipeline runs on cron or periodic schedules" "Go Controller"
            cacheServer = container "Cache Server" "Mutating admission webhook that intercepts pod creation to reuse cached pipeline step outputs" "Go Webhook"
            viewerController = container "Viewer Controller" "Reconciles Viewer CRDs to create Tensorboard Deployments and Services" "Go Controller"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Pipeline execution engine — submits and manages workflow DAGs" "External"
        database = softwareSystem "MySQL / PostgreSQL" "Pipeline, run, experiment, and cache metadata persistence" "External"
        objectStore = softwareSystem "S3-compatible Object Store" "MinIO or SeaweedFS — artifact and pipeline spec storage" "External"
        mlmd = softwareSystem "ML Metadata (MLMD)" "Execution lineage, artifact metadata, and pipeline context tracking" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration, CRD storage, RBAC" "External"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate management for webhook and API server" "External"

        dspo = softwareSystem "DSPO" "Data Science Pipelines Operator — deploys and configures all DSP components" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard" "UI for pipeline management and run visualization" "Internal RHOAI"
        workbench = softwareSystem "Workbench (Notebooks)" "Users submit pipelines via kfp Python SDK from Jupyter notebooks" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Pipeline-to-model lineage tracking (integration proposal)" "Internal RHOAI"

        # User relationships
        dataScientist -> dsp "Submits pipelines and manages runs" "REST/gRPC"
        dataScientist -> workbench "Develops pipeline code" "Browser/SDK"
        platformAdmin -> dspo "Configures DSP deployment" "CRD"

        # Internal container relationships
        apiServer -> database "Stores pipeline/run/experiment metadata" "SQL/3306 or 5432"
        apiServer -> objectStore "Stores artifacts and pipeline specs" "HTTP/9000"
        apiServer -> kubernetes "Submits Argo Workflows, manages CRDs" "HTTPS/443"
        apiServer -> mlmd "Queries execution lineage" "gRPC/8080"

        persistenceAgent -> apiServer "Reports workflow status" "gRPC/8887"
        persistenceAgent -> kubernetes "Watches Argo Workflows" "HTTPS/443"

        scheduledWorkflowController -> apiServer "Triggers scheduled runs" "gRPC/8887"
        scheduledWorkflowController -> kubernetes "Watches ScheduledWorkflow CRDs" "HTTPS/443"

        cacheServer -> database "Cache lookup and storage" "SQL/3306"
        cacheServer -> kubernetes "Intercepts pod CREATE (webhook)" "HTTPS/443"

        driver -> mlmd "Records execution context" "gRPC/8080"
        driver -> apiServer "Cache task lookup" "gRPC/8887"

        launcher -> objectStore "Uploads/downloads artifacts" "HTTP/9000"
        launcher -> mlmd "Publishes execution results" "gRPC/8080"

        # External system relationships
        dsp -> argoWorkflows "Submits and monitors pipeline DAGs" "CRD Watch + Create"
        dsp -> database "Pipeline and cache metadata persistence" "SQL"
        dsp -> objectStore "Artifact storage" "HTTP/HTTPS"
        dsp -> mlmd "Execution lineage tracking" "gRPC"
        dsp -> kubernetes "CRD management, RBAC, pod lifecycle" "HTTPS"
        dsp -> certManager "Optional TLS certificate provisioning" "CRD"

        # Internal platform relationships
        dspo -> dsp "Deploys and configures all components" "CRD/Deployment"
        dashboard -> dsp "Pipeline management UI" "REST/8888"
        workbench -> dsp "Pipeline submission from notebooks" "REST/gRPC"
        dsp -> modelRegistry "Pipeline-to-model lineage" "Integration"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

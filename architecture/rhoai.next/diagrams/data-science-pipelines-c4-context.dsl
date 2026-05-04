workspace {
    model {
        user = person "Data Scientist" "Defines, submits, and monitors ML pipelines via KFP Python SDK or Dashboard UI"

        dataSciencePipelines = softwareSystem "Data Science Pipelines" "KFP v2 backend providing ML pipeline definition, scheduling, execution, caching, and artifact management on Kubernetes" {
            apiServer = container "API Server" "Central REST/gRPC API for pipeline CRUD, run submission, artifact access, and webhook validation" "Go Service" "8888/TCP HTTP, 8887/TCP gRPC, 8443/TCP Webhook"
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflows and syncs execution status back to the API server database" "Go Service"
            scheduledWorkflowController = container "Scheduled Workflow Controller" "Reconciles ScheduledWorkflow CRDs to trigger pipeline runs on cron/periodic schedules" "Go Controller" "9090/TCP metrics"
            cacheServer = container "Cache Server" "Mutating admission webhook that intercepts pod creation to reuse cached pipeline step outputs" "Go Webhook" "443/TCP HTTPS"
            viewerController = container "Viewer Controller" "Reconciles Viewer CRDs to create Tensorboard Deployments and Services" "Go Controller"
            driver = container "Driver" "Pre-execution sidecar that resolves inputs, checks cache, and patches pod specs in Argo Workflow steps" "Go CLI (sidecar)"
            launcher = container "Launcher" "In-container executor that runs user code, manages artifact I/O, and publishes execution results to MLMD" "Go CLI (sidecar)"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Pipeline execution engine — submits and manages workflow DAGs" "External" {
            tags "External"
        }

        database = softwareSystem "MySQL / PostgreSQL" "Pipeline, run, experiment, and cache metadata persistence" "External" {
            tags "External"
        }

        objectStore = softwareSystem "S3-compatible Object Store" "Pipeline spec and artifact storage (MinIO/SeaweedFS)" "External" {
            tags "External"
        }

        mlmd = softwareSystem "ML Metadata (MLMD)" "Execution lineage, artifact metadata, and pipeline context tracking" "External" {
            tags "External"
        }

        kubernetes = softwareSystem "Kubernetes API" "Container orchestration, CRD storage, RBAC" "External" {
            tags "External"
        }

        certManager = softwareSystem "cert-manager" "Optional TLS certificate management for webhook and API server" "External" {
            tags "External"
        }

        dspo = softwareSystem "DSPO" "Data Science Pipelines Operator — deploys and configures all DSP components on RHOAI" "Internal RHOAI" {
            tags "Internal"
        }

        dashboard = softwareSystem "RHOAI Dashboard" "UI for pipeline management and run visualization" "Internal RHOAI" {
            tags "Internal"
        }

        workbench = softwareSystem "Workbench (Notebooks)" "Users submit pipelines via KFP Python SDK from notebooks" "Internal RHOAI" {
            tags "Internal"
        }

        modelRegistry = softwareSystem "Model Registry" "Pipeline-to-model lineage tracking (integration proposal)" "Internal RHOAI" {
            tags "Internal"
        }

        # User relationships
        user -> dataSciencePipelines "Submits pipelines and monitors runs" "REST/gRPC"
        user -> workbench "Develops pipelines in notebooks" "KFP Python SDK"
        user -> dashboard "Manages pipelines via UI" "HTTPS"

        # Internal container relationships
        apiServer -> database "Stores pipeline/run/experiment metadata" "SQL/3306-5432"
        apiServer -> objectStore "Stores pipeline specs and artifacts" "HTTP/9000"
        apiServer -> mlmd "Queries execution lineage" "gRPC/8080"
        apiServer -> kubernetes "Submits Argo Workflows, manages CRDs, RBAC checks" "HTTPS/443"
        persistenceAgent -> apiServer "Reports workflow status" "gRPC/8887"
        persistenceAgent -> kubernetes "Watches Argo Workflows" "HTTPS/443"
        scheduledWorkflowController -> apiServer "Triggers scheduled runs" "gRPC/8887"
        scheduledWorkflowController -> kubernetes "Watches ScheduledWorkflow CRDs" "HTTPS/443"
        cacheServer -> database "Looks up cache fingerprints" "SQL/3306"
        driver -> mlmd "Records execution context" "gRPC/8080"
        driver -> apiServer "Cache lookup via TaskService" "gRPC/8887"
        driver -> kubernetes "Reads ConfigMaps/Secrets, manages PVCs" "HTTPS/443"
        launcher -> objectStore "Uploads/downloads artifacts" "HTTP/9000"
        launcher -> mlmd "Publishes execution results" "gRPC/8080"

        # External system relationships
        dataSciencePipelines -> argoWorkflows "Submits and monitors Workflow DAGs" "CRD Watch + Create"
        dataSciencePipelines -> database "Persists all metadata" "SQL/3306-5432"
        dataSciencePipelines -> objectStore "Stores artifacts and pipeline specs" "HTTP/9000"
        dataSciencePipelines -> mlmd "Records execution lineage" "gRPC/8080"
        dataSciencePipelines -> kubernetes "CRD management, pod lifecycle, RBAC" "HTTPS/443"
        dataSciencePipelines -> certManager "Optional TLS certificate provisioning" "CRD"

        # Internal RHOAI relationships
        dspo -> dataSciencePipelines "Deploys and configures all DSP components"
        dashboard -> dataSciencePipelines "Pipeline management and visualization" "REST/8888"
        workbench -> dataSciencePipelines "Pipeline submission from notebooks" "gRPC+REST/8887-8888"
        dataSciencePipelines -> modelRegistry "Pipeline-to-model lineage (proposed)" "TBD"
    }

    views {
        systemContext dataSciencePipelines "SystemContext" {
            include *
            autoLayout
        }

        container dataSciencePipelines "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
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
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

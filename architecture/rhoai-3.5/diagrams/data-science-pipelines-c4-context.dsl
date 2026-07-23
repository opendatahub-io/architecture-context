workspace {
    model {
        dataScientist = person "Data Scientist" "Defines, compiles, and schedules ML pipelines"
        mlEngineer = person "ML Engineer" "Monitors pipeline runs and manages artifacts"

        dsp = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines v2 backend — ML pipeline orchestration, scheduling, artifact management, and metadata tracking" {
            apiServer = container "API Server" "Central REST/gRPC API for pipeline CRUD, run management, artifact access, webhook validation" "Go Service" {
                tags "Primary"
            }
            driver = container "Driver" "DAG orchestration — resolves inputs, generates pod spec patches, manages caching" "Go CLI (Argo sidecar)"
            launcher = container "Launcher" "User container execution — downloads/uploads artifacts, publishes metadata to MLMD" "Go CLI (Argo sidecar)"
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflows and ScheduledWorkflows, syncs status to API server via gRPC" "Go Agent"
            swfController = container "Scheduled Workflow Controller" "Reconciles ScheduledWorkflow CRs, triggers pipeline runs on cron/periodic schedules" "Go Controller"
            viewerController = container "Viewer Controller" "Reconciles Viewer CRs, manages Tensorboard Deployments and Services" "Go Controller"
            cacheServer = container "Cache Server" "Kubernetes mutating admission webhook for pipeline step caching" "Go Webhook"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow orchestration engine (v3.5/v3.7/v4.0)" {
            tags "External"
        }
        mlmd = softwareSystem "ML Metadata (MLMD)" "Execution and artifact lineage tracking (gRPC)" {
            tags "External"
        }
        database = softwareSystem "MySQL / PostgreSQL" "Pipeline metadata storage (runs, experiments, pipelines)" {
            tags "External"
        }
        objectStore = softwareSystem "S3-compatible Object Store" "Pipeline packages, artifacts, and logs storage" {
            tags "External"
        }
        kubernetes = softwareSystem "Kubernetes API" "Cluster orchestration, CRD management, RBAC, webhooks" {
            tags "External"
        }
        dspaOperator = softwareSystem "DSPA Operator" "Deploys and configures all DSP sub-components" {
            tags "Internal RHOAI"
        }
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator managing DSPA operator lifecycle" {
            tags "Internal RHOAI"
        }
        mlflow = softwareSystem "MLflow Tracking Server" "Optional experiment tracking integration" {
            tags "External"
        }
        metadataEnvoy = softwareSystem "Metadata Envoy" "gRPC-to-HTTP proxy for MLMD access" {
            tags "External"
        }

        # User interactions
        dataScientist -> dsp "Creates/runs pipelines via SDK or UI"
        mlEngineer -> dsp "Monitors runs, manages artifacts"

        # Internal container interactions
        apiServer -> database "SQL queries" "MySQL/PostgreSQL 3306/5432"
        apiServer -> objectStore "Store/retrieve artifacts" "S3 API 9000"
        apiServer -> argoWorkflows "Create Workflow CRs" "HTTPS/443"
        apiServer -> mlmd "Execution metadata" "gRPC/8080"
        apiServer -> kubernetes "CRD management, RBAC, webhooks" "HTTPS/443"
        apiServer -> mlflow "Optional experiment tracking" "HTTPS"

        driver -> apiServer "Cache lookup" "gRPC/8887"
        driver -> mlmd "Execution context" "gRPC/8080"
        driver -> objectStore "Artifact path resolution" "S3 API/9000"
        driver -> kubernetes "ConfigMap, PVC management" "HTTPS/443"

        launcher -> objectStore "Download/upload artifacts" "S3 API/9000"
        launcher -> mlmd "Publish execution results" "gRPC/8080"
        launcher -> apiServer "Cache entry creation" "gRPC/8887"

        persistenceAgent -> apiServer "Report workflow/SWF status" "gRPC/8887"
        persistenceAgent -> kubernetes "Watch Workflows via informers" "HTTPS/443"

        swfController -> apiServer "CreateRun for v2 schedules" "gRPC/8887"
        swfController -> kubernetes "ScheduledWorkflow CRUD, Workflow creation" "HTTPS/443"

        viewerController -> kubernetes "Manage Tensorboard Deployments/Services" "HTTPS/443"

        cacheServer -> kubernetes "Mutating admission webhook" "HTTPS/443"

        argoWorkflows -> driver "Spawns driver container"
        argoWorkflows -> launcher "Spawns launcher container"

        # Platform relationships
        dspaOperator -> dsp "Deploys and configures"
        rhodsOperator -> dspaOperator "Manages lifecycle"

        metadataEnvoy -> mlmd "gRPC-to-HTTP proxy" "gRPC/8080"
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
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

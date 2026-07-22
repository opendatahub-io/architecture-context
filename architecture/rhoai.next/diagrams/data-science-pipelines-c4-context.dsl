workspace {
    model {
        dataScientist = person "Data Scientist" "Defines, schedules, and monitors ML pipelines via SDK or UI"
        platformAdmin = person "Platform Admin" "Deploys and manages DSP stack via DSPO operator"

        dsp = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines backend for defining, scheduling, and executing ML/AI pipelines as Argo Workflows on Kubernetes" {
            apiServer = container "API Server" "Central API gateway for pipeline, run, experiment, and artifact management with multi-user RBAC" "Go Service" {
                tags "Primary"
            }
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflow and ScheduledWorkflow resources, persists status to API server database" "Go Service" {
                tags "Primary"
            }
            scheduledWorkflowController = container "Scheduled Workflow Controller" "Kubernetes controller managing ScheduledWorkflow CRDs — triggers Argo Workflows on cron/periodic schedules" "Go Controller" {
                tags "Primary"
            }
            cacheServer = container "Cache Server" "Mutating admission webhook that injects cached outputs for reusable pipeline steps" "Go Webhook" {
                tags "Supporting"
            }
            viewerController = container "Viewer Controller" "Kubernetes controller that deploys TensorBoard visualization instances" "Go Controller" {
                tags "Supporting"
            }
            driver = container "Driver" "Orchestrates individual pipeline step execution within Argo Workflow DAG nodes — resolves inputs, checks cache, creates K8s resources" "Go CLI (init container)" {
                tags "Runtime"
            }
            launcher = container "Launcher" "Executes user container tasks, handles artifact upload/download to/from object storage, reports metadata to MLMD" "Go CLI (step container)" {
                tags "Runtime"
            }
        }

        dspo = softwareSystem "Data Science Pipelines Operator" "OLM operator that deploys and manages the entire DSP component stack" "Internal RHOAI" {
            tags "Internal"
        }
        argoWorkflows = softwareSystem "Argo Workflows" "Pipeline step execution engine — pipelines compile to Argo Workflow DAGs" "External" {
            tags "External"
        }
        database = softwareSystem "MySQL / PostgreSQL" "Pipeline, run, experiment, and job metadata persistence" "External" {
            tags "External"
        }
        objectStorage = softwareSystem "S3 / MinIO" "Pipeline spec YAML and artifact binary storage" "External" {
            tags "External"
        }
        mlmd = softwareSystem "ML Metadata (MLMD)" "Artifact lineage, execution context, and metadata tracking" "External" {
            tags "External"
        }
        mlflow = softwareSystem "MLflow Server" "Optional ML experiment and run tracking synchronization" "External" {
            tags "External Optional"
        }
        kubernetes = softwareSystem "Kubernetes API" "Container orchestration, CRD hosting, RBAC enforcement" "External" {
            tags "External"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External" {
            tags "External"
        }

        # Person interactions
        dataScientist -> dsp "Creates pipelines, runs, and experiments via SDK or REST API"
        platformAdmin -> dspo "Configures DataSciencePipelinesApplication CR"
        dspo -> dsp "Deploys and manages DSP component stack"

        # Container-level interactions
        dataScientist -> apiServer "REST/gRPC: pipeline CRUD, run management" "HTTP/gRPC 8888/8887"
        apiServer -> database "Store/retrieve pipeline metadata" "MySQL/PG 3306/5432"
        apiServer -> objectStorage "Store/retrieve pipeline specs and artifacts" "S3 API 443"
        apiServer -> mlmd "Query artifact lineage and metadata" "gRPC 8080"
        apiServer -> mlflow "Sync experiment and run tracking" "HTTP/HTTPS"
        apiServer -> kubernetes "CRD operations, TokenReview, SAR" "HTTPS 443"
        apiServer -> argoWorkflows "Create Argo Workflow CRs" "Kubernetes API"

        persistenceAgent -> kubernetes "Watch Argo Workflow status" "HTTPS 443"
        persistenceAgent -> apiServer "Report workflow status and metrics" "HTTP/HTTPS 8888"

        scheduledWorkflowController -> kubernetes "Watch ScheduledWorkflow CRs, create Argo Workflows" "HTTPS 443"

        driver -> mlmd "Record execution context and artifacts" "gRPC 8080"
        driver -> kubernetes "Cache check, create pods, read secrets" "HTTPS 443"
        driver -> objectStorage "Read/write pipeline artifacts" "S3 API 443"
        driver -> apiServer "Report status, resolve specs" "gRPC 8887"

        launcher -> mlmd "Record output artifacts" "gRPC 8080"
        launcher -> objectStorage "Download inputs, upload outputs" "S3 API 443"

        prometheus -> apiServer "Scrape /metrics endpoint" "HTTP 8888"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #999999
                color #ffffff
                border dashed
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Primary" {
                background #4a90e2
            }
            element "Supporting" {
                background #85c1e9
            }
            element "Runtime" {
                background #50c878
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Defines, uploads, and runs ML pipelines via SDK or UI"
        mlEngineer = person "ML Engineer" "Configures pipeline infrastructure and monitors execution"

        dsp = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines v2 backend providing pipeline definition, scheduling, execution orchestration, and artifact management for ML workflows on Kubernetes" {
            apiServer = container "ml-pipeline API Server" "Central API for pipelines, runs, experiments, jobs; gRPC-gateway HTTP proxy; Kubernetes webhook server for PipelineVersion validation/mutation" "Go HTTP/gRPC Service" {
                tags "Primary"
            }
            driver = container "Driver" "Orchestrates task execution within Argo Workflow pods; resolves inputs from MLMD, manages caching, generates pod spec patches" "Go CLI (init container)" {
                tags "Sidecar"
            }
            launcher = container "Launcher v2" "Executes user container code, handles artifact upload/download, publishes execution metadata to MLMD" "Go CLI (main container)" {
                tags "Sidecar"
            }
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflow and ScheduledWorkflow resources; reports execution state to API server via gRPC" "Go Service (informer-based)" {
                tags "Agent"
            }
            swfController = container "Scheduled Workflow Controller" "Reconciles ScheduledWorkflow CRDs to trigger pipeline runs on cron/periodic schedules" "Go Controller (client-go)" {
                tags "Controller"
            }
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Pipeline workflow execution engine; creates and manages task pods" "External" {
            tags "External"
        }
        database = softwareSystem "MySQL / PostgreSQL" "Primary relational database for pipelines, runs, experiments, jobs" "External" {
            tags "External"
        }
        objectStorage = softwareSystem "MinIO / S3 / GCS" "Object storage for pipeline artifacts and pipeline specs" "External" {
            tags "External"
        }
        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC service for execution tracking, artifact lineage, and caching" "Internal Platform" {
            tags "Internal"
        }
        kubernetes = softwareSystem "Kubernetes API" "Container orchestration, RBAC (TokenReview, SubjectAccessReview)" "External" {
            tags "External"
        }
        cacheServer = softwareSystem "Cache Server" "Kubernetes mutating webhook for execution caching decisions" "Internal Platform" {
            tags "Internal"
        }
        vizServer = softwareSystem "Visualization Server" "Generate visualizations for pipeline run results" "Internal Platform" {
            tags "Internal"
        }
        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and manages all DSP component instances via DSPApplication CRD" "Internal Platform" {
            tags "Internal"
        }
        pipelineUI = softwareSystem "ML Pipeline UI" "Dashboard for pipeline management" "Internal Platform" {
            tags "Internal"
        }
        mlflow = softwareSystem "MLflow Tracking Server" "MLflow experiment tracking integration" "External" {
            tags "External"
        }

        # User interactions
        dataScientist -> dsp "Creates and runs ML pipelines via SDK/kubectl" "REST/gRPC"
        mlEngineer -> dsp "Configures pipeline infrastructure and monitors runs" "REST/gRPC"

        # System context relationships
        dsp -> argoWorkflows "Delegates pipeline execution" "REST via Kubernetes API"
        dsp -> database "Stores pipeline metadata" "TCP/3306 or 5432"
        dsp -> objectStorage "Stores artifacts and pipeline specs" "S3/443"
        dsp -> mlmd "Tracks execution lineage and artifacts" "gRPC/8080"
        dsp -> kubernetes "RBAC, CRD management, Pod access" "HTTPS/443"
        dsp -> cacheServer "Checks execution cache" "HTTPS/443"
        dsp -> vizServer "Generates run visualizations" "HTTP/8888"
        dsp -> mlflow "Tracks experiments (optional plugin)" "HTTP(S)"
        dspo -> dsp "Deploys and manages all DSP components"
        pipelineUI -> dsp "Consumes REST APIs for dashboard" "HTTP/8888"

        # Container relationships
        apiServer -> database "SQL queries for pipeline/run/experiment data" "TCP/3306 or 5432"
        apiServer -> objectStorage "Upload/download pipeline specs and artifacts" "S3/443"
        apiServer -> argoWorkflows "Create and manage Workflow resources" "REST"
        apiServer -> mlmd "Artifact/execution metadata" "gRPC/8080"
        apiServer -> vizServer "Generate visualizations" "HTTP/8888"
        apiServer -> kubernetes "TokenReview, SubjectAccessReview, CRD CRUD" "HTTPS/443"
        apiServer -> mlflow "MLflow experiment tracking plugin" "HTTP(S)"

        driver -> mlmd "Resolve inputs, create executions" "gRPC/8080"
        driver -> cacheServer "Check execution cache" "HTTPS/443"

        launcher -> objectStorage "Upload/download artifacts" "S3/443"
        launcher -> mlmd "Publish execution metadata" "gRPC/8080"

        persistenceAgent -> kubernetes "Watch Workflow and ScheduledWorkflow resources" "HTTPS/443"
        persistenceAgent -> apiServer "Report workflow state" "gRPC/8887"

        swfController -> kubernetes "Watch/create ScheduledWorkflows and Workflows" "HTTPS/443"
        swfController -> apiServer "CreateRun for scheduled executions" "gRPC/8887"
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
            element "Internal" {
                background #7ed321
                color #000000
            }
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Sidecar" {
                background #6cb4ee
                color #000000
            }
            element "Agent" {
                background #b8d4f0
                color #000000
            }
            element "Controller" {
                background #b8d4f0
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

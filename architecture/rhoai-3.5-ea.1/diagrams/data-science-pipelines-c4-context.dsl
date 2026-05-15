workspace {
    model {
        dataScientist = person "Data Scientist" "Defines, submits, and monitors ML pipeline workflows"
        platformAdmin = person "Platform Admin" "Deploys and configures Data Science Pipelines via DSPA CR"

        dsp = softwareSystem "Data Science Pipelines" "Multi-component ML pipeline orchestration platform built on Kubeflow Pipelines v2 and Argo Workflows" {
            apiServer = container "API Server" "Central REST/gRPC API for pipeline CRUD, run management, experiment tracking, artifact retrieval, and pipeline compilation into Argo Workflows" "Go Service" "8888/TCP HTTP, 8887/TCP gRPC, 8443/TCP Webhook"
            frontendUI = container "Frontend UI" "Web interface for browsing pipelines, runs, experiments, and artifacts" "TypeScript/React" "3000/TCP HTTP"
            driver = container "Driver" "Orchestrates DAG execution inside Argo task pods: resolves inputs, evaluates conditions, checks cache, generates pod spec patches for launchers" "Go CLI (Argo task container)"
            launcher = container "Launcher" "Executes user code inside pipeline step containers: downloads input artifacts, runs user commands, uploads outputs, publishes execution metadata to MLMD" "Go CLI (user container sidecar)"
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflow and ScheduledWorkflow resources via Kubernetes informers and persists their status to the API server database" "Go Service"
            scheduledWorkflowCtrl = container "Scheduled Workflow Controller" "Kubernetes controller that watches ScheduledWorkflow CRDs and creates Argo Workflow instances according to cron or periodic schedules" "Go Controller" "9090/TCP Prometheus"
            cacheServer = container "Cache Server" "MutatingWebhook for cache injection into pipeline task pods" "Webhook" "443/TCP HTTPS"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "DAG workflow execution engine; executes compiled pipeline specs as Kubernetes pods" "External"
        mysql = softwareSystem "MySQL / PostgreSQL" "Relational database for pipeline definitions, run history, experiments, tasks" "External"
        objectStorage = softwareSystem "SeaweedFS / MinIO / S3" "S3-compatible artifact storage for pipeline inputs, outputs, models, datasets, compiled specs, and run logs" "External"
        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC service for execution lineage tracking: contexts, executions, artifacts" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides TokenReview, SubjectAccessReview, Pod/Secret access, CRD operations" "External"
        rhodsOperator = softwareSystem "rhods-operator / DSPA Controller" "Platform operator that deploys and configures DSP components from DataSciencePipelinesApplication CR" "Internal RHOAI"

        # Person interactions
        dataScientist -> dsp "Submits pipelines, monitors runs, browses experiments" "REST API / Web UI"
        platformAdmin -> rhodsOperator "Creates/updates DataSciencePipelinesApplication CR" "kubectl"

        # System context
        rhodsOperator -> dsp "Deploys and manages DSP components" "Kubernetes CRD"
        dsp -> argoWorkflows "Compiles pipeline specs into Argo Workflow CRs for execution" "Kubernetes API"
        dsp -> mysql "Persists pipeline metadata, run history, experiment definitions" "MySQL/PostgreSQL 3306/5432"
        dsp -> objectStorage "Stores pipeline artifacts, compiled specs, and run logs" "S3 API HTTP 8333/9000"
        dsp -> mlmd "Tracks execution lineage (contexts, executions, artifacts)" "gRPC 8080"
        dsp -> k8sAPI "TokenReview, SubjectAccessReview, Workflow CRUD, Pod/Secret access" "HTTPS 443"

        # Container interactions
        dataScientist -> frontendUI "Browses pipelines and runs" "HTTP 3000"
        dataScientist -> apiServer "Submits pipelines and runs" "REST/gRPC 8888/8887"
        frontendUI -> apiServer "Proxies API requests" "HTTP"

        apiServer -> mysql "Persists metadata" "MySQL/PG 3306/5432"
        apiServer -> objectStorage "Stores artifacts and specs" "S3 API HTTP"
        apiServer -> mlmd "Queries lineage" "gRPC 8080"
        apiServer -> k8sAPI "Creates Argo Workflows, TokenReview, SAR" "HTTPS 443"
        apiServer -> argoWorkflows "Creates Workflow CRs" "Kubernetes API"

        driver -> mlmd "Resolves inputs, creates execution contexts" "gRPC 8080"
        driver -> apiServer "Cache lookup" "gRPC 8887"
        driver -> k8sAPI "Reads Pods, ConfigMaps, Secrets" "HTTPS 443"

        launcher -> objectStorage "Downloads/uploads artifacts" "S3 API HTTP"
        launcher -> mlmd "Publishes execution results" "gRPC 8080"
        launcher -> apiServer "Registers cache entries" "gRPC 8887"

        persistenceAgent -> apiServer "Reports workflow status" "HTTP 8888"
        persistenceAgent -> k8sAPI "Watches Argo Workflows via informers" "HTTPS 443"

        scheduledWorkflowCtrl -> k8sAPI "Watches ScheduledWorkflow CRDs, creates Workflows" "HTTPS 443"
        scheduledWorkflowCtrl -> apiServer "Creates run records" "gRPC 8887"
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
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Authors, uploads, and executes ML pipelines via UI or Python SDK"
        mlEngineer = person "ML Engineer" "Manages pipeline scheduling, monitoring, and artifact inspection"

        dspt = softwareSystem "Data Science Pipelines Tekton" "Backend platform for running Kubeflow ML pipelines with Tekton as the workflow execution engine" {
            apiServer = container "API Server" "gRPC/REST API for pipeline, run, experiment, job management with multi-user RBAC" "Go Service" "8888/TCP HTTP, 8887/TCP gRPC"
            persistenceAgent = container "Persistence Agent" "Watches Tekton PipelineRuns cluster-wide and syncs status to API Server" "Go Service"
            scheduledWorkflowController = container "Scheduled Workflow Controller" "Reconciles ScheduledWorkflow CRDs to create PipelineRuns on cron/periodic schedules" "Go Controller"
            cacheServer = container "Cache Server" "Mutating admission webhook for cache-hit detection on TaskRun pods" "Go Webhook" "8443/TCP HTTPS"
            visualizationServer = container "Visualization Server" "Generates HTML visualizations from pipeline run artifacts" "Python Service" "8888/TCP HTTP"
            viewerController = container "Viewer Controller" "Manages Viewer CRDs to deploy Tensorboard instances" "Go Controller"
            pipelineLoopsController = container "Pipeline-Loops Controller" "Tekton Custom Task controller for iterative PipelineRun execution" "Go/Knative Controller"
            pipelineLoopsWebhook = container "Pipeline-Loops Webhook" "Validation and defaulting webhook for PipelineLoop CRDs" "Go/Knative Webhook" "8443/TCP HTTPS"
            frontend = container "Frontend" "Web UI for pipeline management and visualization" "React/TypeScript"
            metadataWriter = container "Metadata Writer" "Writes pipeline run metadata to ML Metadata store" "Python Service"
        }

        tekton = softwareSystem "Tekton Pipelines" "Kubernetes-native CI/CD pipeline execution engine (>= 0.41.0)" "External"
        mysql = softwareSystem "MySQL" "Relational database for pipeline metadata, run history, and cache (5.7+)" "External"
        minio = softwareSystem "MinIO / S3" "S3-compatible object store for pipeline artifacts, templates, and logs" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Container orchestration, RBAC (SAR/TR), admission webhooks" "External"
        mlmd = softwareSystem "ML Metadata (MLMD)" "Pipeline run metadata persistence store" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and manages all DSPT sub-components via CRDs" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing Data Science projects" "Internal RHOAI"
        seldon = softwareSystem "Seldon Core" "ML model serving platform" "External"

        pythonSDK = softwareSystem "Python SDK (kfp-tekton)" "DSL for authoring pipelines and compiling to Tekton YAML" "Library"

        # Person relationships
        dataScientist -> dspt "Creates and executes ML pipelines" "REST/gRPC"
        dataScientist -> pythonSDK "Authors pipelines programmatically" "Python API"
        dataScientist -> frontend "Manages pipelines via browser" "HTTPS"
        mlEngineer -> dspt "Manages scheduling and monitoring" "REST/gRPC"

        # Core dependencies
        dspt -> tekton "Creates and monitors PipelineRuns/TaskRuns" "HTTPS/443 via K8s API"
        dspt -> mysql "Stores pipeline metadata, run history, cache" "MySQL/3306"
        dspt -> minio "Stores pipeline artifacts, templates, logs" "HTTP(S)/configurable"
        dspt -> k8sAPI "PipelineRun CRUD, RBAC checks (SAR/TR), Pod ops" "HTTPS/443"
        dspt -> mlmd "Persists pipeline run metadata" "gRPC"

        # Internal container relationships
        apiServer -> mysql "Store/retrieve pipeline metadata" "MySQL/3306"
        apiServer -> minio "Store/retrieve artifacts and templates" "HTTP(S)"
        apiServer -> k8sAPI "Create PipelineRuns, SAR, TR" "HTTPS/443"
        apiServer -> visualizationServer "Request HTML visualizations" "HTTP/8888"
        persistenceAgent -> apiServer "Report workflow status" "gRPC/8887"
        persistenceAgent -> k8sAPI "Watch PipelineRuns" "HTTPS/443"
        scheduledWorkflowController -> k8sAPI "Watch SWF CRDs, create PipelineRuns" "HTTPS/443"
        cacheServer -> mysql "Cache lookup/write" "MySQL/3306"
        metadataWriter -> mlmd "Write run metadata" "gRPC"

        # Platform relationships
        dspo -> dspt "Deploys and configures all components"
        dashboard -> dspt "UI management of pipelines" "REST API"
        prometheus -> apiServer "Scrape /metrics" "HTTP/8888"

        # External integrations
        k8sAPI -> cacheServer "MutatingWebhook on pod creation" "HTTPS/8443"
        k8sAPI -> pipelineLoopsWebhook "ValidatingWebhook on PipelineLoop" "HTTPS/8443"
    }

    views {
        systemContext dspt "SystemContext" {
            include *
            autoLayout
        }

        container dspt "Containers" {
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
            element "Library" {
                background #4a90e2
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

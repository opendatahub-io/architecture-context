workspace {
    model {
        dataScientist = person "Data Scientist" "Defines, compiles, schedules, and monitors ML pipelines"
        platformAdmin = person "Platform Admin" "Deploys and configures DSP instances via DSPO"

        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration platform for defining, scheduling, and executing reproducible ML workflows on Kubernetes" {
            apiserver = container "API Server" "Central API for pipeline CRUD, run management, experiment tracking, and pipeline compilation. Serves admission webhooks for PipelineVersion CRDs." "Go Service" "Critical"
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflow resources and persists run status, metrics, and state transitions to the API server" "Go Controller"
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages ScheduledWorkflow CRs to create Argo Workflow instances on cron schedules" "Go Controller"
            driver = container "Driver" "Init container that resolves pipeline task inputs, computes pod spec patches, and prepares execution context" "Go Executable"
            launcher = container "Launcher v2" "Sidecar that downloads input artifacts, invokes user executor, and uploads output artifacts" "Go Executable"
            cacheServer = container "Cache Server" "Mutating admission webhook enabling execution caching based on input fingerprinting" "Go Webhook Service"
            ui = container "ml-pipeline-ui" "Web UI for browsing pipelines, experiments, runs, artifacts, and visualizations" "TypeScript/React"
            viewerCrd = container "Viewer CRD Controller" "Watches Viewer CRs and creates Deployments/Services for pipeline output visualizations" "Go Controller"
            metadataWriter = container "Metadata Writer" "Watches completed Argo Workflow pods and writes execution metadata and artifact records to MLMD" "Python Service"
        }

        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and manages DSP instances via DataSciencePipelinesApplication CR" "Internal RHOAI"
        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine for running pipeline tasks as Kubernetes pods" "External"
        mysql = softwareSystem "MySQL" "Pipeline metadata, run state, and cache database" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Pipeline spec, artifact, and log storage" "External"
        mlmd = softwareSystem "ML Metadata (MLMD)" "Artifact and execution lineage tracking via gRPC API" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for webhook and API server endpoints" "External"
        envoy = softwareSystem "Metadata Envoy" "gRPC-to-HTTP transcoding proxy fronting the MLMD gRPC server" "External"
        kubernetesApi = softwareSystem "Kubernetes API" "Cluster API for CRD management, workflow CRUD, and auth delegation" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via scrape annotations" "Internal RHOAI"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook workbench management" "Internal RHOAI"

        # Relationships - External
        dataScientist -> dsp "Defines and submits pipelines via SDK or UI"
        platformAdmin -> dspo "Deploys DSP instances"
        dspo -> dsp "Manages lifecycle of"

        # Relationships - Internal
        dataScientist -> ui "Browses pipelines, runs, experiments" "HTTP/3000"
        dataScientist -> apiserver "Submits pipelines" "REST/8888, gRPC/8887"
        ui -> apiserver "REST API calls" "HTTP/8888"

        apiserver -> mysql "Stores pipeline metadata and run state" "MySQL/3306"
        apiserver -> s3 "Stores pipeline specs and artifacts" "HTTP/HTTPS"
        apiserver -> kubernetesApi "Creates Argo Workflows, manages CRDs, delegates auth" "HTTPS/6443"
        apiserver -> mlmd "Records artifact/execution metadata" "gRPC/8080"

        persistenceAgent -> kubernetesApi "Watches Argo Workflow status" "HTTPS/6443"
        persistenceAgent -> apiserver "Reports run status and metrics" "HTTP/8888"

        scheduledWorkflow -> kubernetesApi "Creates Workflows on cron schedules" "HTTPS/6443"

        cacheServer -> mysql "Checks/updates execution cache" "MySQL/3306"
        cacheServer -> kubernetesApi "Reads pod specs" "HTTPS/6443"

        driver -> kubernetesApi "Resolves inputs, computes pod specs" "HTTPS/6443"
        launcher -> s3 "Downloads/uploads artifacts" "HTTP/HTTPS"
        launcher -> mlmd "Records metadata" "gRPC/8080"

        metadataWriter -> mlmd "Writes execution metadata" "gRPC/8080"
        envoy -> mlmd "Proxies gRPC to HTTP" "gRPC/8080"

        viewerCrd -> kubernetesApi "Creates visualization Deployments" "HTTPS/6443"

        prometheus -> apiserver "Scrapes metrics" "HTTP/8888"
        prometheus -> scheduledWorkflow "Scrapes metrics" "HTTP/9090"

        certManager -> apiserver "Provisions webhook TLS certs"
        certManager -> cacheServer "Provisions webhook TLS certs"

        apiserver -> kubeflowNotebooks "Manages notebook workbenches" "Kubernetes API"
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
            element "Critical" {
                background #e74c3c
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        datascientist = person "Data Scientist" "Defines and submits ML pipelines via KFP Python SDK or Dashboard UI"
        platformadmin = person "Platform Admin" "Deploys and configures DSP via DSPO operator"

        dsp = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines v2 — ML pipeline definition, scheduling, execution, caching, and artifact management" {
            apiserver = container "API Server" "Central REST/gRPC API for pipeline CRUD, run submission, artifact access, and webhook validation" "Go Service" "8888/TCP HTTP, 8887/TCP gRPC, 8443/TCP Webhook"
            driver = container "Driver" "Pre-execution sidecar that resolves inputs, checks cache, and patches pod specs in Argo Workflow steps" "Go CLI (sidecar)"
            launcher = container "Launcher" "In-container sidecar that executes user code, manages artifact I/O, and publishes results to MLMD" "Go CLI (sidecar)"
            persistenceagent = container "Persistence Agent" "Watches Argo Workflows and syncs execution status back to API server database" "Go Service"
            swcontroller = container "Scheduled Workflow Controller" "Reconciles ScheduledWorkflow CRDs to trigger pipeline runs on cron/periodic schedules" "Go Controller" "9090/TCP metrics"
            cacheserver = container "Cache Server" "Mutating admission webhook that intercepts pod creation to reuse cached pipeline step outputs" "Go Webhook" "443/TCP HTTPS"
            viewercontroller = container "Viewer Controller" "Reconciles Viewer CRDs to create Tensorboard Deployments and Services" "Go Controller"
        }

        argoworkflows = softwareSystem "Argo Workflows" "Pipeline execution engine — submits and manages workflow DAGs" "External"
        database = softwareSystem "MySQL / PostgreSQL" "Persistent storage for pipelines, runs, experiments, tasks, cache" "External"
        objectstore = softwareSystem "S3-compatible Object Store" "Artifact storage and pipeline spec persistence (MinIO/SeaweedFS)" "External"
        mlmd = softwareSystem "ML Metadata (MLMD)" "Execution lineage, artifact metadata, and pipeline context tracking" "External"
        kubernetes = softwareSystem "Kubernetes API" "Container orchestration, CRD storage, RBAC" "External"
        certmanager = softwareSystem "cert-manager" "Optional TLS certificate management for webhook and API server" "External"

        dspo = softwareSystem "DSPO (Data Science Pipelines Operator)" "Deploys and configures all DSP sub-components on RHOAI" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard" "UI for pipeline management and run visualization" "Internal RHOAI"
        workbench = softwareSystem "Workbench (Notebooks)" "Users submit pipelines via kfp Python SDK from notebooks" "Internal RHOAI"
        modelregistry = softwareSystem "Model Registry" "Pipeline-to-model lineage tracking (proposed integration)" "Internal RHOAI"

        # User interactions
        datascientist -> dsp "Creates and manages pipelines via REST/gRPC" "HTTP/gRPC"
        datascientist -> workbench "Develops pipelines in Jupyter notebooks" "HTTPS"
        platformadmin -> dspo "Deploys DSP components" "kubectl/YAML"

        # Internal container interactions
        apiserver -> database "Stores pipeline/run/experiment metadata" "SQL/3306 or 5432"
        apiserver -> objectstore "Stores pipeline specs and artifacts" "HTTP/9000"
        apiserver -> kubernetes "Submits Argo Workflows, manages CRDs, RBAC checks" "HTTPS/443"
        apiserver -> mlmd "Queries execution metadata" "gRPC/8080"

        persistenceagent -> kubernetes "Watches Argo Workflow status" "HTTPS/443"
        persistenceagent -> apiserver "Reports workflow status" "gRPC/8887"

        swcontroller -> kubernetes "Watches ScheduledWorkflow CRDs" "HTTPS/443"
        swcontroller -> apiserver "Creates pipeline runs on schedule" "gRPC/8887"

        cacheserver -> database "Checks cache entries" "SQL/3306"

        driver -> mlmd "Records execution context, resolves upstream outputs" "gRPC/8080"
        driver -> apiserver "Cache lookup/recording" "gRPC/8887"

        launcher -> objectstore "Uploads/downloads artifacts" "HTTP/9000"
        launcher -> mlmd "Publishes execution results" "gRPC/8080"

        # External system interactions
        dsp -> argoworkflows "Uses for pipeline execution DAGs" "CRD Watch + Create"
        dsp -> database "Pipeline and cache metadata persistence" "SQL/3306 or 5432"
        dsp -> objectstore "Artifact storage and pipeline spec persistence" "HTTP/9000"
        dsp -> mlmd "Execution lineage and artifact metadata" "gRPC/8080"
        dsp -> kubernetes "CRD management, pod lifecycle, RBAC" "HTTPS/443"
        dsp -> certmanager "Optional TLS certificate provisioning" "CRD"

        # Internal RHOAI interactions
        dspo -> dsp "Deploys and configures all DSP components" "Deployment owner"
        dashboard -> dsp "Pipeline management and run visualization" "REST/8888"
        workbench -> dsp "Pipeline compilation, submission, and management" "HTTP+gRPC/8888+8887"
        modelregistry -> dsp "Pipeline-to-model lineage tracking" "Integration (proposed)"
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
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

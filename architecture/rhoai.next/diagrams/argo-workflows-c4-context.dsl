workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages ML pipeline workflows"
        dspClient = person "DSP API Client" "Data Science Pipelines API submitting workflows programmatically"

        argoWorkflows = softwareSystem "Argo Workflows" "Container-native workflow engine for orchestrating parallel jobs on Kubernetes; execution backend for Data Science Pipelines in RHOAI" {
            workflowController = container "workflow-controller" "Watches Workflow CRs, orchestrates pod creation, manages DAG/step execution, cron scheduling, artifact GC, and workflow archival. Uses client-go informers with configurable worker pools (32 workflow, 8 cron, 4 GC, 4 cleanup, 8 archive). Leader election for HA." "Go Controller (client-go)" {
                wfReconciler = component "Workflow Reconciler" "Main reconciliation loop for Workflow CRs" "Go"
                cronController = component "Cron Controller" "Schedules workflows from CronWorkflow CRs" "Go"
                gcController = component "GC Controller" "TTL-based workflow garbage collection" "Go"
                podCleanup = component "Pod Cleanup" "Cleans up completed/failed workflow pods" "Go"
                artifactGC = component "Artifact GC" "Garbage collects artifacts from storage backends" "Go"
                syncManager = component "Synchronization Manager" "Semaphore/mutex coordination across workflows" "Go"
            }

            argoServer = container "argo-server" "Exposes REST/gRPC APIs (port 2746) for workflow CRUD, artifact serving, SSO authentication, event dispatch, and serves the web UI. gRPC-gateway pattern." "Go API Server (gRPC + HTTP)" {
                grpcGateway = component "gRPC-Gateway" "REST and gRPC API endpoints" "Go"
                gatekeeper = component "Gatekeeper" "Authentication and authorization interceptor" "Go"
                ssoAuth = component "SSO/OIDC Auth" "OIDC-based single sign-on" "Go"
                artifactServer = component "Artifact Server" "Serves workflow artifacts for download" "Go"
                webUI = component "Web UI" "Static files for Argo Workflows dashboard" "TypeScript/React"
            }

            argoExec = container "argoexec" "Runs inside every workflow pod as init (load artifacts) and wait (save artifacts, report results) containers. Ships FIPS and non-FIPS binaries." "Go Executor (sidecar)"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform and API server" "External"
        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and configures Argo Workflows as part of the DSP stack" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Relational database for workflow archival and node status offloading" "External"
        s3Storage = softwareSystem "S3 / MinIO" "Object storage for workflow artifacts (inputs/outputs)" "External"
        oidcProvider = softwareSystem "OIDC Provider (Keycloak)" "SSO authentication provider" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        argoEvents = softwareSystem "Argo Events" "Event-driven workflow triggering via EventSources and Sensors" "External"
        webhookSources = softwareSystem "GitHub / GitLab / Bitbucket" "Webhook sources for event-triggered workflow submissions" "External"

        # User relationships
        user -> argoWorkflows "Creates Workflows, views results via CLI/UI"
        user -> argoServer "Accesses Web UI and REST API" "HTTPS/2746"
        dspClient -> kubernetes "Submits Workflow CRs" "HTTPS/6443"

        # Internal relationships
        workflowController -> kubernetes "Watch/create/update CRs, Pods, ConfigMaps, Secrets, leader election" "HTTPS/6443"
        workflowController -> postgresql "Archive workflows, offload node status" "TCP/5432"
        workflowController -> s3Storage "Artifact garbage collection" "HTTPS/9000"

        argoServer -> kubernetes "Query CRs, delegate auth via Bearer Token" "HTTPS/6443"
        argoServer -> postgresql "Query archived workflows" "TCP/5432"
        argoServer -> s3Storage "Serve artifact downloads" "HTTPS/9000"
        argoServer -> oidcProvider "SSO authentication" "HTTPS/443"

        argoExec -> kubernetes "Create WorkflowTaskResult CRs, watch WorkflowTaskSet" "HTTPS/6443"
        argoExec -> s3Storage "Load/save workflow artifacts" "HTTPS/9000"

        # External relationships
        dspo -> argoWorkflows "Deploys and configures controller + executor images"
        prometheus -> workflowController "Scrapes metrics" "HTTP/9090"
        prometheus -> argoServer "Scrapes metrics" "HTTPS/2746"
        argoEvents -> kubernetes "Creates Workflows via EventSource/Sensor" "HTTPS/6443"
        webhookSources -> argoServer "Webhook-triggered workflow submissions" "HTTPS/2746"
    }

    views {
        systemContext argoWorkflows "SystemContext" {
            include *
            autoLayout
        }

        container argoWorkflows "Containers" {
            include *
            autoLayout
        }

        component workflowController "WorkflowControllerComponents" {
            include *
            autoLayout
        }

        component argoServer "ArgoServerComponents" {
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
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
